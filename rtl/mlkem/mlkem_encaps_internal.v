`timescale 1ns / 1ps
// Deterministic FIPS 203 Algorithm 17. Input stream is ek || m.
/*
 * Module: mlkem_encaps_internal
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: kpke_encrypt, mlkem_g, mlkem_h.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_encaps_internal
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
    // Algorithm 17 phases: capture ek || m, derive h = H(ek), derive K || r
    // from G(m || h), then run K-PKE.Encrypt and stream K followed by c.
    localparam IDLE = 0, INPUT = 1, H_CMD = 2, H_FEED = 3, H_WAIT = 4, G_CMD = 5, G_FEED = 6, G_WAIT = 7, E_CMD = 8, E_FEED = 9, E_WAIT = 10, OUTPUT = 11, SCRUB = 12, SCRUB_WAIT = 13;

    // Local storage retains ek, m, h, K, r, and c only for this controller
    // transaction.  Byte streams are low-byte-first within each word.
    reg [3 : 0] state;
    reg [7 : 0] ek[0 : 1183], m[0 : 31], h[0 : 31], k[0 : 31], r[0 : 31], c[0 : 1087];
    reg [8 : 0] in_word, h_word, e_word;
    reg [4 : 0] g_word, gout_word;
    reg [9 : 0] c_word, out_word;
    reg [10 : 0] scrub_addr;
    integer lane, reset_i;
    wire hc_ready, h_in_ready, h_out_valid, h_done, h_error, hzb, hzd;
    wire [31 : 0] h_out_data;
    wire [3 : 0] h_out_keep;
    wire h_out_last, h_busy;
    wire gc_ready, g_in_ready, g_out_valid, g_done, g_error, gzb, gzd;
    wire [31 : 0] g_out_data;
    wire [3 : 0] g_out_keep;
    wire g_out_last, g_busy;
    wire ec_ready, e_in_ready, e_out_valid, e_done, e_error, e_nc, ezb, ezd;
    wire [31 : 0] e_out_data, e_cycles;
    wire [3 : 0] e_out_keep, op0, op1, op2, op3, op4, op5, op6;
    wire e_out_last, e_busy;
    reg hzd_seen, gzd_seen, ezd_seen, explicit_scrub;
    wire child_zeroize = (state == SCRUB) && (scrub_addr == 0);
    assign zeroize_busy = explicit_scrub && ((state == SCRUB) || (state == SCRUB_WAIT));
    assign cmd_ready = state == IDLE && !zeroize_req;
    assign in_ready = state == INPUT && !zeroize_req;
    assign out_valid = state == OUTPUT && !zeroize_req;
    assign out_keep = 4'hf;
    assign out_kind = out_word >= 8;
    assign out_last = state == OUTPUT && ((out_word == 7) || (out_word == 279));
    assign out_data = (out_word < 8) ? {k[out_word * 4 + 3], k[out_word * 4 + 2], k[out_word * 4 + 1], k[out_word * 4]} : {c[(out_word - 8) * 4 + 3], c[(out_word - 8) * 4 + 2], c[(out_word - 8) * 4 + 1], c[(out_word - 8) * 4]};
    mlkem_h hc(clk,
               rst_n,
               state == H_CMD,
               hc_ready,
               32'd1184,
               state == H_FEED,
               h_in_ready,
               {ek[h_word * 4 + 3], ek[h_word * 4 + 2], ek[h_word * 4 + 1], ek[h_word * 4]},
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
               child_zeroize,
               hzb,
               hzd);
    wire [31 : 0] g_feed_data = (g_word < 8) ? {m[g_word * 4 + 3], m[g_word * 4 + 2], m[g_word * 4 + 1], m[g_word * 4]} : {h[(g_word - 8) * 4 + 3], h[(g_word - 8) * 4 + 2], h[(g_word - 8) * 4 + 1], h[(g_word - 8) * 4]};
    mlkem_g gc(clk,
               rst_n,
               state == G_CMD,
               gc_ready,
               32'd64,
               state == G_FEED,
               g_in_ready,
               g_feed_data,
               4'hf,
               g_word == 15,
               g_out_valid,
               1'b1,
               g_out_data,
               g_out_keep,
               g_out_last,
               g_busy,
               g_done,
               g_error,
               child_zeroize,
               gzb,
               gzd);
    wire [31 : 0] e_feed_data = (e_word < 296) ? {ek[e_word * 4 + 3], ek[e_word * 4 + 2], ek[e_word * 4 + 1], ek[e_word * 4]} : (e_word < 304) ? {m[(e_word - 296) * 4 + 3], m[(e_word - 296) * 4 + 2], m[(e_word - 296) * 4 + 1], m[(e_word - 296) * 4]}
                                                                                                                                               : {r[(e_word - 304) * 4 + 3], r[(e_word - 304) * 4 + 2], r[(e_word - 304) * 4 + 1], r[(e_word - 304) * 4]};
    kpke_encrypt ec(clk,
                    rst_n,
                    state == E_CMD,
                    ec_ready,
                    state == E_FEED,
                    e_in_ready,
                    e_feed_data,
                    4'hf,
                    e_word == 311,
                    e_out_valid,
                    1'b1,
                    e_out_data,
                    e_out_keep,
                    e_out_last,
                    e_busy,
                    e_done,
                    e_error,
                    e_nc,
                    e_cycles,
                    op0,
                    op1,
                    op2,
                    op3,
                    op4,
                    op5,
                    op6,
                    child_zeroize,
                    ezb,
                    ezd);
    // Result capture, local-state scrub, and the variable-latency controller.
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
            h_word <= 0;
            g_word <= 0;
            gout_word <= 0;
            e_word <= 0;
            c_word <= 0;
            out_word <= 0;
            scrub_addr <= 0;
            hzd_seen <= 0;
            gzd_seen <= 0;
            ezd_seen <= 0;
            explicit_scrub <= 0;
            zeroize_done <= 0;
        end else begin
            if (busy)
                cycle_count <= cycle_count + 1;
            if (h_error || g_error || e_error)
                error <= 1;
            if (hzd)
                hzd_seen <= 1;
            if (gzd)
                gzd_seen <= 1;
            if (ezd)
                ezd_seen <= 1;
            if (h_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    h[gout_word * 4 + lane] <= h_out_data[lane * 8 +: 8];
                gout_word <= gout_word + 1;
            end
            if (g_out_valid) begin
                if (gout_word < 8)
                    for (lane = 0; lane < 4; lane = lane + 1)
                        k[gout_word * 4 + lane] <= g_out_data[lane * 8 +: 8];
                else
                    for (lane = 0; lane < 4; lane = lane + 1)
                        r[(gout_word - 8) * 4 + lane] <= g_out_data[lane * 8 +: 8];
                gout_word <= gout_word + 1;
            end
            if (e_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    c[c_word * 4 + lane] <= e_out_data[lane * 8 +: 8];
                c_word <= c_word + 1;
            end
            if ((zeroize_req === 1'b1) && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                done <= 0;
                error <= 0;
                scrub_addr <= 0;
                hzd_seen <= 0;
                gzd_seen <= 0;
                ezd_seen <= 0;
                explicit_scrub <= 1;
            end else
                case (state)
                    IDLE:
                        // Accept an internal Encaps request.
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            cycle_count <= 0;
                            in_word <= 0;
                            state <= INPUT;
                        end
                    INPUT:
                        // Capture exactly ek || m before launching H.
                        if (in_valid) begin
                            if (in_keep != 4'hf || in_last != (in_word == 303)) begin
                                error <= 1;
                                scrub_addr <= 0;
                                hzd_seen <= 0;
                                gzd_seen <= 0;
                                ezd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else begin
                                if (in_word < 296)
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        ek[in_word * 4 + lane] <= in_data[lane * 8 +: 8];
                                else
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        m[(in_word - 296) * 4 + lane] <= in_data[lane * 8 +: 8];
                                if (in_word == 303)
                                    state <= H_CMD;
                                else
                                    in_word <= in_word + 1;
                            end
                        end
                    H_CMD:
                        // Derive h = H(ek).
                        if (hc_ready) begin
                            h_word <= 0;
                            gout_word <= 0;
                            state <= H_FEED;
                        end
                    H_FEED:
                        if (h_in_ready) begin
                            if (h_word == 295)
                                state <= H_WAIT;
                            else
                                h_word <= h_word + 1;
                        end
                    H_WAIT:
                        if (h_done)
                            state <= G_CMD;
                    G_CMD:
                        // Derive K || r = G(m || h).
                        if (gc_ready) begin
                            g_word <= 0;
                            gout_word <= 0;
                            state <= G_FEED;
                        end
                    G_FEED:
                        if (g_in_ready) begin
                            if (g_word == 15)
                                state <= G_WAIT;
                            else
                                g_word <= g_word + 1;
                        end
                    G_WAIT:
                        if (g_done)
                            state <= E_CMD;
                    E_CMD:
                        // Encrypt ek, m, r through the existing K-PKE child.
                        if (ec_ready) begin
                            e_word <= 0;
                            c_word <= 0;
                            state <= E_FEED;
                        end
                    E_FEED:
                        if (e_in_ready) begin
                            if (e_word == 311)
                                state <= E_WAIT;
                            else
                                e_word <= e_word + 1;
                        end
                    E_WAIT:
                        if (e_done) begin
                            out_word <= 0;
                            state <= OUTPUT;
                        end
                    OUTPUT:
                        // Stream the shared secret followed by ciphertext.
                        if (out_valid && out_ready) begin
                            if (out_word == 279) begin
                                scrub_addr <= 0;
                                hzd_seen <= 0;
                                gzd_seen <= 0;
                                ezd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else
                                out_word <= out_word + 1;
                        end
                    SCRUB: begin
                        // Clear selected M8-local message, coins, key, and ciphertext state.
                        if (scrub_addr < 32) begin
                            m[scrub_addr] <= 0;
                            h[scrub_addr] <= 0;
                            k[scrub_addr] <= 0;
                            r[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 1088)
                            c[scrub_addr] <= 0;
                        ek[scrub_addr] <= 0;
                        if (scrub_addr == 1183)
                            state <= SCRUB_WAIT;
                        else
                            scrub_addr <= scrub_addr + 1;
                    end
                    SCRUB_WAIT:
                        if ((hzd_seen || hzd) && (gzd_seen || gzd) && (ezd_seen || ezd)) begin
                            busy <= 0;
                            if (explicit_scrub)
                                zeroize_done <= 1;
                            else
                                done <= 1;
                            explicit_scrub <= 0;
                            cycle_count <= 0;
                            in_word <= 0;
                            h_word <= 0;
                            g_word <= 0;
                            gout_word <= 0;
                            e_word <= 0;
                            c_word <= 0;
                            out_word <= 0;
                            state <= IDLE;
                        end
                endcase
        end
    end
endmodule
