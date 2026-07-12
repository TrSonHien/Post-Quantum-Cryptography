`timescale 1ns/1ps
module montgomery_reduce_wrap (
    input  wire        clk,
    input  wire [31:0] a,
    output reg  [11:0] r
);
    reg [31:0] a_reg;
    wire [15:0] r_wire;

    montgomery_reduce inst (
        .a(a_reg),
        .r(r_wire)
    );

    always @(posedge clk) begin
        a_reg <= a;
        r     <= r_wire[11:0];
    end
endmodule
