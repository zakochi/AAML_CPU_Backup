`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21 19:38:15
// Design Name: 
// Module Name: dcache_axiBus_bridge
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


module NPU(
    input clk,
    input rst_n,

    // CPU Interface //
    input [31:0] rs1_i,
    input [31:0] rs2_i,
    output reg [31:0] NPU_out,
    input        NPU_start,
    output reg   NPU_done,
    output reg   NPU_exception,
    input [3:0]  funct3_i,
    input [31:0] funct7_i,

    // AXI4 Master Interface (M_AXI) //
    // AW Channel
    //output  [3:0] M_AXI_AWID,
    output reg [31:0] M_AXI_AWADDR,
    output  [7:0] M_AXI_AWLEN,
    output  [2:0] M_AXI_AWSIZE,
    output  [1:0] M_AXI_AWBURST,
    output  M_AXI_AWLOCK,
    output  [3:0] M_AXI_AWCACHE,
    output  [2:0] M_AXI_AWPROT,
    output  [3:0] M_AXI_AWQOS,
    output  [15:0] M_AXI_AWUSER,
    output reg M_AXI_AWVALID,
    input M_AXI_AWREADY,
    // W Channel
    output reg [31:0] M_AXI_WDATA,
    output  [3:0] M_AXI_WSTRB,
    output reg M_AXI_WLAST,
    output reg M_AXI_WVALID,
    input M_AXI_WREADY,
    
    // B Channel
    //input [3:0] M_AXI_BID,
    input [1:0] M_AXI_BRESP,
    //input [15:0] M_AXI_BUSER,
    input M_AXI_BVALID,
    output  M_AXI_BREADY,
    
    // AR Channel
    //output  [3:0] M_AXI_ARID,
    output reg [31:0] M_AXI_ARADDR,
    output  [7:0] M_AXI_ARLEN,
    output  [2:0] M_AXI_ARSIZE,
    output  [1:0] M_AXI_ARBURST,
    output  M_AXI_ARLOCK,
    output  [3:0] M_AXI_ARCACHE,
    output  [2:0] M_AXI_ARPROT,
    output  [3:0] M_AXI_ARQOS,
    output  [15:0] M_AXI_ARUSER,
    output reg M_AXI_ARVALID,
    input M_AXI_ARREADY,
    
    // R Channel
    input [3:0] M_AXI_RID,
    input [31:0] M_AXI_RDATA,
    input [1:0] M_AXI_RRESP,
    input M_AXI_RLAST,
    input M_AXI_RVALID,
    output M_AXI_RREADY
);





endmodule
