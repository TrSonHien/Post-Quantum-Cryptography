`timescale 1ns / 1ps
// Deterministic FIPS 203 Algorithm 16. Input stream is d || z.
/*
 * Module: mlkem_keygen_internal
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: kpke_keygen, mlkem_h.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_keygen_internal
    (
        input wire clk,
        input wire rst_n,
        input wire cmd_valid,
        output wire cmd_ready,
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
        output wire out_kind,
        output reg busy,
        output reg done,
        output reg error,
        output reg [31 : 0] cycle_count,
        input wire zeroize_req,
        output wire zeroize_busy,
        output reg zeroize_done);
    localparam IDLE = 0, INPUT = 1, K_CMD = 2, K_FEED = 3, K_WAIT = 4, H_CMD = 5, H_FEED = 6, H_WAIT = 7, ASSEMBLE = 8, OUTPUT = 9, SCRUB = 10, SCRUB_WAIT = 11;
    reg [3 : 0] state;
    reg [7 : 0] d[0 : 31], z[0 : 31], ek[0 : 1183], dkpke[0 : 1151], h[0 : 31], dk[0 : 2399];
    reg [4 : 0] in_word;
    reg [3 : 0] k_in_word, hout_word;
    reg [8 : 0] h_in_word;
    reg [9 : 0] k_ek_word, k_dk_word;
    reg [9 : 0] out_word;
    reg [11 : 0] scrub_addr;
    integer lane, j;
    wire k_ready, k_in_ready, k_out_valid, k_out_last, k_out_type, k_busy, k_done, k_error, kzb, kzd;
    wire [31 : 0] k_out_data;
    wire [3 : 0] k_out_keep;
    wire [31 : 0] k_cycles;
    wire [3 : 0] op0, op1, op2, op3, op4, op5;
    wire hc_ready, h_in_ready, h_out_valid, h_out_last, h_busy, h_done, h_error, hzb, hzd;
    wire [31 : 0] h_out_data;
    wire [3 : 0] h_out_keep;
    reg kzd_seen, hzd_seen, explicit_scrub;
    wire child_zeroize = (state == SCRUB) && (scrub_addr == 0);
    assign zeroize_busy = explicit_scrub && ((state == SCRUB) || (state == SCRUB_WAIT));
    assign cmd_ready = state == IDLE && !zeroize_req;
    assign in_ready = state == INPUT && !zeroize_req;
    assign out_valid = state == OUTPUT && !zeroize_req;
    assign out_keep = 4'hf;
    assign out_kind = out_word >= 296;
    assign out_last = state == OUTPUT && ((out_word == 295) || (out_word == 895));
    assign out_data = (out_word < 296) ? {ek[out_word * 4 + 3], ek[out_word * 4 + 2], ek[out_word * 4 + 1], ek[out_word * 4]} : {dk[(out_word - 296) * 4 + 3], dk[(out_word - 296) * 4 + 2], dk[(out_word - 296) * 4 + 1], dk[(out_word - 296) * 4]};
    kpke_keygen kcore(clk,
                      rst_n,
                      state == K_CMD,
                      k_ready,
                      state == K_FEED,
                      k_in_ready,
                      {d[k_in_word * 4 + 3], d[k_in_word * 4 + 2], d[k_in_word * 4 + 1], d[k_in_word * 4]},
                      4'hf,
                      k_in_word == 7,
                      k_out_valid,
                      1'b1,
                      k_out_data,
                      k_out_keep,
                      k_out_last,
                      k_out_type,
                      k_busy,
                      k_done,
                      k_error,
                      k_cycles,
                      op0,
                      op1,
                      op2,
                      op3,
                      op4,
                      op5,
                      child_zeroize,
                      kzb,
                      kzd);
    mlkem_h hcore(clk,
                  rst_n,
                  state == H_CMD,
                  hc_ready,
                  32'd1184,
                  state == H_FEED,
                  h_in_ready,
                  {ek[h_in_word * 4 + 3], ek[h_in_word * 4 + 2], ek[h_in_word * 4 + 1], ek[h_in_word * 4]},
                  4'hf,
                  h_in_word == 295,
                  h_out_valid,
                  1'b1,
                  h_out_data,
                  h_out_keep,
                  h_out_last,
                  h_busy,
                  h_done,
                  h_error,
                  child_zeroize,
                  hzb,
                  hzd);
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            cycle_count <= 0;
            in_word <= 0;
            k_in_word <= 0;
            h_in_word <= 0;
            hout_word <= 0;
            k_ek_word <= 0;
            k_dk_word <= 0;
            out_word <= 0;
            scrub_addr <= 0;
            kzd_seen <= 0;
            hzd_seen <= 0;
            explicit_scrub <= 0;
            zeroize_done <= 0;
        end else begin
            if (busy)
                cycle_count <= cycle_count + 1'b1;
            if (k_error || h_error)
                error <= 1;
            if (kzd)
                kzd_seen <= 1;
            if (hzd)
                hzd_seen <= 1;
            if (k_out_valid) begin
                if (!k_out_type) begin
                    for (lane = 0; lane < 4; lane = lane + 1)
                        ek[k_ek_word * 4 + lane] <= k_out_data[lane * 8 +: 8];
                    k_ek_word <= k_ek_word + 1'b1;
                end else begin
                    for (lane = 0; lane < 4; lane = lane + 1)
                        dkpke[k_dk_word * 4 + lane] <= k_out_data[lane * 8 +: 8];
                    k_dk_word <= k_dk_word + 1'b1;
                end
            end
            if (h_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    h[hout_word * 4 + lane] <= h_out_data[lane * 8 +: 8];
                hout_word <= hout_word + 1'b1;
            end
            if ((zeroize_req === 1'b1) && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                done <= 0;
                error <= 0;
                scrub_addr <= 0;
                kzd_seen <= 0;
                hzd_seen <= 0;
                explicit_scrub <= 1;
            end else
                case (state)
                    IDLE:
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            cycle_count <= 0;
                            in_word <= 0;
                            state <= INPUT;
                        end
                    INPUT:
                        if (in_valid) begin
                            if (in_keep != 4'hf || in_last != (in_word == 15)) begin
                                error <= 1;
                                scrub_addr <= 0;
                                kzd_seen <= 0;
                                hzd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else begin
                                if (in_word < 8)
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        d[in_word * 4 + lane] <= in_data[lane * 8 +: 8];
                                else
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        z[(in_word - 8) * 4 + lane] <= in_data[lane * 8 +: 8];
                                if (in_word == 15)
                                    state <= K_CMD;
                                else
                                    in_word <= in_word + 1'b1;
                            end
                        end
                    K_CMD:
                        if (k_ready) begin
                            k_in_word <= 0;
                            k_ek_word <= 0;
                            k_dk_word <= 0;
                            state <= K_FEED;
                        end
                    K_FEED:
                        if (k_in_ready) begin
                            if (k_in_word == 7)
                                state <= K_WAIT;
                            else
                                k_in_word <= k_in_word + 1'b1;
                        end
                    K_WAIT:
                        if (k_done)
                            state <= H_CMD;
                    H_CMD:
                        if (hc_ready) begin
                            h_in_word <= 0;
                            hout_word <= 0;
                            state <= H_FEED;
                        end
                    H_FEED:
                        if (h_in_ready) begin
                            if (h_in_word == 295)
                                state <= H_WAIT;
                            else
                                h_in_word <= h_in_word + 1'b1;
                        end
                    H_WAIT:
                        if (h_done)
                            state <= ASSEMBLE;
                    ASSEMBLE: begin
                        for (j = 0; j < 1152; j = j + 1)
                            dk[j] <= dkpke[j];
                        for (j = 0; j < 1184; j = j + 1)
                            dk[1152 + j] <= ek[j];
                        for (j = 0; j < 32; j = j + 1) begin
                            dk[2336 + j] <= h[j];
                            dk[2368 + j] <= z[j];
                        end
                        out_word <= 0;
                        state <= OUTPUT;
                    end
                    OUTPUT:
                        if (out_valid && out_ready) begin
                            if (out_word == 895) begin
                                scrub_addr <= 0;
                                kzd_seen <= 0;
                                hzd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else
                                out_word <= out_word + 1'b1;
                        end
                    SCRUB: begin
                        if (scrub_addr < 32) begin
                            d[scrub_addr] <= 0;
                            z[scrub_addr] <= 0;
                            h[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 1152)
                            dkpke[scrub_addr] <= 0;
                        if (scrub_addr < 1184)
                            ek[scrub_addr] <= 0;
                        dk[scrub_addr] <= 0;
                        if (scrub_addr == 2399)
                            state <= SCRUB_WAIT;
                        else
                            scrub_addr <= scrub_addr + 1'b1;
                    end
                    SCRUB_WAIT:
                        if ((kzd_seen || kzd) && (hzd_seen || hzd)) begin
                            busy <= 0;
                            if (explicit_scrub)
                                zeroize_done <= 1;
                            else
                                done <= 1;
                            explicit_scrub <= 0;
                            cycle_count <= 0;
                            in_word <= 0;
                            k_in_word <= 0;
                            h_in_word <= 0;
                            hout_word <= 0;
                            k_ek_word <= 0;
                            k_dk_word <= 0;
                            out_word <= 0;
                            state <= IDLE;
                        end
                endcase
        end
    end
endmodule
