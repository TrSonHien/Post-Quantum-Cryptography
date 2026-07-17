`timescale 1ns / 1ps
/*
 * Module: poly_ntt_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Forward polynomial NTT adapter used by the active polyvec NTT path.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL coefficient domain.
 * Output representation: NTT coefficient domain.
 * Interface: busy/done controller with indexed workspace load/result access.
 * Latency / completion: variable; completion indicated by done.
 * State ownership: delegated to poly_transform_pipe.
 * Submodules: poly_transform_pipe.
 * Verification: active K-PKE roundtrip and M8 release regressions.
 */
module poly_ntt_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire load_begin,
        input wire [1 : 0] load_domain,
        input wire load_we,
        input wire [7 : 0] load_idx,
        input wire [11 : 0] load_coeff,
        output wire load_ready,
        input wire start,
        output wire busy,
        output wire done,
        output wire error,
        input wire result_req,
        input wire [7 : 0] result_idx,
        output wire result_valid,
        output wire [11 : 0] result_coeff,
        output wire [1 : 0] result_domain,
        output wire result_complete,
        input wire result_release,
        input wire zeroize_req,
        output wire zeroize_busy,
        output wire zeroize_done);
    poly_transform_pipe #(.IS_INVERSE(0))
        impl(.*);
endmodule
