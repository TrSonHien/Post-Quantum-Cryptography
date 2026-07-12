`timescale 1ns/1ps
module mod_mul_wrap (
    input  wire        clk,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg  [11:0] c
);
    reg [11:0] a_reg;
    reg [11:0] b_reg;
    wire [11:0] c_wire;

    mod_mul inst (
        .a(a_reg),
        .b(b_reg),
        .c(c_wire)
    );

    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
        c     <= c_wire;
    end
endmodule
