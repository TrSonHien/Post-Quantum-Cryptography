`timescale 1ns/1ps
module butterfly_unit_wrap (
    input  wire        clk,
    input  wire [11:0] a_in,
    input  wire [11:0] b_in,
    input  wire [11:0] zeta,
    output reg  [11:0] a_out,
    output reg  [11:0] b_out
);
    reg [11:0] a_in_reg;
    reg [11:0] b_in_reg;
    reg [11:0] zeta_reg;
    wire [11:0] a_out_wire;
    wire [11:0] b_out_wire;

    butterfly_unit inst (
        .a_in(a_in_reg),
        .b_in(b_in_reg),
        .zeta(zeta_reg),
        .a_out(a_out_wire),
        .b_out(b_out_wire)
    );

    always @(posedge clk) begin
        a_in_reg <= a_in;
        b_in_reg <= b_in;
        zeta_reg <= zeta;
        a_out    <= a_out_wire;
        b_out    <= b_out_wire;
    end
endmodule
