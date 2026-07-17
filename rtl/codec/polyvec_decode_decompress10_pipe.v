`timescale 1ns / 1ps
/*
 * Module: polyvec_decode_decompress10_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Byte/bit, coefficient, or K-PKE record codec adapter.
 * Standard role: FIPS 203 encoding/decoding support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: polyvec_codec_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module polyvec_decode_decompress10_pipe
    (input wire clk,
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
     output wire [1 : 0] poly_index,
     input wire zeroize_req,
     output wire zeroize_busy,
     output wire zeroize_done);
    wire x1, x2, x3;
    wire [31 : 0] x4;
    wire [3 : 0] x5;
    wire nc;
    polyvec_codec_pipe #(.D(10),
                         .ENCODE(0),
                         .COMPRESS(1))
        u(clk,
          rst_n,
          start,
          2'b01,
          busy,
          done,
          error,
          1'b0,
          x1,
          12'd0,
          in_valid,
          in_ready,
          in_data,
          in_keep,
          in_last,
          x2,
          1'b0,
          x4,
          x5,
          x3,
          out_valid,
          out_ready,
          out_coeff,
          out_index,
          out_domain,
          poly_index,
          nc,
          zeroize_req,
          zeroize_busy,
          zeroize_done);
endmodule
