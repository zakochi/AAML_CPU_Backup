`timescale 1ns / 1ps

module way_32Bx512(
    input clk,
    input cpu_wr,
    input mem_wr,
	input wr_vld,
	input wr_dty,
    input [3:0]mask, 
    input [17:0]tag_i,
    input [8:0]index,
    input [4:0]byte_offset,
    input [31:0]cpu_data_i,
    input [255:0]mem_data_i,
	input vld_i,
	input dty_i,
    
    output [31:0]cpu_data_o,
    output [255:0]mem_data_o,
    output vld_o,
    output dty_o,
    output [17:0]tag_o
);
    
    DistributedRAM #(.DATA_WIDTH(1), .ADDR_WIDTH(9)) vld_arr (
        .a(index), .d(vld_i), .clk(clk), .we(wr_vld), .spo(vld_o)
    );
    
    DistributedRAM #(.DATA_WIDTH(1), .ADDR_WIDTH(9)) dty_arr (
        .a(index), .d(dty_i), .clk(clk), .we(wr_dty), .spo(dty_o)
    );
    
    tag_block18b t_arr (.clk(clk), .write(mem_wr), .index(index), .tag_i(tag_i), .tag_o(tag_o));
    
    data_block32B d_arr (
        .clk(clk), .cpu_wr(cpu_wr), .mem_wr(mem_wr), .mask(mask), 
        .index(index), .byte_offset(byte_offset),
        .cpu_data_i(cpu_data_i), .mem_data_i(mem_data_i), 
        .cpu_data_o(cpu_data_o), .mem_data_o(mem_data_o)
    );
    
endmodule