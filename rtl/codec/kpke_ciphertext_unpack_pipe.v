`timescale 1ns / 1ps
/*
 * Module: kpke_ciphertext_unpack_pipe
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Byte/bit, coefficient, or K-PKE record codec adapter.
 * Standard role: FIPS 203 encoding/decoding support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: kpke_format_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module kpke_ciphertext_unpack_pipe
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
     output wire [31 : 0] out_data,
     output wire [3 : 0] out_keep,
     output wire out_last,
     output wire c2_segment,
     input wire zeroize_req,
     output wire zeroize_busy,
     output wire zeroize_done);
    kpke_format_pipe #(.WORDS(272),
                       .SPLIT_WORDS(240))
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
          out_data,
          out_keep,
          out_last,
          c2_segment,
          zeroize_req,
          zeroize_busy,
          zeroize_done);
endmodule
