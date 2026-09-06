module MUL_DIV_top (
    input clk,
    input rst_n,

    input [31:0] data1,
    input [31:0] data2,

    input MUL_DIV_start,
    input [2:0] MUL_DIV_ctrl,
    output [31:0] MUL_out,
    output [31:0] DIV_out,
    output MUL_DIV_done 
);

    wire is_MUL = ~MUL_DIV_ctrl[2];
    wire is_DIV =  MUL_DIV_ctrl[2];
    wire MUL_done, DIV_done;

    assign MUL_DIV_done = MUL_done | DIV_done;
    
    DSP_Multiplier m_DSP_Multiplier(
        .clk(clk),
        .rst_n(rst_n),
        .start(MUL_DIV_start & is_MUL), 
        .multiplicand(data1), 
        .multiplier(data2),
        .MUL_DIV_ctrl(MUL_DIV_ctrl),
        .MUL_out(MUL_out),
        .MUL_done(MUL_done)
    );

    SRTDivider m_SRTDivider(
        .clk(clk),
        .rst_n(rst_n),
        .start(MUL_DIV_start & is_DIV),
        .remainder(data1), 
        .divisor(data2),
        .MUL_DIV_ctrl(MUL_DIV_ctrl),
        .DIV_out(DIV_out),
        .DIV_done(DIV_done)
    );

endmodule