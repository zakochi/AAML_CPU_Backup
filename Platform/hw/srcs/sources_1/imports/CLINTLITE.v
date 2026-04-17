module clint_axiLite_slave (
    input wire aclk,
    input wire aresetn,

    // AW Channel 
    input  wire        s_axi_lite_awvalid,
    output reg         s_axi_lite_awready,
    input  wire [31:0] s_axi_lite_awaddr,
    
    // W Channel
    input  wire        s_axi_lite_wvalid,
    output reg         s_axi_lite_wready,
    input  wire [31:0] s_axi_lite_wdata,
    input  wire [ 3:0] s_axi_lite_wstrb,
    
    // B Channel
    output reg         s_axi_lite_bvalid,
    input  wire        s_axi_lite_bready,
    output reg  [ 1:0] s_axi_lite_bresp,

    // AR Channel 
    input  wire        s_axi_lite_arvalid,
    output reg         s_axi_lite_arready,
    input  wire [31:0] s_axi_lite_araddr,
    
    // R Channel
    output reg         s_axi_lite_rvalid,
    input  wire        s_axi_lite_rready,
    output reg  [31:0] s_axi_lite_rdata,
    output reg  [ 1:0] s_axi_lite_rresp,

    // ---------------------------------------
    // Interrupt Outputs (To CPU CSR)
    // ---------------------------------------
    output wire        timer_irq_o, // 接到 CPU CSR (Machine Timer Interrupt)
    output wire        soft_irq_o   // 接到 CPU CSR (Machine Software Interrupt)
);

    // =======================================
    // 內部暫存器宣告 (64-bit 時間與 32-bit 軟體中斷)
    // =======================================
    reg [63:0] mtime;
    reg [63:0] mtimecmp;
    reg [31:0] msip;

    // ---------------------------------------
    // 硬體行為邏輯 (概念示意)
    // ---------------------------------------
    
    // 1. mtime 永遠在背景自己 +1
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mtime <= 64'd0;
        end else begin
            mtime <= mtime + 1'b1;
        end
    end

    // 2. 中斷觸發條件 (這就是 CLINT 最核心的兩行 code)
    assign timer_irq_o = (mtime >= mtimecmp) ? 1'b1 : 1'b0;
    assign soft_irq_o  = (msip[0] == 1'b1)   ? 1'b1 : 1'b0;

    // TODO: 接下來你要寫 AXI-Lite 的 Read/Write FSM
    // 在 Write FSM 中，利用 s_axi_lite_awaddr 的 Offset 來決定：
    // addr == 0x0000 -> 寫入 msip
    // addr == 0x4000 -> 寫入 mtimecmp[31:0]
    // addr == 0x4004 -> 寫入 mtimecmp[63:32]
    // ...以此類推

endmodule