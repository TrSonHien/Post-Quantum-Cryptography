`timescale 1ns / 1ps
// Common ByteDecode_D followed by exact power-of-two decompression.
/*
 * Module: poly_decode_decompress_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Byte/bit, coefficient, or K-PKE record codec adapter.
 * Standard role: FIPS 203 encoding/decoding support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: byte_decode_poly_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module poly_decode_decompress_pipe
    #(parameter integer D = 10)
    (
        input wire clk,
        input wire rst_n,
        input wire start,
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
        input wire zeroize_req,
        output wire zeroize_busy,
        output wire zeroize_done);
    wire [11 : 0] raw;
    wire nc;
    byte_decode_poly_pipe #(.D(D))
        u(clk,
          rst_n,
          start,
          busy,
          done,
          error,
          in_valid,
          in_ready,
          in_data,
          in_keep,
          in_last,
          out_valid,
          out_ready,
          raw,
          out_index,
          nc,
          zeroize_req,
          zeroize_busy,
          zeroize_done);
    assign out_coeff = (raw * 3329 + (1 << (D - 1))) >> D;
    assign out_domain = 2'b01;
endmodule
