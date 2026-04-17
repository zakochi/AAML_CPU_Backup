`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/02 22:47:02
// Design Name: 
// Module Name: riscv_rstn_gen
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


module riscv_rstn_gen(
    input clk,
    input mb_rst,
    output reg riscv_rst_n 
);
    reg delay_element;
    always@(posedge clk or posedge mb_rst)begin
        if(mb_rst)begin
            riscv_rst_n <= 0;
            delay_element <= 0;
        end
        else begin
            delay_element <= 1;
            riscv_rst_n <= delay_element;
        end
    end
endmodule
