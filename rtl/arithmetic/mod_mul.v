`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_mul
//
// Operation:
//   c = montgomery_reduce(a * b), returned as an unsigned canonical coefficient.
//
// Reference:
//   - kyber768/reduce.c: montgomery_reduce()
//   - kyber768/ntt.c: fqmul()
//
// Datapath convention:
//   - Inputs are canonical unsigned Kyber coefficients: 0 <= a,b < q.
//   - montgomery_reduce returns a signed representative roughly in
//     {-q+1, ..., q-1}; this wrapper converts negative results by adding q.
//   - The output is therefore canonical: 0 <= c < q.
//
// Note:
//   This is a clear first RTL implementation for verification. A later
//   timing/PPA pass may replace the 32-bit multiply and reduction datapath with
//   a pipelined or resource-shared architecture.
// -----------------------------------------------------------------------------
module mod_mul #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire [`KYBER_Q_WIDTH-1:0] a,
    input  wire [`KYBER_Q_WIDTH-1:0] b,
    output wire [`KYBER_Q_WIDTH-1:0] c
);

    wire signed [31:0] product;
    wire signed [15:0] mont_result;

    wire signed [16:0] mont_ext;
    wire signed [16:0] canonical;

    // a and b are unsigned canonical coefficients.
    // Product is positive and fits easily in 32 bits.

    assign product = $signed({20'd0, a}) * $signed({20'd0, b});
    
    montgomery_reduce #(.Q(Q)) u_montgomery_reduce ( .a(product), .r(mont_result) );
    
    // montgomery_reduce returns a signed value roughly in:
    //     {-q+1, ..., q-1}
    //
    // Convert it to canonical unsigned:
    //     if negative, add q
    assign mont_ext  = {mont_result[15], mont_result};
    assign canonical = (mont_ext < 0) ? (mont_ext + Q) : mont_ext;
    assign c         = canonical[`KYBER_Q_WIDTH-1:0];

endmodule
