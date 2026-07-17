`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_sub
//
// Operation:
//   c = (a - b) mod KYBER_Q
//
// Reference:
//   - Kyber parameter q = 3329 from kyber768/params.h.
//   - This block uses the RTL datapath convention:
//       0 <= a,b,c < q
//
// Width notes:
//   - A 13-bit subtraction is used so the MSB of diff indicates underflow.
//   - If underflow occurs, adding q and taking the low coefficient bits gives
//     the canonical result. This relies on normal fixed-width Verilog wrapping.
// -----------------------------------------------------------------------------
/*
 * Module: mod_sub
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mod_sub
    (input wire [`KYBER_Q_WIDTH - 1 : 0] a,
     input wire [`KYBER_Q_WIDTH - 1 : 0] b,
     output wire [`KYBER_Q_WIDTH - 1 : 0] c);

    wire [`KYBER_SUM_WIDTH - 1 : 0] diff;
    wire [`KYBER_SUM_WIDTH - 1 : 0] adjusted_diff;

    assign diff = {1'b0, a} - {1'b0, b};
    assign adjusted_diff = diff[`KYBER_SUM_WIDTH - 1] ? (diff + `KYBER_Q) : diff;

    assign c = adjusted_diff[`KYBER_Q_WIDTH - 1 : 0];
endmodule
