`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_sub_pipe
//
// Operation:
//   r = (a - b) mod KYBER_Q
//
// Latency: 1 cycle
// Initiation Interval (II): 1
//
// Constraints:
//   - a, b are unsigned canonical coefficients: 0 <= a,b < q (q = 3329)
//   - Output r is unsigned canonical coefficient: 0 <= r < q
//   - Reset clears out_valid only; payload registers need not reset.
//   - No signed arithmetic or signed signals.
// -----------------------------------------------------------------------------
module mod_sub_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg         out_valid,
    output reg  [11:0] r
);

    wire [12:0] diff_wrapped;
    wire [11:0] r_next;

    // To avoid underflow, we conditionally add KYBER_Q.
    // Since a, b are canonical, a + KYBER_Q >= b is guaranteed if a < b.
    assign diff_wrapped = {1'b0, a} + 13'd3329 - {1'b0, b};
    assign r_next       = (a >= b) ? (a - b) : diff_wrapped[11:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;
        end
    end

    always @(posedge clk) begin
        if (in_valid) begin
            r <= r_next;
        end
    end

endmodule
