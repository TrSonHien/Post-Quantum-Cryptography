`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: intt_butterfly_unit
// Description:
//   Inverse NTT butterfly unit for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c
//
// C behavior:
//
//   t = r[j];
//   r[j] = barrett_reduce(t + r[j + len]);
//   r[j + len] = t - r[j + len];
//   r[j + len] = fqmul(zeta, r[j + len]);
//
// RTL behavior with canonical unsigned datapath:
//
//   sum  = mod_add(a_in, b_in)
//   diff = mod_sub(a_in, b_in)
//   mul  = mod_mul(zeta, diff)
//
//   a_out = sum
//   b_out = mul
//
// Datapath convention:
//   All inputs and outputs are canonical unsigned coefficients:
//       0 <= x < KYBER_Q
//
// Notes:
//   - This block is combinational.
//   - Final INTT scaling by zetas_inv[127] is NOT done here.
//   - Final scaling belongs in intt_core.v.
//   - This unit has only been syntax/elaboration checked in the current tree;
//     add a dedicated self-checking testbench before relying on it as verified.
// -----------------------------------------------------------------------------
/*
 * Module: intt_butterfly_unit
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: NTT/INTT arithmetic leaf, scheduler, ROM, or transform controller.
 * Standard role: FIPS 203 Algorithms 9--12 support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: mod_add, mod_mul, mod_sub.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module intt_butterfly_unit
    (
        input wire [`KYBER_Q_WIDTH - 1 : 0] a_in,
        input wire [`KYBER_Q_WIDTH - 1 : 0] b_in,
        input wire [`KYBER_Q_WIDTH - 1 : 0] zeta,

        output wire [`KYBER_Q_WIDTH - 1 : 0] a_out,
        output wire [`KYBER_Q_WIDTH - 1 : 0] b_out);

    wire [`KYBER_Q_WIDTH - 1 : 0] diff;

    mod_add u_mod_add(.a(a_in),
                      .b(b_in),
                      .c(a_out));
    mod_sub u_mod_sub(.a(a_in),
                      .b(b_in),
                      .c(diff));
    mod_mul u_mod_mul(.a(zeta),
                      .b(diff),
                      .c(b_out));
endmodule
