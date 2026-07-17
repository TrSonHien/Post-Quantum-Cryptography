`timescale 1ns / 1ps
/*
 * Module: polyvec_sub_pipe
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: polyvec_elementwise_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module polyvec_sub_pipe
    (input wire clk, rst_n, load_begin, load_operand,
     input wire [1 : 0] load_poly_idx, load_domain,
     input wire load_we,
     input wire [7 : 0] load_idx,
     input wire [11 : 0] load_coeff,
     output wire load_ready,
     input wire start,
     output wire busy, done, error,
     input wire result_req,
     input wire [1 : 0] result_poly_idx,
     input wire [7 : 0] result_idx,
     output wire result_valid,
     output wire [11 : 0] result_coeff,
     output wire [1 : 0] result_domain,
     output wire result_complete,
     input wire result_release,
     input wire zeroize_req,
     output wire zeroize_busy,
     output wire zeroize_done);
    polyvec_elementwise_pipe #(.OP(1))
        u(.*);
endmodule
