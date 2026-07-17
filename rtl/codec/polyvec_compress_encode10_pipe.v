`timescale 1ns / 1ps
/*
 * Module: polyvec_compress_encode10_pipe
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
module polyvec_compress_encode10_pipe
    (input wire clk,
     input wire rst_n,
     input wire start,
     input wire [1 : 0] input_domain,
     output wire busy,
     output wire done,
     output wire error,
     input wire in_valid,
     output wire in_ready,
     input wire [11 : 0] in_coeff,
     output wire out_valid,
     input wire out_ready,
     output wire [31 : 0] out_data,
     output wire [3 : 0] out_keep,
     output wire out_last,
     output wire [1 : 0] poly_index,
     input wire zeroize_req,
     output wire zeroize_busy,
     output wire zeroize_done);
    wire x1, x2, x3, x4;
    wire [11 : 0] x5;
    wire [7 : 0] x6;
    wire [1 : 0] x7;
    wire nc;
    polyvec_codec_pipe #(.D(10),
                         .ENCODE(1),
                         .COMPRESS(1))
        u(clk,
          rst_n,
          start,
          input_domain,
          busy,
          done,
          error,
          in_valid,
          in_ready,
          in_coeff,
          1'b0,
          x1,
          32'd0,
          4'd0,
          1'b0,
          out_valid,
          out_ready,
          out_data,
          out_keep,
          out_last,
          x2,
          1'b0,
          x5,
          x6,
          x7,
          poly_index,
          nc,
          zeroize_req,
          zeroize_busy,
          zeroize_done);
endmodule
