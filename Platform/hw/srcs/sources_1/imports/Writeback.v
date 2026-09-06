`include "riscv_defs.v"
module Writeback (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        en,
    input  wire        clear,
    input  wire        is_impl_i,
    input  wire        pc_valid_i,
    
    input  wire [31:0] pc_p4_i,
    
    input  wire [4:0]  rd_i,
    
    input  wire [31:0] bypass_i,
    input  wire [31:0] ALU_i,
    input  wire [31:0] MUL_DIV_i,
    input  wire [31:0] NPU_i,
    input  wire [31:0] mem_data_i, 
    input  wire [31:0] csr_rd_data_i,
    
    input  wire [31:0] MUL_out_i,
    input  wire        is_mul_i,
    
    input  wire        reg_wr_en_i,
    input  wire [2:0]  reg_w_sel_i,

    output wire        is_impl_o,
    output wire        pc_valid_o,
    output wire [ 4:0] rd_o,
    output wire [31:0] wb_data_o,
    output wire        reg_wr_en_o
);

wire EX_reg_wr_en_w = (reg_wr_en_i & pc_valid_i & is_impl_i);

wire WB_is_impl_out;
wire WB_pc_valid_out;
wire [31:0] WB_pc_out;
wire [31:0] WB_pc_p4_out;
wire [4:0]  WB_rd_out;
wire [31:0] WB_ALU_out;
wire [31:0] WB_MUL_DIV_out;
wire [31:0] WB_mem_data_out; 
wire [31:0] WB_csr_rd_data_out;
wire [31:0] WB_NPU_out;
wire [31:0] WB_bypass_out;

(* max_fanout = "8" *) wire        WB_is_mul_out;
(* max_fanout = "8" *) wire [2:0]  WB_reg_w_sel_out;
wire        WB_reg_wr_en_out;

WB_Reg m_WB_Reg(
    .clk(clk), .rst_n(rst_n), .en(en), .clear(clear),
    .is_impl_i(is_impl_i), .pc_valid_i(pc_valid_i), 
    
    .pc_i(32'd0),
    .pc_p4_i(pc_p4_i),
    
    .rd_i(rd_i), .bypass_i(bypass_i),
    .ALU_i(ALU_i), .MUL_DIV_i(MUL_DIV_i), .NPU_i(NPU_i),
    .mem_data_i(mem_data_i), 
    .csr_rd_data_i(csr_rd_data_i), .is_mul_i(is_mul_i),
    .reg_wr_en_i(EX_reg_wr_en_w), .reg_w_sel_i(reg_w_sel_i),
    
    .is_impl_o(WB_is_impl_out), .pc_valid_o(WB_pc_valid_out), .pc_o(WB_pc_out), 
    .pc_p4_o(WB_pc_p4_out), .rd_o(WB_rd_out), .bypass_o(WB_bypass_out),
    .ALU_o(WB_ALU_out), .MUL_DIV_o(WB_MUL_DIV_out), .NPU_o(WB_NPU_out),
    .mem_data_o(WB_mem_data_out), .csr_rd_data_o(WB_csr_rd_data_out),
    .is_mul_o(WB_is_mul_out), .reg_wr_en_o(WB_reg_wr_en_out), .reg_w_sel_o(WB_reg_w_sel_out)
);

assign is_impl_o = WB_is_impl_out;
assign pc_valid_o = WB_pc_valid_out;
assign reg_wr_en_o = WB_reg_wr_en_out;
assign rd_o = WB_rd_out;

wire [31:0] mul_div_data = WB_is_mul_out ? MUL_out_i : WB_MUL_DIV_out;

reg [31:0] mux_low;
always @(*) begin
    case (WB_reg_w_sel_out[1:0])
        2'b00: mux_low = WB_pc_p4_out;
        2'b01: mux_low = WB_ALU_out;
        2'b10: mux_low = WB_mem_data_out;
        2'b11: mux_low = WB_csr_rd_data_out;
    endcase
end

reg [31:0] mux_high;
always @(*) begin
    case (WB_reg_w_sel_out[1:0])
        2'b00: mux_high = 32'b0; 
        2'b01: mux_high = WB_bypass_out;
        2'b10: mux_high = mul_div_data;
        2'b11: mux_high = WB_NPU_out;
    endcase
end

assign wb_data_o = WB_reg_w_sel_out[2] ? mux_high : mux_low;

endmodule