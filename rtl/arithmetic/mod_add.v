`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_add
//
// Operation:
//   c = (a + b) mod KYBER_Q
//
// Reference:
//   - Kyber parameter q = 3329 from kyber768/params.h.
//   - This is the unsigned canonical form used by the RTL datapath:
//       0 <= a,b,c < q
//
// Width notes:
//   - The largest input sum is 3328 + 3328 = 6656.
//   - KYBER_SUM_WIDTH is 13 bits, enough to hold that value.
//   - Because the inputs are already canonical, at most one subtract-q is
//     needed after the addition.
// -----------------------------------------------------------------------------
module mod_add (
    input  wire [`KYBER_Q_WIDTH-1:0] a,
    input  wire [`KYBER_Q_WIDTH-1:0] b,
    output wire [`KYBER_Q_WIDTH-1:0] c
);

    wire [`KYBER_SUM_WIDTH-1:0] sum;
    wire [`KYBER_SUM_WIDTH-1:0] reduced_sum;

    assign sum = {1'b0, a} + {1'b0, b};
    assign reduced_sum = (sum >= `KYBER_Q) ? (sum - `KYBER_Q) : sum;
    assign c = reduced_sum[`KYBER_Q_WIDTH-1:0];

endmodule
