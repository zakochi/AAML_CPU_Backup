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


module NPU (
    input clk,
    input rst_n,

    // CPU Interface //
    input      [31:0] rs1_i,
    input      [31:0] rs2_i,
    output     [31:0] NPU_out,
    input             NPU_start,
    output reg        NPU_done,
    output reg        NPU_exception,
    input      [ 2:0] funct3_i,
    input      [ 6:0] funct7_i,

    // AXI4 Master Interface (M_AXI) //
    // AW Channel
    //output  [3:0] M_AXI_AWID,
    output [31:0] M_AXI_AWADDR,
    output [7:0] M_AXI_AWLEN,
    output [2:0] M_AXI_AWSIZE,
    output [1:0] M_AXI_AWBURST,
    output M_AXI_AWLOCK,
    output [3:0] M_AXI_AWCACHE,
    output [2:0] M_AXI_AWPROT,
    output [3:0] M_AXI_AWQOS,
    output [15:0] M_AXI_AWUSER,
    output M_AXI_AWVALID,
    input M_AXI_AWREADY,
    // W Channel
    output [31:0] M_AXI_WDATA,
    output [3:0] M_AXI_WSTRB,
    output M_AXI_WLAST,
    output M_AXI_WVALID,
    input M_AXI_WREADY,

    // B Channel
    //input [3:0] M_AXI_BID,
    input [1:0] M_AXI_BRESP,
    //input [15:0] M_AXI_BUSER,
    input M_AXI_BVALID,
    output M_AXI_BREADY,

    // AR Channel
    //output  [3:0] M_AXI_ARID,
    output [31:0] M_AXI_ARADDR,
    output [7:0] M_AXI_ARLEN,
    output [2:0] M_AXI_ARSIZE,
    output [1:0] M_AXI_ARBURST,
    output M_AXI_ARLOCK,
    output [3:0] M_AXI_ARCACHE,
    output [2:0] M_AXI_ARPROT,
    output [3:0] M_AXI_ARQOS,
    output [15:0] M_AXI_ARUSER,
    output M_AXI_ARVALID,
    input M_AXI_ARREADY,

    // R Channel
    input [3:0] M_AXI_RID,
    input [31:0] M_AXI_RDATA,
    input [1:0] M_AXI_RRESP,
    input M_AXI_RLAST,
    input M_AXI_RVALID,
    output M_AXI_RREADY
);

    // Implement your own NPU here

    assign M_AXI_AWADDR  = 32'd0;
    assign M_AXI_AWLEN   = 8'd0;
    assign M_AXI_AWSIZE  = 3'd0;
    assign M_AXI_AWBURST = 2'd0;
    assign M_AXI_AWLOCK  = 1'b0;
    assign M_AXI_AWCACHE = 4'd0;
    assign M_AXI_AWPROT  = 3'd0;
    assign M_AXI_AWQOS   = 4'd0;
    assign M_AXI_AWUSER  = 16'd0;
    assign M_AXI_AWVALID = 1'b0;

    assign M_AXI_WDATA   = 32'd0;
    assign M_AXI_WSTRB   = 4'd0;
    assign M_AXI_WLAST   = 1'b0;
    assign M_AXI_WVALID  = 1'b0;

    assign M_AXI_BREADY  = 1'b0;

    assign M_AXI_ARADDR  = 32'd0;
    assign M_AXI_ARLEN   = 8'd0;
    assign M_AXI_ARSIZE  = 3'd0;
    assign M_AXI_ARBURST = 2'd0;
    assign M_AXI_ARLOCK  = 1'b0;
    assign M_AXI_ARCACHE = 4'd0;
    assign M_AXI_ARPROT  = 3'd0;
    assign M_AXI_ARQOS   = 4'd0;
    assign M_AXI_ARUSER  = 16'd0;
    assign M_AXI_ARVALID = 1'b0;

    assign M_AXI_RREADY  = 1'b0;

    // You can change the following always block to implement your own NPU
    // Do not add or remove any input or output ports, and do not change the name of this module

    // always@(posedge clk, negedge rst_n)begin
    // 	if(!rst_n)begin
    // 		NPU_done <= 0;
    // 		NPU_exception <= 0;
    // 	end
    // 	else begin
    //         // Example 
    // 		// if(NPU_start)begin
    // 		// 	NPU_done <= 1;
    // 		// 	if(funct3_i == your own local param 1)
    // 		// 		do something
    // 		// 	else if(funct3_i == your own local param 2)
    // 		// 		do something
    //         //  ...
    // 		// end
    // 	end
    // end


    // Change the following below as well, this is just an example
    assign NPU_out       = 32'd0;

    always @(*) begin
        NPU_done = NPU_start;
        NPU_exception = 1'b0;
    end

endmodule
