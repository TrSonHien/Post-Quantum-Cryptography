`timescale 1ns / 1ps
`include "kyber_params.vh"
/*
 * Module: poly_reduce
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module poly_reduce
    ();
endmodule
