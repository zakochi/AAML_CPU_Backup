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
    output [31:0] NPU_out,
    input        NPU_start,
    output reg   NPU_done,
    output reg   NPU_exception,
    input [2:0]  funct3_i,
    input [6:0] funct7_i,

    // AXI4 Master Interface (M_AXI) //
    // AW Channel
    //output  [3:0] M_AXI_AWID,
    output [31:0] M_AXI_AWADDR,
    output  [7:0] M_AXI_AWLEN,
    output  [2:0] M_AXI_AWSIZE,
    output  [1:0] M_AXI_AWBURST,
    output  M_AXI_AWLOCK,
    output  [3:0] M_AXI_AWCACHE,
    output  [2:0] M_AXI_AWPROT,
    output  [3:0] M_AXI_AWQOS,
    output  [15:0] M_AXI_AWUSER,
    output M_AXI_AWVALID,
    input M_AXI_AWREADY,
    // W Channel
    output [31:0] M_AXI_WDATA,
    output  [3:0] M_AXI_WSTRB,
    output M_AXI_WLAST,
    output M_AXI_WVALID,
    input M_AXI_WREADY,
    
    // B Channel
    //input [3:0] M_AXI_BID,
    input [1:0] M_AXI_BRESP,
    //input [15:0] M_AXI_BUSER,
    input M_AXI_BVALID,
    output  M_AXI_BREADY,
    
    // AR Channel
    //output  [3:0] M_AXI_ARID,
    output [31:0] M_AXI_ARADDR,
    output  [7:0] M_AXI_ARLEN,
    output  [2:0] M_AXI_ARSIZE,
    output  [1:0] M_AXI_ARBURST,
    output  M_AXI_ARLOCK,
    output  [3:0] M_AXI_ARCACHE,
    output  [2:0] M_AXI_ARPROT,
    output  [3:0] M_AXI_ARQOS,
    output  [15:0] M_AXI_ARUSER,
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
	assign M_AXI_AWLEN   = 8'h00;     
    assign M_AXI_AWSIZE  = 3'b010;    
    assign M_AXI_AWBURST = 2'b01;     
    assign M_AXI_AWLOCK  = 1'b0;
    assign M_AXI_AWCACHE = 4'b0011;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWQOS   = 4'b0000;
    assign M_AXI_AWUSER  = 16'h0000;
    assign M_AXI_WSTRB   = 4'b1111;    
    assign M_AXI_BREADY  = 1'b1;      

    assign M_AXI_ARLEN   = 8'h00;
    assign M_AXI_ARSIZE  = 3'b010;
    assign M_AXI_ARBURST = 2'b01;
    assign M_AXI_ARLOCK  = 1'b0;
    assign M_AXI_ARCACHE = 4'b0011;
    assign M_AXI_ARPROT  = 3'b000;
    assign M_AXI_ARQOS   = 4'b0000;
    assign M_AXI_ARUSER  = 16'h0000;
    assign M_AXI_RREADY  = 1'b1;      

	assign M_AXI_ARADDR  = 32'd0;
	assign M_AXI_ARVALID = 1'b0;
	assign M_AXI_AWADDR  = 32'd0;
	assign M_AXI_AWVALID = 1'b0;
	assign M_AXI_WDATA   = 32'd0;
	assign M_AXI_WVALID  = 1'b0;
	assign M_AXI_WLAST   = 1'b0;
		 
    localparam STATE_IDLE  = 3'd0;
    localparam STATE_COMP  = 3'd1;
    localparam STATE_AR    = 3'd2;
    localparam STATE_R     = 3'd3;
    localparam STATE_AW_W  = 3'd4;
    localparam STATE_B     = 3'd5;
    localparam STATE_DONE  = 3'd6;


	localparam clear_out = 2;
	localparam acc_out = 3;
	localparam set_iofs = 1;
	localparam set_fofs = 4;
	reg signed [15:0] InputOffset, FilterOffset;
    // SIMD multiply step:
    wire signed [15:0] prod_0, prod_1, prod_2, prod_3;
	reg signed   [31:0]   new_sum_prods;

    assign prod_0 = ($signed(rs1_i[7:0])+ InputOffset) * ($signed(rs2_i[7:0])+FilterOffset);
    assign prod_1 = ($signed(rs1_i[15:8])+ InputOffset) * ($signed(rs2_i[15:8])+FilterOffset);
    assign prod_2 = ($signed(rs1_i[23:16])+ InputOffset) * ($signed(rs2_i[23:16])+FilterOffset);
    assign prod_3 = ($signed(rs1_i[31:24])+ InputOffset) * ($signed(rs2_i[31:24])+FilterOffset);
	
	wire signed [31:0] sum_prods;
    assign sum_prods = prod_0 + prod_1 + prod_2 + prod_3;
	
	always@(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			NPU_done <= 0;
			NPU_exception <= 0;
			new_sum_prods <= 0;
		end
		else begin
			if(NPU_start)begin
				NPU_done <= 1;
				if(funct3_i == set_iofs)
					InputOffset <= rs1_i;
				else if(funct3_i == acc_out)
					new_sum_prods <= new_sum_prods + sum_prods;
				else if(funct3_i == clear_out)
					new_sum_prods<= 0;
				else if(funct3_i == set_fofs)
					FilterOffset <= rs1_i;
			end
			else
				NPU_done <= 0;
		end
	end
	assign NPU_out = new_sum_prods;
	
endmodule
