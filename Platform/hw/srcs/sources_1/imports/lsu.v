`include "../riscv_defs.v"

module lsu (
    input           clk_i, input rst_i,
    input           opcode_valid_i,
    input           is_dflush_i, input is_dinval_i, 
    input           is_dwb_i,
    input           ex_mem_rd_i, input ex_mem_wr_i,
    input   [ 3:0]  ex_mem_ctrl_i,
    input   [31:0]  lsu_addr_i, input [31:0] lsu_wdata_i, input [3:0] lsu_mask_i,
    output  [31:0]  mem_addr_o, output [31:0] mem_data_o, output [ 3:0] mem_mask_o,

    output          dcache_rd_o, output dcache_wr_o,
    input   [31:0]  dcache_value_i, input dcache_vld_i, input dcache_rdy_i, 
    output          dcache_dflush_o, output dcache_dinvalidate_o,
    output          dcache_dwriteback_o, output icache_invalidate_o,

    output          cdma_rd_o, output cdma_wr_o,
    input   [31:0]  cdma_value_i, input cdma_valid_i,

    output  [31:0]  writeback_value_o, output writeback_valid_o
);

localparam D_ADDR_MIN = 32'h60000000;
localparam D_ADDR_MAX = 32'hFFFFFFFF;

reg [1:0]  state_r;
localparam ST_IDLE = 2'b00;
localparam ST_WAIT = 2'b01;

reg [31:0] req_addr_r, req_wdata_r;
reg [ 3:0] req_mask_r, req_ctrl_r;
reg        req_rd_r, req_wr_r;
reg        cmi_flush_r, cmi_inv_r, cmi_wb_r;
reg        is_cachable_r;
reg        wait_1;

wire req_flush  = (is_dflush_i);
wire req_inv    = (is_dinval_i);
wire req_wb     = (is_dwb_i);

wire is_cmi = req_flush | req_inv | req_wb;
wire is_active_req = opcode_valid_i && (ex_mem_rd_i || ex_mem_wr_i || is_cmi);

always @(posedge clk_i or negedge rst_i) begin
    if (~rst_i) begin
        state_r <= ST_IDLE;
        req_addr_r <= 0; req_wdata_r <= 0; req_mask_r <= 0;
        req_ctrl_r <= 0; req_rd_r <= 0; req_wr_r <= 0;
        cmi_flush_r <= 0; cmi_inv_r <= 0; cmi_wb_r <= 0;
        is_cachable_r <= 0;
        wait_1 <= 0;
    end else begin
        case (state_r)
            ST_IDLE: begin
                if (is_active_req) begin
                    req_addr_r  <= lsu_addr_i;
                    req_wdata_r <= lsu_wdata_i << {lsu_addr_i[1:0], 3'b000};
                    req_mask_r  <= lsu_mask_i << lsu_addr_i[1:0];
                    req_ctrl_r  <= ex_mem_ctrl_i;
                    req_rd_r    <= ex_mem_rd_i;
                    req_wr_r    <= ex_mem_wr_i;
                    cmi_flush_r <= req_flush;
                    cmi_inv_r   <= req_inv;
                    cmi_wb_r    <= req_wb;
                    is_cachable_r <= (lsu_addr_i >= D_ADDR_MIN) && (lsu_addr_i <= D_ADDR_MAX);
                    wait_1      <= 1'b1;
                    state_r     <= ST_WAIT;
                end
            end
            ST_WAIT: begin
                wait_1 <= 1'b0;
                if (writeback_valid_o) begin 
                    state_r <= ST_IDLE;
                    req_rd_r <= 0; req_wr_r <= 0;
                    cmi_flush_r <= 0; cmi_inv_r <= 0; cmi_wb_r <= 0; 
                end
            end
        endcase
    end
end

wire use_comb = (state_r == ST_IDLE);

wire [1:0] direct_byte_sel = lsu_addr_i[1:0];
wire [31:0] comb_wdata = lsu_wdata_i << {direct_byte_sel, 3'b000};
wire [ 3:0] comb_mask  = lsu_mask_i << direct_byte_sel;
wire comb_cachable = (lsu_addr_i >= D_ADDR_MIN) && (lsu_addr_i <= D_ADDR_MAX);

assign mem_addr_o = use_comb ? lsu_addr_i : req_addr_r;
assign mem_data_o = use_comb ? comb_wdata : req_wdata_r;
assign mem_mask_o = use_comb ? comb_mask  : req_mask_r;

wire cur_is_cachable = use_comb ? comb_cachable : is_cachable_r;
wire cur_req_rd      = use_comb ? (opcode_valid_i & ex_mem_rd_i) : req_rd_r;
wire cur_req_wr      = use_comb ? (opcode_valid_i & ex_mem_wr_i) : req_wr_r;
wire cur_is_cmi      = use_comb ? is_cmi : (cmi_flush_r | cmi_inv_r | cmi_wb_r);

assign dcache_rd_o = cur_is_cachable & cur_req_rd;
assign dcache_wr_o = cur_is_cachable & cur_req_wr;
assign cdma_rd_o   = !cur_is_cachable & cur_req_rd;
assign cdma_wr_o   = !cur_is_cachable & cur_req_wr;

assign dcache_dflush_o      = (state_r == ST_WAIT) & cmi_flush_r;
assign dcache_dinvalidate_o = (state_r == ST_WAIT) & cmi_inv_r;
assign dcache_dwriteback_o  = (state_r == ST_WAIT) & cmi_wb_r;
assign icache_invalidate_o  = 1'b0;

assign writeback_valid_o =
    (state_r == ST_IDLE && opcode_valid_i && !is_active_req) ? 1'b1 :
    (state_r == ST_WAIT) ? (
        cur_is_cmi ? (!wait_1 && dcache_rdy_i) :
        is_cachable_r ? dcache_vld_i :
        cdma_valid_i
    ) : 1'b0;

wire [31:0] cur_addr = use_comb ? lsu_addr_i : req_addr_r;
wire [ 3:0] cur_ctrl = use_comb ? ex_mem_ctrl_i : req_ctrl_r;

wire [31:0] raw_memory_value = !cur_is_cachable ? cdma_value_i : dcache_value_i;
wire [4:0]  shift_amount = {cur_addr[1:0], 3'b000};

wire [31:0] raw_rdata = raw_memory_value >> shift_amount;

wire [7:0]  raw_byte = raw_rdata[7:0];
wire [15:0] raw_half = raw_rdata[15:0];
wire sign_ext_b = cur_ctrl[3] & raw_byte[7];
wire sign_ext_h = cur_ctrl[3] & raw_half[15];

wire [31:0] fmt_byte = {{24{sign_ext_b}}, raw_byte};
wire [31:0] fmt_half = {{16{sign_ext_h}}, raw_half};

assign writeback_value_o = (cur_ctrl[2:0] == 3'b001) ? fmt_byte :
                           (cur_ctrl[2:0] == 3'b010) ? fmt_half :
                           raw_rdata;

endmodule