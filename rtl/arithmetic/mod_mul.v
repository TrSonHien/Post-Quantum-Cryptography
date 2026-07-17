`timescale 1ns / 1ps
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
//   - montgomery_reduce returns a canonical unsigned result.
//   - The output is therefore canonical: 0 <= c < q.
//
// Note:
//   This is a clear first RTL implementation for verification. A later
//   timing/PPA pass may replace the 32-bit multiply and reduction datapath with
//   a pipelined or resource-shared architecture.
// -----------------------------------------------------------------------------
/*
 * Module: mod_mul
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: montgomery_reduce.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mod_mul
    (input wire [`KYBER_Q_WIDTH - 1 : 0] a,
     input wire [`KYBER_Q_WIDTH - 1 : 0] b,
     output wire [`KYBER_Q_WIDTH - 1 : 0] c);

    wire [23 : 0] product;
    wire [31 : 0] product_extended;
    wire [15 : 0] mont_result;

    // a and b are unsigned canonical coefficients.
    // Product is positive and fits easily in 32 bits.

    assign product = a * b;
    assign product_extended = {{8{1'b0}}, product};

    montgomery_reduce u_montgomery_reduce(.a(product_extended),
                                          .r(mont_result));

    assign c = mont_result[`KYBER_Q_WIDTH - 1 : 0];
endmodule
