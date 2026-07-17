`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Unsigned reduction helpers for Kyber / ML-KEM.
//
// Project convention:
//   - All arithmetic signals are unsigned.
//   - All public coefficient outputs are canonical:
//
//         0 <= coefficient < KYBER_Q
//
//   - No signed declarations.
//   - No $signed casts.
//   - No arithmetic right shifts.
//   - No division or modulo operators in synthesizable datapaths.
//
// Important semantic difference from the C reference:
//   The C implementation may return a centered representative, including
//   negative values. These RTL modules return the equivalent canonical
//   unsigned representative modulo KYBER_Q.
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// montgomery_reduce
//
// Computes:
//
//     r = a * R^-1 mod q
//
// where:
//
//     q = 3329
//     R = 2^16
//
// This implementation uses the fully unsigned Montgomery REDC equation:
//
//     m = (a * q_dash) mod R
//     t = (a + m*q) / R
//     r = (t >= q) ? t - q : t
//
// where:
//
//     q_dash = -q^-1 mod R = 3327
//
// The addition form is used because q_dash is the negative modular inverse.
//
// Supported input range:
//
//     0 <= a < q*R
//
// The current mod_mul caller satisfies the stronger bound:
//
//     a <= (q-1)^2
//
// Under this range, t < 2*q, so one conditional subtraction is sufficient.
//
// Output:
//
//     0 <= r < q
// -----------------------------------------------------------------------------
/*
 * Module: montgomery_reduce
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module montgomery_reduce
    (input wire [31 : 0] a,
     output wire [15 : 0] r);

    localparam [31 : 0] Q = `KYBER_Q;

    // -q^-1 mod 2^16
    //
    // q^-1 mod 2^16  = 62209
    // -p^-1 mod 2^16 = 3327
    localparam [15 : 0] MONT_Q_DASH = 16'd3327;

    // m = low_16_bits(a * MONT_Q_DASH)
    wire [47 : 0] a_qdash_full;
    wire [15 : 0] m;

    // Operands are explicitly zero-extanded to preserve the full product
    assign a_qdash_full = {16'b0, a} * {{32{1'b0}}, MONT_Q_DASH};
    assign m = a_qdash_full[15 : 0];

    // t = (a + m*q) >> 16
    wire [47 : 0] m_q_full;
    wire [32 : 0] sum_full;
    wire [16 : 0] t_raw;

    assign m_q_full = {{32{1'b0}}, m} * {16'b0, Q};

    // For Kyber's valid input range, m*q fits comfortably below bit 32
    assign sum_full = {1'b0, a} + m_q_full[32 : 0];

    // Logical shift is sufficient because the complete datapath is unsigned
    assign t_raw = sum_full[32 : 16];

    // Canonical correction
    wire [16 : 0] t_canonical;

    assign t_canonical = (t_raw >= Q[16 : 0]) ? (t_raw - Q[16 : 0]) : t_raw;
    assign r = t_canonical[15 : 0];
endmodule

// -----------------------------------------------------------------------------
// barrett_reduce
//
// Computes the exact canonical unsigned remainder:
//
//     r = a mod q
//
// without using the Verilog modulo or division operators.
//
// The reciprocal constant is:
//
//     BARRETT_MU = floor(2^48 / q)
//                = 84552411147
//
// Quotient approximation:
//
//     quotient = floor((a * BARRETT_MU) / 2^48)
//
// Because:
//
//     0 <= a < 2^32
//
// and BARRETT_MU is the floor reciprocal at 48-bit precision, quotient is
// either:
//
//     floor(a/q)
//
// or:
//
//     floor(a/q) - 1
//
// Therefore:
//
//     remainder0 = a - quotient*q
//
// is guaranteed to be in:
//
//     0 <= remainder0 < 2*q
//
// One conditional subtraction produces the canonical remainder.
//
// Output:
//
//     0 <= r < q
//
// This implementation supports the full unsigned 32-bit input range.
// -----------------------------------------------------------------------------
/*
 * Module: barrett_reduce
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module barrett_reduce
    (input wire [31 : 0] a,
     output wire [15 : 0] r);

    localparam [31 : 0] Q = `KYBER_Q;

    // floor(2^48 / 3329)
    localparam [36 : 0] BARRETT_MU = 37'd84_552_411_147;

    // quotient = (a * BARRETT_MU) >> 48
    wire [68 : 0] a_mu_full;
    wire [20 : 0] quotient;

    // 32-bit a time 37-bit reciprocal produces a 69-bit result
    // Explicit zero extention avoids accidental expression truncation
    assign a_mu_full = {{37{1'b0}}, a} * {{32{1'b0}}, BARRETT_MU};
    assign quotient = a_mu_full[68 : 48];

    // remainder0 = a - quotient*q
    wire [52 : 0] quotient_q_full;
    wire [52 : 0] a_extended;
    wire [52 : 0] remainder0;

    assign quotient_q_full = {{32{1'b0}}, quotient} * {21'b0, Q};
    assign a_extended = {{21{1'b0}}, a};

    // quotient never exceeds floor(a/q), so this subtraction is non-negative
    assign remainder0 = a_extended - quotient_q_full;

    // Canonical correction
    wire [52 : 0] remainder1;
    assign remainder1 = (remainder0 >= Q) ? (remainder0 - Q) : remainder0;
    assign r = remainder1[15 : 0];
endmodule

// -----------------------------------------------------------------------------
// conditional_sub_q
//
// Applies one unsigned conditional subtraction:
//
//     r = (a >= q) ? a - q : a
//
// Required input range:
//
//     0 <= a < 2*q
//
// Output:
//
//     0 <= r < q
//
// This module is useful when range analysis proves that one subtraction is
// sufficient.
// -----------------------------------------------------------------------------
/*
 * Module: conditional_sub_q
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module conditional_sub_q
    (input wire [15 : 0] a,
     output wire [15 : 0] r);

    localparam [31 : 0] Q = `KYBER_Q;

    assign r = (a >= Q) ? (a - Q) : a;
endmodule
