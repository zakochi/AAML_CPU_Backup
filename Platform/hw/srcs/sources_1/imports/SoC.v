`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2026 11:31:35 PM
// Design Name: 
// Module Name: SoC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SoC(
    input         CLK100MHZ,
    input         CPU_RESETN,
    output [12:0] DDR2_addr,
    output [2:0]  DDR2_ba,
    output        DDR2_cas_n,
    output [0:0]  DDR2_ck_n,
    output [0:0]  DDR2_ck_p,
    output [0:0]  DDR2_cke,
    output [0:0]  DDR2_cs_n,
    output [1:0]  DDR2_dm,
    inout  [15:0] DDR2_dq,
    inout  [1:0]  DDR2_dqs_n,
    inout  [1:0]  DDR2_dqs_p,
    output [0:0]  DDR2_odt,
    output        DDR2_ras_n,
    output        DDR2_we_n,
    input         UART_rxd,
    output        UART_txd,
    output        mb_reset,
    
    output        diag_led_blink, 
    output        diag_led_rst   
);

    wire sys_clk;
    
    reg [26:0] cnt;
    always @(posedge sys_clk) cnt <= cnt + 1;
    assign diag_led_blink = cnt[26];   
    assign diag_led_rst   = ~CPU_RESETN; 
    
    
      MMIO MMIO_i
       (.DDR2_0_addr(DDR2_addr),
        .DDR2_0_ba(DDR2_ba),
        .DDR2_0_cas_n(DDR2_cas_n),
        .DDR2_0_ck_n(DDR2_ck_n),
        .DDR2_0_ck_p(DDR2_ck_p),
        .DDR2_0_cke(DDR2_cke),
        .DDR2_0_cs_n(DDR2_cs_n),
        .DDR2_0_dm(DDR2_dm),
        .DDR2_0_dq(DDR2_dq),
        .DDR2_0_dqs_n(DDR2_dqs_n),
        .DDR2_0_dqs_p(DDR2_dqs_p),
        .DDR2_0_odt(DDR2_odt),
        .DDR2_0_ras_n(DDR2_ras_n),
        .DDR2_0_we_n(DDR2_we_n),
        .UART_0_rxd(UART_rxd),
        .UART_0_txd(UART_txd),
        .button_resetn(CPU_RESETN),
        .clk_in(CLK100MHZ),
        .mem_retn(),
        .sys_clk(sys_clk));
endmodule
