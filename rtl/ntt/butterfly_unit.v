`timescale 1ns / 1ps
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
//   - The zeta input is already selected from zetas_rom by the address
//     generator. Forward NTT uses zetas[1..127] in the nested loop.
//   - This module does not know about addresses, memory, or scheduling; it only
//     implements one mathematical butterfly.
// -----------------------------------------------------------------------------
/*
 * Module: butterfly_unit
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

module butterfly_unit
    (
        input wire [`KYBER_Q_WIDTH - 1 : 0] a_in,
        input wire [`KYBER_Q_WIDTH - 1 : 0] b_in,
        input wire [`KYBER_Q_WIDTH - 1 : 0] zeta,

        output wire [`KYBER_Q_WIDTH - 1 : 0] a_out,
        output wire [`KYBER_Q_WIDTH - 1 : 0] b_out);

    wire [`KYBER_Q_WIDTH - 1 : 0] t;

    // t = fqmul(zeta, b_in)
    // mod_mul must implement:
    //     montgomery_reduce(zeta * b_in)
    // and return canonical unsigned [0, q-1].
    mod_mul u_mod_mul(.a(zeta),
                      .b(b_in),
                      .c(t));

    // a_out = a_in + t mod q
    mod_add u_mod_add(.a(a_in),
                      .b(t),
                      .c(a_out));

    // b_out = a_in - t mod q
    mod_sub u_mod_sub(.a(a_in),
                      .b(t),
                      .c(b_out));
endmodule
