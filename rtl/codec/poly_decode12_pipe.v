`timescale 1ns / 1ps
/*
 * Module: poly_decode12_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: 12-bit polynomial decoder selected by active K-PKE public-key codecs.
 * Standard role: FIPS 203 decoding support.
 * Input representation: LSB-first 12-bit coefficient byte stream.
 * Output representation: canonical coefficients in expected_domain.
 * Interface: valid/ready stream with busy/done completion.
 * Latency / completion: variable; completion indicated by done.
 * State ownership: delegated to byte_decode_poly_pipe.
 * Submodules: byte_decode_poly_pipe.
 * Verification: active K-PKE roundtrip and M8 release regressions.
 */
module poly_decode12_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [1 : 0] expected_domain,
        output wire busy,
        output wire done,
        output wire error,
        input wire in_valid,
        output wire in_ready,
        input wire [31 : 0] in_data,
        input wire [3 : 0] in_keep,
        input wire in_last,
        output wire out_valid,
        input wire out_ready,
        output wire [11 : 0] out_coeff,
        output wire [7 : 0] out_index,
        output wire [1 : 0] out_domain,
        output wire noncanonical_seen,
        input wire zeroize_req,
        output wire zeroize_busy,
        output wire zeroize_done);
    wire child_error;
    byte_decode_poly_pipe #(.D(12))
        u(clk,
          rst_n,
          start,
          busy,
          done,
          child_error,
          in_valid,
          in_ready,
          in_data,
          in_keep,
          in_last,
          out_valid,
          out_ready,
          out_coeff,
          out_index,
          noncanonical_seen,
          zeroize_req,
          zeroize_busy,
          zeroize_done);
    assign out_domain = expected_domain;
    assign error = !zeroize_busy && !(zeroize_req === 1'b1) && (child_error | (start && !((expected_domain == 2'b01) || (expected_domain == 2'b10))));
endmodule
