`timescale 1ns/1ps
module mod_add_wrap (
    input  wire        clk,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg  [11:0] r
);
    reg [11:0] a_reg;
    reg [11:0] b_reg;
    wire [11:0] r_wire;

    mod_add inst (
        .a(a_reg),
        .b(b_reg),
        .c(r_wire)
    );

    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
        r     <= r_wire;
    end
endmodule
