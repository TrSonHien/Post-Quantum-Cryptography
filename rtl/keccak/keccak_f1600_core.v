`timescale 1ns / 1ps
/*
 * Module: keccak_f1600_core
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Keccak permutation, sponge, SHA3/SHAKE, or ML-KEM hash wrapper.
 * Standard role: FIPS 202 and FIPS 203 hash support.
 * Input representation: low-byte-first stream or Keccak state lanes.
 * Output representation: hash/XOF stream or updated Keccak state.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: keccak_round.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module keccak_f1600_core
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [1599 : 0] state_in,
        output reg busy,
        output reg done,
        output reg error,
        output reg [1599 : 0] state_out,
        input wire zeroize_req,
        output reg zeroize_done);
    reg [1599 : 0] state_reg;
    reg [4 : 0] round_index;
    wire [1599 : 0] round_result;

    keccak_round u_round(
                         .state_in(state_reg),
                         .round_index(round_index),
                         .state_out(round_result));

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            round_index <= 5'd0;
            state_out <= 1600'h0;
            zeroize_done <= 1'b0;
        end else begin
            done <= 1'b0;
            zeroize_done <= 1'b0;
            if (zeroize_req === 1'b1) begin
                state_reg <= 1600'h0;
                state_out <= 1600'h0;
                round_index <= 5'd0;
                busy <= 1'b0;
                error <= 1'b0;
                zeroize_done <= 1'b1;
            end else begin
                if (start && busy)
                    error <= 1'b1;

                if (!busy) begin
                    if (start) begin
                        state_reg <= state_in;
                        round_index <= 5'd0;
                        busy <= 1'b1;
                    end
                end else begin
                    state_reg <= round_result;
                    if (round_index == 5'd23) begin
                        state_out <= round_result;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        round_index <= round_index + 5'd1;
                    end
                end
            end
        end
    end
endmodule
