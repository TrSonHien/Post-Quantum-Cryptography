`timescale 1ns / 1ps

// FIPS 203 Algorithm 4. out_bits[j] is bit j of the accepted byte.
/*
 * Module: bytes_to_bits_pipe
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Byte/bit, coefficient, or K-PKE record codec adapter.
 * Standard role: FIPS 203 encoding/decoding support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module bytes_to_bits_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire in_valid,
        output wire in_ready,
        input wire [7 : 0] in_byte,
        output reg out_valid,
        input wire out_ready,
        output reg [7 : 0] out_bits,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    wire zeroize_active = zeroize_busy || (zeroize_req === 1'b1);
    assign in_ready = !zeroize_active && (!out_valid || out_ready);
    always @(posedge clk) begin
        zeroize_done <= 1'b0;
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_bits <= 8'd0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            out_valid <= 0;
            out_bits <= 0;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            out_valid <= 0;
            out_bits <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 1;
        end else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid)
                out_bits <= in_byte;
        end
    end
endmodule
