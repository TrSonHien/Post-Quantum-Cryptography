`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_add_pipe
//
// Operation:
//   r = (a + b) mod KYBER_Q
//
// Latency: 1 cycle
// Initiation Interval (II): 1
//
// Constraints:
//   - a, b are unsigned canonical coefficients: 0 <= a,b < q (q = 3329)
//   - Output r is unsigned canonical coefficient: 0 <= r < q
//   - Reset clears out_valid only; payload registers need not reset.
//   - Internal sum width is 13 bits (KYBER_SUM_WIDTH), preserving range 0..6656.
// -----------------------------------------------------------------------------
module mod_add_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg         out_valid,
    output reg  [11:0] r,
    input  wire        zeroize_req,
    output reg         zeroize_busy,
    output reg         zeroize_done
);

    // Sum is up to 3328 + 3328 = 6656, requiring 13 bits.
    wire [12:0] sum;
    wire [12:0] sum_sub;
    wire [11:0] r_next;

    assign sum      = {1'b0, a} + {1'b0, b};
    assign sum_sub  = sum - 13'd3329;
    assign r_next   = (sum >= 13'd3329) ? sum_sub[11:0] : sum[11:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b0;
        end else if (zeroize_req === 1'b1 && !zeroize_busy) begin
            out_valid <= 1'b0;
            r <= 12'd0;
            zeroize_busy <= 1'b1;
            zeroize_done <= 1'b0;
        end else if (zeroize_busy) begin
            out_valid <= 1'b0;
            r <= 12'd0;
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b1;
        end else begin
            out_valid <= in_valid;
            zeroize_done <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (in_valid && !zeroize_busy && zeroize_req !== 1'b1) begin
            r <= r_next;
        end
    end

endmodule
