`timescale 1ns / 1ps

// Compute-only custom accelerator template.
// The port names match the current NPU.v example so the software CUSTOM-0 path
// can remain unchanged while the implementation is replaced.
module CustomAcceleratorTemplate(
    input clk,
    input rst_n,

    input [31:0] rs1_i,
    input [31:0] rs2_i,
    output reg [31:0] NPU_out,
    input        NPU_start,
    output reg   NPU_done,
    output reg   NPU_exception,
    input [3:0]  funct3_i,
    input [31:0] funct7_i,

    output reg [31:0] M_AXI_AWADDR,
    output [7:0] M_AXI_AWLEN,
    output [2:0] M_AXI_AWSIZE,
    output [1:0] M_AXI_AWBURST,
    output M_AXI_AWLOCK,
    output [3:0] M_AXI_AWCACHE,
    output [2:0] M_AXI_AWPROT,
    output [3:0] M_AXI_AWQOS,
    output [15:0] M_AXI_AWUSER,
    output reg M_AXI_AWVALID,
    input M_AXI_AWREADY,

    output reg [31:0] M_AXI_WDATA,
    output [3:0] M_AXI_WSTRB,
    output reg M_AXI_WLAST,
    output reg M_AXI_WVALID,
    input M_AXI_WREADY,

    input [1:0] M_AXI_BRESP,
    input M_AXI_BVALID,
    output M_AXI_BREADY,

    output reg [31:0] M_AXI_ARADDR,
    output [7:0] M_AXI_ARLEN,
    output [2:0] M_AXI_ARSIZE,
    output [1:0] M_AXI_ARBURST,
    output M_AXI_ARLOCK,
    output [3:0] M_AXI_ARCACHE,
    output [2:0] M_AXI_ARPROT,
    output [3:0] M_AXI_ARQOS,
    output [15:0] M_AXI_ARUSER,
    output reg M_AXI_ARVALID,
    input M_AXI_ARREADY,

    input [3:0] M_AXI_RID,
    input [31:0] M_AXI_RDATA,
    input [1:0] M_AXI_RRESP,
    input M_AXI_RLAST,
    input M_AXI_RVALID,
    output M_AXI_RREADY
);
    localparam FUNCT3_COMPUTE = 3'd0;
    localparam FUNCT7_ADD     = 7'd0;
    localparam FUNCT7_XOR     = 7'd1;

    localparam STATE_IDLE = 1'd0;
    localparam STATE_DONE = 1'd1;

    reg state_r;

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r       <= STATE_IDLE;
            NPU_out       <= 32'd0;
            NPU_done      <= 1'b0;
            NPU_exception <= 1'b0;
            M_AXI_AWADDR  <= 32'd0;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_WDATA   <= 32'd0;
            M_AXI_WLAST   <= 1'b0;
            M_AXI_WVALID  <= 1'b0;
            M_AXI_ARADDR  <= 32'd0;
            M_AXI_ARVALID <= 1'b0;
        end else begin
            NPU_done      <= 1'b0;
            NPU_exception <= 1'b0;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_WLAST   <= 1'b0;
            M_AXI_WVALID  <= 1'b0;
            M_AXI_ARVALID <= 1'b0;

            case (state_r)
                STATE_IDLE: begin
                    if (NPU_start) begin
                        if (funct3_i[2:0] == FUNCT3_COMPUTE) begin
                            case (funct7_i[6:0])
                                FUNCT7_ADD: NPU_out <= rs1_i + rs2_i;
                                FUNCT7_XOR: NPU_out <= rs1_i ^ rs2_i;
                                default: begin
                                    NPU_out       <= 32'd0;
                                    NPU_exception <= 1'b1;
                                end
                            endcase
                        end else begin
                            NPU_out       <= 32'd0;
                            NPU_exception <= 1'b1;
                        end

                        state_r <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    NPU_done <= 1'b1;
                    state_r  <= STATE_IDLE;
                end
            endcase
        end
    end

    wire unused_axi_inputs = &{
        1'b0,
        M_AXI_AWREADY,
        M_AXI_WREADY,
        M_AXI_BRESP,
        M_AXI_BVALID,
        M_AXI_ARREADY,
        M_AXI_RID,
        M_AXI_RDATA,
        M_AXI_RRESP,
        M_AXI_RLAST,
        M_AXI_RVALID
    };
endmodule
