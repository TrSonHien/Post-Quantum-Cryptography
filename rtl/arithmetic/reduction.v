`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Reduction helpers for the Kyber / ML-KEM arithmetic datapath.
//
// Reference:
//   ref_model/c_ref/.../Reference_Implementation/crypto_kem/kyber768/reduce.c
//
// These modules intentionally mirror the C reference at the arithmetic level.
// They are not yet optimized for area, timing, or constant-latency pipeline use.
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// montgomery_reduce
//
// C reference:
//   int16_t montgomery_reduce(int32_t a)
//
// Computes a * R^-1 mod q, where R = 2^16. The C function returns a signed
// representative in approximately {-q+1, ..., q-1}. mod_mul wraps this module
// and converts the signed representative into the canonical unsigned RTL range.
// -----------------------------------------------------------------------------
module montgomery_reduce #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire signed [31:0] a,
    output wire signed [15:0] r
);

    localparam signed [31:0] QINV = -32'sd3327;

    wire signed [63:0] a_qinv_full;
    wire signed [15:0] u;
    wire signed [32:0] uq;
    wire signed [32:0] t;
    
    // Therefore only the low 16 bits are kept and interpreted as signed
    assign a_qinv_full = $signed(a) * $signed(QINV);
    assign u           = a_qinv_full[15:0];

    // t = a - (int32_t)u * q
    assign uq = $signed(u) * $signed(Q);
    assign t  = $signed(a) - $signed(uq);

    // arithmetic right shift by 16
    assign r = t >>> 16;

endmodule

// -----------------------------------------------------------------------------
// barrett_reduce
//
// C reference:
//   int16_t barrett_reduce(int16_t a)
//
// This approximates a / q with v = round(2^26 / q), then subtracts t*q.
// The reference function is used in inverse NTT paths after additions. It may
// return q as a valid representative, so a caller that requires strict
// canonical [0, q-1] output should apply a conditional subtract afterward.
// -----------------------------------------------------------------------------
module barrett_reduce #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire signed [31:0] a,
    output wire signed [15:0] r
);

    localparam signed [31:0] V = 32'sd20159;

    wire signed [31:0] a_ext;
    wire signed [31:0] prod;
    wire signed [31:0] t;
    wire signed [31:0] tq;
    wire signed [31:0] r_full;

    // The port is already signed and wide enough for current RTL callers.
    assign a_ext = a;

    // t = (v * a) >> 26
    assign prod =  $signed(V) * $signed(a_ext);
    assign t    =  prod >>> 26;

    // r = a - t * q
    assign tq     = $signed(t) * $signed(Q);
    assign r_full = $signed(a_ext) - $signed(tq);

    assign r = r_full[15:0];

endmodule

// -----------------------------------------------------------------------------
// conditional_sub_q
//
// C reference:
//   int16_t csubq(int16_t a)
//
// Subtracts q once when a >= q. This helper assumes the input is already in a
// range where one subtraction is sufficient, such as [0, 2*q).
// -----------------------------------------------------------------------------
module conditional_sub_q #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire [15:0] a,
    output wire [15:0] r
);

    assign r = (a >= Q) ? (a - Q) : a;

endmodule
