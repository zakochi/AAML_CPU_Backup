`timescale 1ns / 1ps

module DSP_Multiplier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] multiplicand,
    input  wire [31:0] multiplier,
    input  wire [ 2:0] MUL_DIV_ctrl,

    output reg  [31:0] MUL_out,
    output wire        MUL_done
);

    localparam MUL    = 3'b000;
    localparam MULH   = 3'b001;
    localparam MULHSU = 3'b010;
    localparam MULHU  = 3'b011;

    wire sign_a = multiplicand[31] & (MUL_DIV_ctrl != MULHU);
    wire sign_b = multiplier[31]   & (~MUL_DIV_ctrl[1]);

    wire signed [32:0] op_a = {sign_a, multiplicand};
    wire signed [32:0] op_b = {sign_b, multiplier};

    (* use_dsp = "yes" *)
    wire signed [65:0] mult_result = op_a * op_b;

    wire is_high_word = (MUL_DIV_ctrl != MUL);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            MUL_out  <= 32'b0;
        end
        else begin
            MUL_out <= is_high_word ? mult_result[63:32] : mult_result[31:0];
        end
    end
    
    assign MUL_done = start;
endmodule