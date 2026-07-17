`timescale 1ns / 1ps
// Public Decaps length and stored H(embedded ek) check. No modulus check here.
/*
 * Module: mlkem_decaps_input_check
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: mlkem_h.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_decaps_input_check
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        output wire busy,
        input wire in_valid,
        output wire in_ready,
        input wire in_kind,
        input wire [31 : 0] in_data,
        input wire [3 : 0] in_keep,
        input wire in_last,
        output reg done,
        output reg error,
        output reg inputs_valid,
        output reg [5 : 0] hash_bytes_compared,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam IDLE = 0, LOAD_DK = 1, LOAD_C = 2, H_CMD = 3, H_FEED = 4, H_WAIT = 5, COMPARE = 6, HOLD = 7;
    reg [2 : 0] state;
    reg [7 : 0] dk[0 : 2399], c[0 : 1087], digest[0 : 31];
    reg [10 : 0] word_count;
    reg [8 : 0] h_word;
    reg [3 : 0] hout_word;
    reg [5 : 0] cmp_index;
    reg mismatch;
    reg [11 : 0] scrub_addr;
    integer lane, reset_i;
    wire h_cmd_ready, h_in_ready, h_out_valid, h_out_last, h_busy, h_done, h_error, hzb, hzd;
    wire [31 : 0] h_out_data;
    wire [3 : 0] h_out_keep;
    wire h_cmd_valid = state == H_CMD;
    wire h_in_valid = state == H_FEED;
    wire [31 : 0] h_in_data = {dk[1152 + h_word * 4 + 3], dk[1152 + h_word * 4 + 2], dk[1152 + h_word * 4 + 1], dk[1152 + h_word * 4]};
    assign busy = (state != IDLE && state != HOLD) || zeroize_busy;
    assign in_ready = (state == LOAD_DK) || (state == LOAD_C);
    mlkem_h hcore(clk,
                  rst_n,
                  h_cmd_valid,
                  h_cmd_ready,
                  32'd1184,
                  h_in_valid,
                  h_in_ready,
                  h_in_data,
                  4'hf,
                  h_word == 295,
                  h_out_valid,
                  1'b1,
                  h_out_data,
                  h_out_keep,
                  h_out_last,
                  h_busy,
                  h_done,
                  h_error,
                  zeroize && !zeroize_busy,
                  hzb,
                  hzd);
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            word_count <= 0;
            h_word <= 0;
            hout_word <= 0;
            cmp_index <= 0;
            hash_bytes_compared <= 0;
            mismatch <= 0;
            done <= 0;
            error <= 0;
            inputs_valid <= 0;
            scrub_addr <= 0;
            zeroize_busy <= 0;
        end else if (zeroize && !zeroize_busy) begin
            state <= IDLE;
            inputs_valid <= 0;
            mismatch <= 0;
            word_count <= 0;
            cmp_index <= 0;
            hash_bytes_compared <= 0;
            scrub_addr <= 0;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            dk[scrub_addr] <= 0;
            if (scrub_addr < 1088)
                c[scrub_addr] <= 0;
            if (scrub_addr < 32)
                digest[scrub_addr] <= 0;
            if (scrub_addr == 2399) begin
                scrub_addr <= 0;
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end else
                scrub_addr <= scrub_addr + 1'b1;
        end else begin
            if (start) begin
                if (state != IDLE && state != HOLD)
                    error <= 1;
                else begin
                    state <= LOAD_DK;
                    word_count <= 0;
                    error <= 0;
                    inputs_valid <= 0;
                    mismatch <= 0;
                    hash_bytes_compared <= 0;
                end
            end
            if (in_valid && in_ready) begin
                if (in_keep != 4'hf || in_kind != (state == LOAD_C) || in_last != ((state == LOAD_DK) ? (word_count == 599) : (word_count == 271))) begin
                    state <= HOLD;
                    error <= 1;
                    inputs_valid <= 0;
                    done <= 1;
                end else begin
                    if (state == LOAD_DK)
                        for (lane = 0; lane < 4; lane = lane + 1)
                            dk[word_count * 4 + lane] <= in_data[lane * 8 +: 8];
                    else
                        for (lane = 0; lane < 4; lane = lane + 1)
                            c[word_count * 4 + lane] <= in_data[lane * 8 +: 8];
                    if ((state == LOAD_DK && word_count == 599)) begin
                        state <= LOAD_C;
                        word_count <= 0;
                    end else if (state == LOAD_C && word_count == 271) begin
                        state <= H_CMD;
                        word_count <= 0;
                    end else
                        word_count <= word_count + 1'b1;
                end
            end
            if (in_valid && !in_ready && !start)
                error <= 1;
            if (h_error) begin
                error <= 1;
                inputs_valid <= 0;
                state <= HOLD;
                done <= 1;
            end
            if (h_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    digest[hout_word * 4 + lane] <= h_out_data[lane * 8 +: 8];
                hout_word <= hout_word + 1'b1;
            end
            case (state)
                H_CMD:
                    if (h_cmd_ready) begin
                        h_word <= 0;
                        hout_word <= 0;
                        state <= H_FEED;
                    end
                H_FEED:
                    if (h_in_ready) begin
                        if (h_word == 295)
                            state <= H_WAIT;
                        else
                            h_word <= h_word + 1'b1;
                    end
                H_WAIT:
                    if (h_done) begin
                        cmp_index <= 0;
                        hash_bytes_compared <= 0;
                        mismatch <= 0;
                        state <= COMPARE;
                    end
                COMPARE: begin
                    mismatch <= mismatch | (digest[cmp_index] ^ dk[2336 + cmp_index]) != 0;
                    hash_bytes_compared <= hash_bytes_compared + 1'b1;
                    if (cmp_index == 31) begin
                        inputs_valid <= !(mismatch | ((digest[cmp_index] ^ dk[2336 + cmp_index]) != 0));
                        done <= 1;
                        state <= HOLD;
                    end else
                        cmp_index <= cmp_index + 1'b1;
                end
            endcase
        end
    end
endmodule
