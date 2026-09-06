module Frontend_top(
    input         clk,
    input         rst_n,

    input         redirect_valid_i,
    input  [31:0] redirect_pc_i,

    input         invalidate_i,
    output        invalid_complete,

    input         req_inst_i,
    output        inst_rdy_o,
    output [31:0] inst_pc_o,
    output [31:0] inst_o,

    input         rm_rdy,
    input         rm_success,
    input         rm_complete,
    input [255:0] rm_data,
    output        req_rm,
    output [31:0] rm_addr
);

(* mark_debug = "true" *)   wire        ibuf_ready;
(* mark_debug = "true" *)   wire        ibuf_almost_full;
(* mark_debug = "true" *)   wire        ibuf_push;
(* mark_debug = "true" *)   wire        ibuf_flush;

(* mark_debug = "true" *)   wire        fetch_valid;
(* mark_debug = "true" *)   wire        ibus_ready;
(* mark_debug = "true" *)   wire        ibus_hit;
(* mark_debug = "true" *)   wire        inst_valid;
(* mark_debug = "true" *)   wire [31:0] fetch_addr;

(* mark_debug = "true" *)   wire [31:0] inst_data;
(* mark_debug = "true" *)   wire [31:0] inst_pc;
  
(* mark_debug = "true" *)   wire        ibus_flush;
(* mark_debug = "true" *)   wire        ibus_invld;
(* mark_debug = "true" *)   wire        flush_status;

    Fetch_ctrl m_fetch_ctrl (
        .clk                (clk),
        .rst_n              (rst_n),
        .redirect_valid_i   (redirect_valid_i),
        .redirect_pc_i      (redirect_pc_i),
        .invalidate_i       (invalidate_i),
        .invalid_complete   (invalid_complete),
        .ibuf_ready_i       (ibuf_ready),
        .ibuf_almost_full_i (ibuf_almost_full), 
        .ibuf_push_o        (ibuf_push),
        .ibuf_flush_o       (ibuf_flush),
        .ibus_hit_i         (ibus_hit),
        .ibus_ready_i       (ibus_ready),
        .inst_valid_i       (inst_valid),
        .ibus_fetch_vld_o   (fetch_valid),
        .flush_status_i     (flush_status),
        .ibus_flush_o       (ibus_flush),
        .ibus_invld_o       (ibus_invld),
        .ibus_addr_o        (fetch_addr)
    );

    I_bus m_ibus (
        .clk            (clk),
        .rst_n          (rst_n),
        .fetch_vld      (fetch_valid),
        .fetch_addr     (fetch_addr),
        .ibus_ready     (ibus_ready),
        .inst_valid     (inst_valid),
        .ibus_hit       (ibus_hit),
        .inst_o         (inst_data),
        .pc_o           (inst_pc),
        .invalidate_i   (ibus_invld),
        .flush_i        (ibus_flush),
        .flush_status_o (flush_status),
        .rm_rdy         (rm_rdy),
        .rm_addr        (rm_addr),
        .rm_success     (rm_success),
        .rm_complete    (rm_complete),
        .req_rm         (req_rm),
        .rm_data        (rm_data)
    );

    Inst_buf m_inst_buf (
        .clk            (clk),   
        .rst_n          (rst_n),
        .push_valid_i   (ibuf_push),
        .push_pc_i      (inst_pc),
        .push_inst_i    (inst_data),
        .push_ready_o   (ibuf_ready),
        .almost_full_o  (ibuf_almost_full), 
        .flush          (ibuf_flush),
        .inst_rdy_o     (inst_rdy_o),
        .inst_pc_o      (inst_pc_o),
        .inst_o         (inst_o),
        .req_inst_i     (req_inst_i)
    );

endmodule