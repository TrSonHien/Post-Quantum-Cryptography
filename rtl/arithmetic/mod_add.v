`timescale 1ns / 1ps
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
/*
 * Module: mod_add
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
module mod_add
    (input wire [`KYBER_Q_WIDTH - 1 : 0] a,
     input wire [`KYBER_Q_WIDTH - 1 : 0] b,
     output wire [`KYBER_Q_WIDTH - 1 : 0] c);

    wire [`KYBER_SUM_WIDTH - 1 : 0] sum;
    wire [`KYBER_SUM_WIDTH - 1 : 0] reduced_sum;

    assign sum = {1'b0, a} + {1'b0, b};
    assign reduced_sum = (sum >= `KYBER_Q) ? (sum - `KYBER_Q) : sum;
    assign c = reduced_sum[`KYBER_Q_WIDTH - 1 : 0];
endmodule
