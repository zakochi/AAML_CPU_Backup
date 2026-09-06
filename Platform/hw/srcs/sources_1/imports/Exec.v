`include "riscv_defs.v"
module Exec(
    input clk
    ,input rst_n
    
    ,input en
    ,input clear
    
    ,input is_impl_i
    ,input pc_valid_i
    ,input [31:0] pc_i
    ,input [31:0] pc_p4_i
    ,input [31:0] inst_i
    ,input  wire [31:0] reg_rd_data1_i
    ,input  wire [31:0] reg_rd_data2_i
    
    ,input  wire [31:0] imm_i
    
    ,input  wire [4:0]  rd_i
    ,input  wire [4:0]  rs1_i
    ,input  wire [4:0]  rs2_i
    ,input  wire [4:0]  rs3_i
    // reg
    ,input wire        reg_wr_en_i
    ,input wire [2:0]  reg_w_sel_i
    // mem
    ,input wire        mem_wr_en_i
    ,input wire        mem_rd_en_i
    ,input wire [3:0]  mem_ctrl_i
    // Br and Jump
    ,input wire        is_j_i
    ,input wire        is_br_i
    // ALU
    ,input wire        ALU_sel1_i
    ,input wire        ALU_sel2_i
    ,input wire [3:0]  ALU_ctrl_i
    // cmp
    ,input wire [2:0]  cmp_op_i
    
    // MUL/DIV
    ,input wire is_MUL_DIV_i
    ,input wire [2:0] MUL_DIV_ctrl_i

    // csr
    ,input wire [11:0] csr_addr_i

    ,input wire is_csr_i

    // npu
    ,input wire is_npu_i

    // bypass
    ,input wire [1:0] bypass_sel_i
    // fence
    ,input wire fetch_invalid_i
    
    // cache operations
    ,input wire is_dflush_i
    ,input wire is_dinval_i
    ,input wire is_dwb_i

    // forwarding
    ,input [4:0] WB_rd_i
    ,input WB_reg_wr_en_i
    ,input [31:0] wb_data_i

//=================================
    // output
    // data
    ,output wire         is_impl_o
    ,output  wire        pc_valid_o
    ,output  wire [31:0] pc_o
    ,output  wire [31:0] pc_p4_o
    ,output wire [31:0] inst_o
    
    ,output wire [31:0] reg_fwd_data1_o
    ,output wire [31:0] reg_fwd_data2_o
    
    ,output wire [31:0] imm_o
    
    ,output wire [4:0]  rd_o
    ,output wire [4:0]  rs1_o
    ,output wire [4:0]  rs2_o
    ,output wire [4:0]  rs3_o
    
    // reg
    ,output wire        reg_wr_en_o
    ,output wire [2:0]  reg_w_sel_o
    // mem
    ,output wire        mem_wr_en_o
    ,output wire        mem_rd_en_o
    ,output wire [3:0]  mem_ctrl_o
    // Br and Jump
    ,output wire        is_j_o
    ,output wire        is_br_o
    // ALU
    ,output wire [3:0]  ALU_ctrl_o
    ,output wire [31:0] ALU_o
    // Branch
    ,output wire        br_taken_o

    // MUL/DIV
    ,output wire is_MUL_DIV_o
    ,output wire [2:0] MUL_DIV_ctrl_o

    // csr
    ,output wire [31:0] csr_rd_data_o

	// lsu
	,output wire [31:0] lsu_addr_o
    ,output wire [31:0] lsu_wdata_o
    ,output wire [3:0]  lsu_mask_o
	
    // npu
    ,output wire is_npu_o

    ,output wire [1:0] bypass_sel_o
    ,output wire [31:0] bypass_o

    ,output wire fetch_invalid_o
    
    // cache operations
    ,output wire is_dflush_o
    ,output wire is_dinval_o
    ,output wire is_dwb_o
    
	// EX control
    ,output wire EX_start_o
    ,output wire MUL_DIV_start_o
    ,output wire NPU_start_o
    ,output wire LSU_start_o
    
    ,input wire MUL_DIV_done_i
    ,input wire NPU_done_i
    ,input wire LSU_done_i
    
    ,output wire EX_done_o
);
wire [31:0] reg_rd_data1_o;
wire [31:0] reg_rd_data2_o;

wire ALU_sel1_o;
wire ALU_sel2_o;

wire [2:0] cmp_op_o;
wire [11:0] csr_addr_o;

// data
PipelineRegister #(.WIDTH( 1)) reg_is_impl   (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(is_impl_i),   .data_o(is_impl_o));
PipelineRegister #(.WIDTH( 1)) reg_pc_valid  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(pc_valid_i),   .data_o(pc_valid_o));
PipelineRegister #(.WIDTH(32)) reg_inst      (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(inst_i),     .data_o(inst_o));
PipelineRegister #(.WIDTH(32)) reg_pc        (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(pc_i),      .data_o(pc_o));
PipelineRegister #(.WIDTH(32)) reg_pc_p4     (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(pc_p4_i),   .data_o(pc_p4_o));

PipelineRegister #(.WIDTH(32)) reg_rd_data1  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_rd_data1_i), .data_o(reg_rd_data1_o));
PipelineRegister #(.WIDTH(32)) reg_rd_data2  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_rd_data2_i), .data_o(reg_rd_data2_o));

PipelineRegister #(.WIDTH(32)) reg_imm       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(imm_i),      .data_o(imm_o));
PipelineRegister #(.WIDTH(5))  reg_rd        (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rd_i),       .data_o(rd_o));
PipelineRegister #(.WIDTH(5))  reg_rs1       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rs1_i),      .data_o(rs1_o));
PipelineRegister #(.WIDTH(5))  reg_rs2       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rs2_i),      .data_o(rs2_o));
PipelineRegister #(.WIDTH(5))  reg_rs3       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rs3_i),      .data_o(rs3_o));

// control
PipelineRegister #(.WIDTH(1))  reg_reg_wr_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_wr_en_i), .data_o(reg_wr_en_o));
PipelineRegister #(.WIDTH(3))  reg_reg_w_sel (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_w_sel_i), .data_o(reg_w_sel_o));
// mem
PipelineRegister #(.WIDTH(1))  reg_mem_rd_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_rd_en_i), .data_o(mem_rd_en_o));
PipelineRegister #(.WIDTH(1))  reg_mem_wr_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_wr_en_i), .data_o(mem_wr_en_o));
PipelineRegister #(.WIDTH(4))  reg_mem_ctrl  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_ctrl_i), .data_o(mem_ctrl_o));
// Br and Jump
PipelineRegister #(.WIDTH(1))  reg_is_j      (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_j_i), .data_o(is_j_o));
PipelineRegister #(.WIDTH(1))  reg_is_br     (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_br_i), .data_o(is_br_o));
// ALU
PipelineRegister #(.WIDTH(1))  reg_ALU_sel1  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_sel1_i), .data_o(ALU_sel1_o));
PipelineRegister #(.WIDTH(1))  reg_ALU_sel2  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_sel2_i), .data_o(ALU_sel2_o));
PipelineRegister #(.WIDTH(4))  reg_ALU_ctrl  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_ctrl_i), .data_o(ALU_ctrl_o));
// cmp
PipelineRegister #(.WIDTH(3))  reg_cmp_op    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(cmp_op_i), .data_o(cmp_op_o));
// MUL/DIV
PipelineRegister #(.WIDTH(1))  reg_is_MUL_DIV (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_MUL_DIV_i), .data_o(is_MUL_DIV_o));
PipelineRegister #(.WIDTH(3))  reg_MUL_DIV_ctrl (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(MUL_DIV_ctrl_i), .data_o(MUL_DIV_ctrl_o));
// csr
PipelineRegister #(.WIDTH(12)) reg_csr_addr  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(csr_addr_i), .data_o(csr_addr_o));
PipelineRegister #(.WIDTH(1))  reg_is_csr    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_csr_i), .data_o(is_csr_o));

// vpu
PipelineRegister #(.WIDTH(1))  reg_is_npu    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_npu_i), .data_o(is_npu_o));
// bypass
PipelineRegister #(.WIDTH(2))  reg_bypass_sel (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(bypass_sel_i), .data_o(bypass_sel_o));
// Fence
PipelineRegister #(.WIDTH(1))  reg_fetch_invalid (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(fetch_invalid_i), .data_o(fetch_invalid_o));

// Cache Operations
PipelineRegister #(.WIDTH(1)) reg_is_dflush (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(is_dflush_i), .data_o(is_dflush_o));
PipelineRegister #(.WIDTH(1)) reg_is_dinval (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(is_dinval_i), .data_o(is_dinval_o));
PipelineRegister #(.WIDTH(1)) reg_is_dwb    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(is_dwb_i),    .data_o(is_dwb_o));


// Forwarding
wire EX_fwd1_sel;
wire EX_fwd2_sel;
ForwardUnit m_Forward(
    .EX_rs1(rs1_o),
    .EX_rs2(rs2_o),
    .EX_rs3(rs3_o),
    
    .WB_rd(WB_rd_i),
    .WB_reg_wr_en(WB_reg_wr_en_i),
    
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel)
);

wire [31:0] current_fwd_data1;
wire [31:0] current_fwd_data2;

Mux2to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(EX_fwd1_sel),
    .s0(wb_data_i),
    .s1(reg_rd_data1_o),
    .out(current_fwd_data1)
);
Mux2to1 #(.size(32)) m_EX_fwd2_MUX(
    .sel(EX_fwd2_sel),
    .s0(wb_data_i),
    .s1(reg_rd_data2_o),
    .out(current_fwd_data2)
);

// EX start control
wire bypass_start;
wire ALU_start;
wire Br_start;
wire SYS_start;

reg started;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) started <= 0;
    else begin     
        if(EX_done_o || !(pc_valid_o && is_impl_o)) started <= 0;
        else if((pc_valid_o && is_impl_o) && !started)
            started <= 1;
    end
end
assign EX_start_o = (!started) && (pc_valid_o && is_impl_o);

reg [31:0] held_fwd_data1;
reg [31:0] held_fwd_data2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        held_fwd_data1 <= 32'd0;
        held_fwd_data2 <= 32'd0;
    end else if (!started) begin
        held_fwd_data1 <= current_fwd_data1;
        held_fwd_data2 <= current_fwd_data2;
    end
end

assign reg_fwd_data1_o = started ? held_fwd_data1 : current_fwd_data1;
assign reg_fwd_data2_o = started ? held_fwd_data2 : current_fwd_data2;

// ALU src
wire [31:0] ALU_src1, ALU_src2;
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(ALU_sel1_o),
    .s0(pc_o),
    .s1(reg_fwd_data1_o),
    .out(ALU_src1)
);
Mux2to1 #(.size(32)) m_ALU_SRC2_MUX(
    .sel(ALU_sel2_o),
    .s0(reg_fwd_data2_o),
    .s1(imm_o),
    .out(ALU_src2)
);

assign bypass_start = EX_start_o && (|bypass_sel_o);
assign ALU_start = EX_start_o && (|ALU_ctrl_o);
assign Br_start  = EX_start_o && (is_br_o || is_j_o);
assign SYS_start = EX_start_o && is_csr_o;
assign MUL_DIV_start_o = EX_start_o && is_MUL_DIV_o;
assign NPU_start_o = EX_start_o && is_npu_o;
assign LSU_start_o = EX_start_o && 
    (mem_wr_en_o || mem_rd_en_o || (mem_ctrl_o[1:0] == 2'b11) || (mem_ctrl_o[2:1] == 2'b11) ||
     is_dflush_o || is_dinval_o || is_dwb_o);

// ALU =========================
wire ALU_done;
ALU_top m_ALU(
    .ALU_ctrl(ALU_ctrl_o),
    .a(ALU_src1),
    .b(ALU_src2),
    .is_imm_i(ALU_sel2_o),
    
    .out(ALU_o)
);
assign ALU_done = ALU_start;

// BypassUnit ==================
wire bypass_done;
BypassUnit m_BypassUnit(
    .bypass_sel(bypass_sel_o),
    .imm(imm_o),
    .reg_data1(reg_fwd_data1_o),
    .result_o(bypass_o)
);
assign bypass_done = bypass_start;

// Branch Unit =================
wire Br_done;
BranchUnit m_Branch(
    .is_br(is_br_o),
    .is_j(is_j_o),
    .cmp_op(cmp_op_o),
    .reg_rd_data1(reg_fwd_data1_o),
    .reg_rd_data2(reg_fwd_data2_o),

    .br_taken(br_taken_o)
);
assign Br_done = Br_start;

// CSR =========================
CSR m_CSR(
    .clk(clk),
    .rst_n(rst_n),
    .csr_rd_addr_i(csr_addr_o),
    .csr_rd_data_o(csr_rd_data_o)
);

assign SYS_done = SYS_start;

// LSU ==========================
assign lsu_addr_o = reg_fwd_data1_o + imm_o;
assign lsu_wdata_o = reg_fwd_data2_o;

wire is_lb_sb = (mem_ctrl_o[2:0] == 3'b001);
wire is_lh_sh = (mem_ctrl_o[2:0] == 3'b010);
wire is_lw_sw = (mem_ctrl_o[2:0] == 3'b100);

reg [3:0] lsu_mask_r;
always @(*) begin
    lsu_mask_r = 4'b0000;
    if (mem_rd_en_o || mem_wr_en_o) begin
        if (is_lb_sb) begin
            lsu_mask_r = 4'b0001;
        end else if (is_lh_sh) begin
            lsu_mask_r = 4'b0011;
        end else if (is_lw_sw) begin
            lsu_mask_r = 4'b1111;
        end
    end
end
assign lsu_mask_o = lsu_mask_r;

assign EX_done_o = (!pc_valid_o) | (!is_impl_o) | 
    ALU_done | Br_done | LSU_done_i | 
    SYS_done | bypass_done | MUL_DIV_done_i | 
    NPU_done_i | 
    fetch_invalid_o; 

endmodule