`timescale 1ns/1ps

// Canonical ordinary modular multiplication: r = a*b mod 3329.
// Latency 4 cycles, II=1. Reset clears validity only.
module mod_mul_normal_pipe(
    input wire clk, input wire rst_n, input wire in_valid,
    input wire [11:0] a, input wire [11:0] b,
    output wire out_valid, output wire [11:0] r
);
    reg valid_s1;
    reg [23:0] product_s1;
    always @(posedge clk) begin
        if (!rst_n) valid_s1 <= 1'b0;
        else valid_s1 <= in_valid;
        if (in_valid) product_s1 <= a * b;
    end
    barrett_reduce_pipe reduce(
        .clk(clk), .rst_n(rst_n), .in_valid(valid_s1),
        .a({8'd0, product_s1}), .out_valid(out_valid), .r(r));
`ifndef SYNTHESIS
    always @(posedge clk) if (rst_n && in_valid && (a >= 3329 || b >= 3329))
        $fatal(1, "MOD_MUL_NORMAL_RANGE a=%0d b=%0d", a, b);
`endif
endmodule
