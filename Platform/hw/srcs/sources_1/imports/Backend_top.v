`timescale 1ns / 1ps
`include "riscv_defs.v"

module Backend_top (
    input             clk,
    input             rst_n,

    // Frontend Interface
    input             inst_rdy_i,
    input      [31:0] inst_pc_i,
    input      [31:0] inst_i,
    output            req_inst_o,
    output            redirect_valid_o,
    output     [31:0] redirect_pc_o,
    output            invalidate_o,
    input             invalid_complete_i,

    // D-Cache AXI Interfaces
    output     [31:0] dbus_rm_addr, 
    input             dbus_rm_rdy, 
    input     [255:0] dbus_rm_data,
    input             dbus_rm_success, 
    input             dbus_rm_complete, 
    output            dbus_rm_vld,
    input             dbus_wm_rdy, 
    output    [255:0] dbus_wm_data, 
    output            dbus_wm_vld,
    input             dbus_wm_success, 
    input             dbus_wm_complete,

    // I-Cache AXI Interfaces
    output     [31:0] ibus_rm_addr, 
    input             ibus_rm_rdy, 
    input     [255:0] ibus_rm_data,
    input             ibus_rm_success, 
    input             ibus_rm_complete, 
    output            ibus_rm_vld,

    // AXI-Lite MMIO Interfaces
    output            m_axi_lite_awvalid, 
    input             m_axi_lite_awready, 
    output     [31:0] m_axi_lite_awaddr,
    output            m_axi_lite_wvalid, 
    input             m_axi_lite_wready, 
    output     [31:0] m_axi_lite_wdata,
    output     [ 3:0] m_axi_lite_wstrb, 
    input             m_axi_lite_bvalid, 
    output            m_axi_lite_bready,
    input      [ 1:0] m_axi_lite_bresp, 
    output            m_axi_lite_arvalid, 
    input             m_axi_lite_arready,
    output     [31:0] m_axi_lite_araddr, 
    input             m_axi_lite_rvalid, 
    output            m_axi_lite_rready,
    input      [31:0] m_axi_lite_rdata, 
    input      [ 1:0] m_axi_lite_rresp,

    // NPU Interface
    output     [31:0] rs1_o, 
    output     [31:0] rs2_o, 
    input      [31:0] NPU_out,
    output            NPU_start, 
    input             NPU_done, 
    output     [ 3:0] funct3_o, 
    output     [31:0] funct7_o
);

(* mark_debug = "true" *)wire EX_done, EX_pc_valid_out, EX_is_br_out, EX_is_j_out, br_taken, EX_fetch_invalid_out;
(* mark_debug = "true" *)wire [31:0] ALU_out, EX_pc_p4_out;
wire EX_is_impl_out;

(* mark_debug = "true" *)wire br_flush = EX_pc_valid_out && ((EX_is_br_out && br_taken) || EX_is_j_out);
wire fencei_flush = EX_pc_valid_out && EX_fetch_invalid_out;
assign invalidate_o = fencei_flush;

(* mark_debug = "true" *)wire redirect_flush = br_flush | fencei_flush;

wire EX_stall = ~EX_done;
wire IF_stall = (~inst_rdy_i) & (~EX_stall);

wire pc_en, ID_en, ID_clear, EX_en, EX_clear, WB_en, WB_clear;

