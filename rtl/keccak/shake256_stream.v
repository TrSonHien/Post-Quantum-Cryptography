/*
 * Module: shake256_stream
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Keccak permutation, sponge, SHA3/SHAKE, or ML-KEM hash wrapper.
 * Standard role: FIPS 202 and FIPS 203 hash support.
 * Input representation: low-byte-first stream or Keccak state lanes.
 * Output representation: hash/XOF stream or updated Keccak state.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: keccak_hash_stream.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module shake256_stream
    (input wire clk,
     input wire rst_n,
     input wire cmd_valid,
     output wire cmd_ready,
     input wire [31 : 0] msg_len_bytes,
     input wire [31 : 0] out_len_bytes,
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
     output wire busy,
     output wire done,
     output wire error,
     input wire zeroize_req,
     output wire zeroize_done);
    keccak_hash_stream u(.clk(clk),
                         .rst_n(rst_n),
                         .cmd_valid(cmd_valid),
                         .cmd_ready(cmd_ready),
                         .mode(2'd3),
                         .msg_len_bytes(msg_len_bytes),
                         .out_len_bytes(out_len_bytes),
                         .in_valid(in_valid),
                         .in_ready(in_ready),
                         .in_data(in_data),
                         .in_keep(in_keep),
                         .in_last(in_last),
                         .out_valid(out_valid),
                         .out_ready(out_ready),
                         .out_data(out_data),
                         .out_keep(out_keep),
                         .out_last(out_last),
                         .busy(busy),
                         .done(done),
                         .error(error),
                         .zeroize_req(zeroize_req),
                         .zeroize_done(zeroize_done));
endmodule
