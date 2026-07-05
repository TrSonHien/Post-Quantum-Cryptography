`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: butterfly_unit
// Description:
//   Forward NTT butterfly unit for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c
//
// C behavior:
//   t = fqmul(zeta, r[j + len]);
//   r[j + len] = r[j] - t;
//   r[j]       = r[j] + t;
//
// RTL behavior:
//   t     = mod_mul(zeta, b_in)
//   a_out = mod_add(a_in, t)
//   b_out = mod_sub(a_in, t)
//
// Datapath convention:
//   All inputs and outputs are canonical unsigned coefficients:
//       0 <= x < KYBER_Q
//
// Notes:
//   - This block is combinational.
//   - Pipeline/registering should be handled later when building ntt_core.
// -----------------------------------------------------------------------------

module butterfly_unit (
    input  wire [`KYBER_Q_WIDTH:0] a_in,
    input  wire [`KYBER_Q_WIDTH:0] b_in,
    input  wire [`KYBER_Q_WIDTH:0] zeta,
    
    output wire [`KYBER_Q_WIDTH:0] a_out,
    output wire [`KYBER_Q_WIDTH:0] b_out
);

    wire [`KYBER_Q_WIDTH-1:0] t;

    // t = fqmul(zeta, b_in)
    // mod_mul must implement:
    //     montgomery_reduce(zeta * b_in)
    // and return canonical unsigned [0, q-1].
    mod_mul u_mod_mul ( .a(zeta), .b(b_in), .c(t) );

    // a_out = a_in + t mod q
    mod_add u_mod_add ( .a(a_in), .b(t), .c(a_out) );

    // b_out = a_in - t mod q
    mod_sub u_mod_sub ( .a(a_in), .b(t), .c(b_out) );

endmodule