assign req_inst_o = inst_rdy_i & ID_en & ~redirect_flush;
assign redirect_valid_o = redirect_flush;
assign redirect_pc_o    = br_flush ? {ALU_out[31:2], 2'b0} : EX_pc_p4_out;

PipelineCtrl m_PipelineCtrl(
    .br_flush (redirect_flush),
    .IF_stall (IF_stall),
    .EX_stall (EX_stall),
    .pc_en    (pc_en),
    .ID_en    (ID_en),
    .ID_clear (ID_clear),
    .EX_en    (EX_en),
    .EX_clear (EX_clear),
    .WB_en    (WB_en),
    .WB_clear (WB_clear)
);

(* mark_debug = "true" *)wire        ID_pc_valid_out;
(* mark_debug = "true" *)wire [31:0] ID_pc_out, ID_pc_p4_out, ID_inst_out, decode_imm;
wire [4:0]  decode_rs1, decode_rs2, decode_rs3, decode_rd;
wire [11:0] decode_csr_addr;
wire        is_impl, reg_wr_en, mem_wr_en, mem_rd_en, is_j, is_br, ALU_sel1, ALU_sel2, is_MUL_DIV, is_csr, is_npu, fetch_invalid;
wire [2:0]  reg_w_sel, cmp_op, MUL_DIV_ctrl;
wire [3:0]  mem_ctrl, ALU_ctrl;
wire [1:0]  bypass_sel;

// Cache Operations Wires from ID
wire id_is_dflush, id_is_dinval, id_is_dwb;

wire [31:0] inst_pc_p4 = inst_pc_i + 32'd4;

Decode m_ID(
    .clk             (clk),
    .rst_n           (rst_n),
    .en              (ID_en),
    .clear           (ID_clear),
    .inst_valid_i    (inst_rdy_i),
    .pc_i            (inst_pc_i),
    .pc_p4_i         (inst_pc_p4),
    .inst_i          (inst_i),
    .pc_valid_o      (ID_pc_valid_out),
    .pc_o            (ID_pc_out),
    .pc_p4_o         (ID_pc_p4_out),
    .inst_o          (ID_inst_out),
    .rs1_o           (decode_rs1),
    .rs2_o           (decode_rs2),
    .rs3_o           (decode_rs3),
    .rd_o            (decode_rd),
    .csr_addr_o      (decode_csr_addr),
    .imm_o           (decode_imm),
    .reg_wr_en_o     (reg_wr_en),
    .reg_w_sel_o     (reg_w_sel),
    .mem_wr_en_o     (mem_wr_en),
    .mem_rd_en_o     (mem_rd_en),
    .mem_ctrl_o      (mem_ctrl),
    .is_j_o          (is_j),
    .is_br_o         (is_br),
    .cmp_op_o        (cmp_op),
    .ALU_ctrl_o      (ALU_ctrl),
    .ALU_sel1_o      (ALU_sel1),
    .ALU_sel2_o      (ALU_sel2),
    .is_MUL_DIV_o    (is_MUL_DIV),
    .MUL_DIV_ctrl_o  (MUL_DIV_ctrl),
    .is_csr_o        (is_csr),
    .is_npu_o        (is_npu),
    .bypass_sel_o    (bypass_sel),
    .fetch_invalid_o (fetch_invalid),
    .is_impl_o       (is_impl),
    
    .is_dflush_o     (id_is_dflush),
    .is_dinval_o     (id_is_dinval),
    .is_dwb_o        (id_is_dwb)
);

(* mark_debug = "true" *)wire [31:0] wb_data_in, reg_data1_out, reg_data2_out;
(* mark_debug = "true" *)wire        WB_reg_wr_en_out;
(* mark_debug = "true" *)wire [4:0]  WB_rd_out;

Register m_Register(
    .clk        (clk),
    .rst_n      (rst_n),
    .wr_en      (WB_reg_wr_en_out),
    .rs1        (decode_rs1),
    .rs2        (decode_rs2),
    .rd         (WB_rd_out),
    .data_i     (wb_data_in),
    .rd_data1_o (reg_data1_out),
    .rd_data2_o (reg_data2_out)
);

(* mark_debug = "true" *)wire EX_reg_wr_en_out, EX_mem_rd_en_out, EX_mem_wr_en_out, EX_is_MUL_DIV_out, EX_is_csr_out, EX_is_npu_out;
(* mark_debug = "true" *)wire [31:0] EX_inst_out, EX_imm_out, EX_fwd_data1, EX_fwd_data2;
(* mark_debug = "true" *)wire [4:0]  EX_rd_out, EX_rs1_out, EX_rs2_out, EX_rs3_out;
wire [2:0]  EX_reg_w_sel_out, EX_cmp_op_out, EX_MUL_DIV_ctrl_out;
wire [3:0]  EX_mem_ctrl_out, EX_ALU_ctrl_out;
wire [11:0] EX_csr_addr_out;
wire [1:0]  EX_bypass_sel_out;
wire EX_start, MUL_DIV_start, LSU_start, MUL_DIV_done, LSU_done;

// Cache Operations Wires from EX
wire ex_is_dflush, ex_is_dinval, ex_is_dwb;

wire [31:0] MUL_out, DIV_out, bypass_out, csr_rd_data;
wire NPU_start_w; 

wire [31:0] EX_lsu_addr, EX_lsu_wdata;
wire [ 3:0] EX_lsu_mask;

Exec m_EX(
    .clk              (clk),
    .rst_n            (rst_n),
    .en               (EX_en),
    .clear            (EX_clear),
    .is_impl_i        (is_impl),
    .pc_valid_i       (ID_pc_valid_out),
    .inst_i           (ID_inst_out),
    .pc_i             (ID_pc_out),
    .pc_p4_i          (ID_pc_p4_out),
    .reg_rd_data1_i   (reg_data1_out),
    .reg_rd_data2_i   (reg_data2_out),
    .imm_i            (decode_imm),
    .rd_i             (decode_rd),
    .rs1_i            (decode_rs1),
    .rs2_i            (decode_rs2),
    .rs3_i            (decode_rs3),
    .reg_wr_en_i      (reg_wr_en),
    .reg_w_sel_i      (reg_w_sel),
    .mem_rd_en_i      (mem_rd_en),
    .mem_wr_en_i      (mem_wr_en),
    .mem_ctrl_i       (mem_ctrl),
    .is_j_i           (is_j),
    .is_br_i          (is_br),
    .cmp_op_i         (cmp_op),
    .ALU_sel1_i       (ALU_sel1),
    .ALU_sel2_i       (ALU_sel2),
    .ALU_ctrl_i       (ALU_ctrl),
    .is_MUL_DIV_i     (is_MUL_DIV),
    .MUL_DIV_ctrl_i   (MUL_DIV_ctrl),
    .csr_addr_i       (decode_csr_addr),
    .is_csr_i         (is_csr),
    .is_npu_i         (is_npu),
    .bypass_sel_i     (bypass_sel),
    .fetch_invalid_i  (fetch_invalid),
    
    .is_dflush_i      (id_is_dflush),
    .is_dinval_i      (id_is_dinval),
    .is_dwb_i         (id_is_dwb),
    
    .WB_rd_i          (WB_rd_out),
    .WB_reg_wr_en_i   (WB_reg_wr_en_out),
    .wb_data_i        (wb_data_in),

    .is_impl_o        (EX_is_impl_out),
    .pc_valid_o       (EX_pc_valid_out),
    .inst_o           (EX_inst_out),
    .pc_p4_o          (EX_pc_p4_out),
    .reg_fwd_data1_o  (EX_fwd_data1),
    .reg_fwd_data2_o  (EX_fwd_data2),
    .imm_o            (EX_imm_out),
    .rd_o             (EX_rd_out),
    .rs1_o            (EX_rs1_out),
    .rs2_o            (EX_rs2_out),
    .rs3_o            (EX_rs3_out),
    .reg_wr_en_o      (EX_reg_wr_en_out),
    .reg_w_sel_o      (EX_reg_w_sel_out),
    .mem_rd_en_o      (EX_mem_rd_en_out),
    .mem_wr_en_o      (EX_mem_wr_en_out),
    .mem_ctrl_o       (EX_mem_ctrl_out),
    .is_j_o           (EX_is_j_out),
    .is_br_o          (EX_is_br_out),
    .br_taken_o       (br_taken),
    .ALU_ctrl_o       (EX_ALU_ctrl_out),
    .ALU_o            (ALU_out),
    .is_MUL_DIV_o     (EX_is_MUL_DIV_out),
    .MUL_DIV_ctrl_o   (EX_MUL_DIV_ctrl_out),
    .csr_rd_data_o    (csr_rd_data),
    
    .lsu_addr_o       (EX_lsu_addr),
    .lsu_wdata_o      (EX_lsu_wdata),
    .lsu_mask_o       (EX_lsu_mask),
    
    .is_npu_o         (EX_is_npu_out),
    .bypass_sel_o     (EX_bypass_sel_out),
    .bypass_o         (bypass_out),
    .fetch_invalid_o  (EX_fetch_invalid_out),
    
    .is_dflush_o      (ex_is_dflush),
    .is_dinval_o      (ex_is_dinval),
    .is_dwb_o         (ex_is_dwb),

    .EX_start_o       (EX_start),
    .MUL_DIV_start_o  (MUL_DIV_start), 
    .NPU_start_o      (NPU_start_w),  
    .LSU_start_o      (LSU_start),
    .MUL_DIV_done_i   (MUL_DIV_done),
    .NPU_done_i       (NPU_done),
    .LSU_done_i       (LSU_done),
    .EX_done_o        (EX_done)
);

reg [31:0] npu_rs1_r, npu_rs2_r;
reg [ 3:0] npu_funct3_r;
reg [31:0] npu_funct7_r;
reg        npu_start_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        npu_rs1_r    <= 32'd0;
        npu_rs2_r    <= 32'd0;
        npu_funct3_r <= 4'd0;
        npu_funct7_r <= 32'd0;
        npu_start_r  <= 1'b0;
    end else begin
        npu_rs1_r    <= EX_fwd_data1;
        npu_rs2_r    <= EX_fwd_data2;
        npu_funct3_r <= EX_inst_out[14:12];
        npu_funct7_r <= EX_inst_out[31:25];
        npu_start_r  <= NPU_start_w;
    end
end

assign rs1_o     = npu_rs1_r;
assign rs2_o     = npu_rs2_r;
assign funct3_o  = npu_funct3_r;
assign funct7_o  = npu_funct7_r;
assign NPU_start = npu_start_r;

MUL_DIV_top m_MUL_DIV_top(
    .clk           (clk),
    .rst_n         (rst_n),
    .data1         (EX_fwd_data1),
    .data2         (EX_fwd_data2),
    .MUL_DIV_start (MUL_DIV_start), 
    .MUL_DIV_ctrl  (EX_MUL_DIV_ctrl_out),
    .MUL_out       (MUL_out), 
    .DIV_out       (DIV_out), 
    .MUL_DIV_done  (MUL_DIV_done)
);

wire [31:0] mem_shared_addr, mem_shared_data;
wire [ 3:0] mem_shared_mask;

(* mark_debug = "true" *)wire dcache_req_rd, dcache_req_wr;
(* mark_debug = "true" *)wire cdma_req_rd, cdma_req_wr;
wire [31:0] dcache_rdata, cdma_rdata;
wire dcache_vld, cdma_vld;
wire dcache_flush, dcache_inv, dcache_wb, i_inv;
wire dcache_rdy; 

wire [31:0] lsu_writeback_value_o;
wire        lsu_writeback_valid_o;

(* mark_debug = "true" *)assign LSU_done = lsu_writeback_valid_o;

lsu u_lsu (
    .clk_i                (clk), 
    .rst_i                (rst_n),
    
    .opcode_valid_i       (LSU_start), 
    .is_dflush_i          (ex_is_dflush),
    .is_dinval_i          (ex_is_dinval),
    .is_dwb_i             (ex_is_dwb),
    
    .ex_mem_rd_i          (EX_mem_rd_en_out),
    .ex_mem_wr_i          (EX_mem_wr_en_out), 
    .ex_mem_ctrl_i        (EX_mem_ctrl_out),
    .lsu_addr_i           (EX_lsu_addr),
    .lsu_wdata_i          (EX_lsu_wdata),
    .lsu_mask_i           (EX_lsu_mask),
    
    .mem_addr_o           (mem_shared_addr),
    .mem_data_o           (mem_shared_data),
    .mem_mask_o           (mem_shared_mask),
    
    .dcache_rd_o          (dcache_req_rd),
    .dcache_wr_o          (dcache_req_wr),
    .dcache_value_i       (dcache_rdata),
    .dcache_vld_i         (dcache_vld),
    .dcache_rdy_i         (dcache_rdy), 
    .dcache_dflush_o      (dcache_flush),
    .dcache_dinvalidate_o (dcache_inv),
    .dcache_dwriteback_o  (dcache_wb),
    .icache_invalidate_o  (i_inv),      
    
    .cdma_rd_o            (cdma_req_rd),
    .cdma_wr_o            (cdma_req_wr),
    .cdma_value_i         (cdma_rdata),
    .cdma_valid_i         (cdma_vld),
    
    .writeback_value_o    (lsu_writeback_value_o),
    .writeback_valid_o    (lsu_writeback_valid_o)
);

dcache_pro m_dcache (
    .clk               (clk),
    .rst_n             (rst_n), 
    .cpu_daddr_i       (mem_shared_addr),
    .cpu_data_i        (mem_shared_data), 
    .mask_i            (mem_shared_mask), 
    .cpu_req_wr        (dcache_req_wr),
    .cpu_req_rd        (dcache_req_rd), 
    .cpu_data_o        (dcache_rdata), 
    .dcache_rdy_o      (dcache_rdy),
    .dcache_vld_o         (dcache_vld), 
    .d_exception       (), 
    .invalidate_i      (dcache_inv),
    .flush_i           (dcache_flush), 
    .writeback_i       (dcache_wb), 
    .mem_addr          (dbus_rm_addr),
    .rm_rdy            (dbus_rm_rdy),
    .rm_data           (dbus_rm_data),
    .rm_success        (dbus_rm_success),
    .rm_complete       (dbus_rm_complete),
    .rm_vld            (dbus_rm_vld),
    .wm_rdy            (dbus_wm_rdy),
    .wm_data           (dbus_wm_data),
    .wm_vld            (dbus_wm_vld),
    .wm_success        (dbus_wm_success),
    .wm_complete       (dbus_wm_complete)
);

cpu_axiLite_bridge m_axi_lite_bridge (
    .aclk               (clk),
    .aresetn            (rst_n), 
    .req_rd_mm          (cdma_req_rd),
    .req_wr_mm          (cdma_req_wr), 
    .mm_addr_i          (mem_shared_addr), 
    .mm_data_i          (mem_shared_data),
    .mm_data_out        (cdma_rdata), 
    .mm_exception       (), 
    .mm_rdy             (), 
    .mm_vld             (cdma_vld),
    .m_axi_lite_awvalid (m_axi_lite_awvalid),
    .m_axi_lite_awready (m_axi_lite_awready),
    .m_axi_lite_awaddr  (m_axi_lite_awaddr),
    .m_axi_lite_wvalid  (m_axi_lite_wvalid),
    .m_axi_lite_wready  (m_axi_lite_wready),
    .m_axi_lite_wdata   (m_axi_lite_wdata),
    .m_axi_lite_wstrb   (m_axi_lite_wstrb),
    .m_axi_lite_bvalid  (m_axi_lite_bvalid),
    .m_axi_lite_bready  (m_axi_lite_bready),
    .m_axi_lite_bresp   (m_axi_lite_bresp),
    .m_axi_lite_arvalid (m_axi_lite_arvalid),
    .m_axi_lite_arready (m_axi_lite_arready),
    .m_axi_lite_araddr  (m_axi_lite_araddr),
    .m_axi_lite_rvalid  (m_axi_lite_rvalid),
    .m_axi_lite_rready  (m_axi_lite_rready),
    .m_axi_lite_rdata   (m_axi_lite_rdata),
    .m_axi_lite_rresp   (m_axi_lite_rresp)
);

wire        WB_is_impl_out, WB_pc_valid_out;
wire [31:0] WB_pc_out;

Writeback m_WB(
    .clk           (clk),
    .rst_n         (rst_n),
    .en            (WB_en),
    .clear         (WB_clear),
    .is_impl_i     (EX_is_impl_out),
    .pc_valid_i    (EX_pc_valid_out),
    
    .pc_p4_i       (EX_pc_p4_out),
    
    .rd_i          (EX_rd_out),
    .bypass_i      (bypass_out),
    .ALU_i         (ALU_out),
    .MUL_DIV_i     (DIV_out), 
    .NPU_i         (NPU_out),
    .mem_data_i    (lsu_writeback_value_o), 
    .csr_rd_data_i (csr_rd_data),
    .MUL_out_i     (MUL_out),
    
    .is_mul_i      (EX_is_MUL_DIV_out & ~EX_MUL_DIV_ctrl_out[2]), 
    
    .reg_wr_en_i   (EX_reg_wr_en_out),
    .reg_w_sel_i   (EX_reg_w_sel_out),
    .is_impl_o     (WB_is_impl_out),
    .pc_valid_o    (WB_pc_valid_out),
    .rd_o          (WB_rd_out),
    .wb_data_o     (wb_data_in),
    .reg_wr_en_o   (WB_reg_wr_en_out)
);

endmodule