`timescale 1ns / 1ps
// Deterministic FIPS 203 Algorithm 18 with fixed-work implicit rejection.
/*
 * Module: mlkem_decaps_internal
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: kpke_decrypt, kpke_encrypt, mlkem_g, mlkem_j.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_decaps_internal
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
        output reg busy,
        output reg done,
        output reg error,
        output reg [31 : 0] cycle_count,
        output reg [10 : 0] compare_count,
        output reg [5 : 0] select_count,
        input wire zeroize_req,
        output wire zeroize_busy,
        output reg zeroize_done);
    // -------------------------------------------------------------------------
    // FIPS 203 Algorithm 18 phases
    // -------------------------------------------------------------------------
    // D_* decrypts (dkPKE || c), G_* derives (K_prime || r_prime), J_* derives
    // K_bar = J(z || c), and E_* independently re-encrypts c_prime.
    localparam IDLE = 0, INPUT = 1, D_CMD = 2, D_FEED = 3, D_WAIT = 4, G_CMD = 5, G_FEED = 6, G_WAIT = 7, J_CMD = 8, J_FEED = 9, J_WAIT = 10, E_CMD = 11, E_FEED = 12, E_WAIT = 13, COMPARE = 14, SELECT = 15, OUTPUT = 16, SCRUB = 17, SCRUB_WAIT = 18;

    // -------------------------------------------------------------------------
    // M8-local record storage and phase counters
    // -------------------------------------------------------------------------
    // dk = dkPKE || ek || H(ek) || z.  c and c_prime are full 1088-byte
    // ciphertext records.  All byte arrays use low-byte-first stream lanes.
    reg [4 : 0] state;
    reg [7 : 0] dk[0 : 2399], c[0 : 1087], mp[0 : 31], kp[0 : 31], rp[0 : 31], kb[0 : 31], cp[0 : 1087], kout[0 : 31];
    reg [9 : 0] in_word, d_word, e_word, cp_word;
    reg [8 : 0] j_word;
    reg [4 : 0] g_word, gout_word;
    reg [3 : 0] dout_word, jout_word, out_word;
    reg [10 : 0] idx;
    reg [11 : 0] scrub_addr;
    reg mismatch;
    reg [7 : 0] mask;
    integer lane, reset_i;

    // -------------------------------------------------------------------------
    // Child-engine interfaces: K-PKE decrypt, G, J, and K-PKE encrypt
    // -------------------------------------------------------------------------
    wire dc_ready, d_in_ready, d_out_valid, d_done, d_error, d_nc, dzb, dzd;
    wire [31 : 0] d_out_data, d_cycles;
    wire [3 : 0] d_out_keep, dop0, dop1, dop2, dop3, dop4;
    wire d_out_last, d_busy;
    wire gc_ready, g_in_ready, g_out_valid, g_done, g_error, gzb, gzd;
    wire [31 : 0] g_out_data;
    wire [3 : 0] g_out_keep;
    wire g_out_last, g_busy;
    wire jc_ready, j_in_ready, j_out_valid, j_done, j_error, jzb, jzd;
    wire [31 : 0] j_out_data;
    wire [3 : 0] j_out_keep;
    wire j_out_last, j_busy;
    wire ec_ready, e_in_ready, e_out_valid, e_done, e_error, e_nc, ezb, ezd;
    wire [31 : 0] e_out_data, e_cycles;
    wire [3 : 0] e_out_keep, eop0, eop1, eop2, eop3, eop4, eop5, eop6;
    wire e_out_last, e_busy;
    reg dzd_seen, gzd_seen, jzd_seen, ezd_seen, explicit_scrub;

    // -------------------------------------------------------------------------
    // Parent stream contract and zeroize propagation
    // -------------------------------------------------------------------------
    wire child_zeroize = (state == SCRUB) && (scrub_addr == 0);
    assign zeroize_busy = explicit_scrub && ((state == SCRUB) || (state == SCRUB_WAIT));
    assign cmd_ready = state == IDLE && !zeroize_req;
    assign in_ready = state == INPUT && !zeroize_req;
    assign out_valid = state == OUTPUT && !zeroize_req;
    assign out_keep = 4'hf;
    assign out_last = state == OUTPUT && out_word == 7;
    assign out_data = {kout[out_word * 4 + 3], kout[out_word * 4 + 2], kout[out_word * 4 + 1], kout[out_word * 4]};

    // -------------------------------------------------------------------------
    // Child command/data wiring
    // -------------------------------------------------------------------------
    // d_feed carries dkPKE followed by c.  The child is responsible for the
    // K-PKE parse; this controller retains m_prime after its output handshake.
    wire [31 : 0] d_feed = (d_word < 288) ? {dk[d_word * 4 + 3], dk[d_word * 4 + 2], dk[d_word * 4 + 1], dk[d_word * 4]} : {c[(d_word - 288) * 4 + 3], c[(d_word - 288) * 4 + 2], c[(d_word - 288) * 4 + 1], c[(d_word - 288) * 4]};
    kpke_decrypt dc(clk,
                    rst_n,
                    state == D_CMD,
                    dc_ready,
                    state == D_FEED,
                    d_in_ready,
                    d_feed,
                    4'hf,
                    d_word == 559,
                    d_out_valid,
                    1'b1,
                    d_out_data,
                    d_out_keep,
                    d_out_last,
                    d_busy,
                    d_done,
                    d_error,
                    d_nc,
                    d_cycles,
                    dop0,
                    dop1,
                    dop2,
                    dop3,
                    dop4,
                    child_zeroize,
                    dzb,
                    dzd);

    // G consumes m_prime || stored H(ek) and returns K_prime || r_prime.
    wire [31 : 0] g_feed = (g_word < 8) ? {mp[g_word * 4 + 3], mp[g_word * 4 + 2], mp[g_word * 4 + 1], mp[g_word * 4]} : {dk[2336 + (g_word - 8) * 4 + 3], dk[2336 + (g_word - 8) * 4 + 2], dk[2336 + (g_word - 8) * 4 + 1], dk[2336 + (g_word - 8) * 4]};
    mlkem_g gc(clk,
               rst_n,
               state == G_CMD,
               gc_ready,
               32'd64,
               state == G_FEED,
               g_in_ready,
               g_feed,
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

    // J consumes z || c to create the exact implicit-rejection fallback key.
    wire [31 : 0] j_feed = (j_word < 8) ? {dk[2368 + j_word * 4 + 3], dk[2368 + j_word * 4 + 2], dk[2368 + j_word * 4 + 1], dk[2368 + j_word * 4]} : {c[(j_word - 8) * 4 + 3], c[(j_word - 8) * 4 + 2], c[(j_word - 8) * 4 + 1], c[(j_word - 8) * 4]};
    mlkem_j jc(clk,
               rst_n,
               state == J_CMD,
               jc_ready,
               32'd1120,
               state == J_FEED,
               j_in_ready,
               j_feed,
               4'hf,
               j_word == 279,
               j_out_valid,
               1'b1,
               j_out_data,
               j_out_keep,
               j_out_last,
               j_busy,
               j_done,
               j_error,
               child_zeroize,
               jzb,
               jzd);

    // Re-encryption consumes ek || m_prime || r_prime and produces c_prime.
    wire [31 : 0] e_feed = (e_word < 296) ? {dk[1152 + e_word * 4 + 3], dk[1152 + e_word * 4 + 2], dk[1152 + e_word * 4 + 1], dk[1152 + e_word * 4]} : (e_word < 304) ? {mp[(e_word - 296) * 4 + 3], mp[(e_word - 296) * 4 + 2], mp[(e_word - 296) * 4 + 1], mp[(e_word - 296) * 4]}
                                                                                                                                                                      : {rp[(e_word - 304) * 4 + 3], rp[(e_word - 304) * 4 + 2], rp[(e_word - 304) * 4 + 1], rp[(e_word - 304) * 4]};
    kpke_encrypt ec(clk,
                    rst_n,
                    state == E_CMD,
                    ec_ready,
                    state == E_FEED,
                    e_in_ready,
                    e_feed,
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
                    eop0,
                    eop1,
                    eop2,
                    eop3,
                    eop4,
                    eop5,
                    eop6,
                    child_zeroize,
                    ezb,
                    ezd);

    // -------------------------------------------------------------------------
    // Result capture, explicit zeroize, and Algorithm 18 FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            cycle_count <= 0;
            compare_count <= 0;
            select_count <= 0;
            in_word <= 0;
            d_word <= 0;
            e_word <= 0;
            cp_word <= 0;
            j_word <= 0;
            g_word <= 0;
            gout_word <= 0;
            dout_word <= 0;
            jout_word <= 0;
            out_word <= 0;
            idx <= 0;
            scrub_addr <= 0;
            mismatch <= 0;
            mask <= 0;
            dzd_seen <= 0;
            gzd_seen <= 0;
            jzd_seen <= 0;
            ezd_seen <= 0;
            explicit_scrub <= 0;
            zeroize_done <= 0;
        end else begin
            if (busy)
                cycle_count <= cycle_count + 1;
            if (d_error || g_error || j_error || e_error)
                error <= 1;
            if (dzd)
                dzd_seen <= 1;
            if (gzd)
                gzd_seen <= 1;
            if (jzd)
                jzd_seen <= 1;
            if (ezd)
                ezd_seen <= 1;
            if (d_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    mp[dout_word * 4 + lane] <= d_out_data[lane * 8 +: 8];
                dout_word <= dout_word + 1;
            end
            if (g_out_valid) begin
                if (gout_word < 8)
                    for (lane = 0; lane < 4; lane = lane + 1)
                        kp[gout_word * 4 + lane] <= g_out_data[lane * 8 +: 8];
                else
                    for (lane = 0; lane < 4; lane = lane + 1)
                        rp[(gout_word - 8) * 4 + lane] <= g_out_data[lane * 8 +: 8];
                gout_word <= gout_word + 1;
            end
            if (j_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    kb[jout_word * 4 + lane] <= j_out_data[lane * 8 +: 8];
                jout_word <= jout_word + 1;
            end
            if (e_out_valid) begin
                for (lane = 0; lane < 4; lane = lane + 1)
                    cp[cp_word * 4 + lane] <= e_out_data[lane * 8 +: 8];
                cp_word <= cp_word + 1;
            end
            if ((zeroize_req === 1'b1) && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                done <= 0;
                error <= 0;
                scrub_addr <= 0;
                mismatch <= 0;
                mask <= 0;
                dzd_seen <= 0;
                gzd_seen <= 0;
                jzd_seen <= 0;
                ezd_seen <= 0;
                explicit_scrub <= 1;
            end else
                case (state)
                    IDLE:
                        // Accept one concatenated dk || c record.
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            cycle_count <= 0;
                            compare_count <= 0;
                            select_count <= 0;
                            in_word <= 0;
                            state <= INPUT;
                        end
                    INPUT:
                        // Validate exact four-byte beats and preserve dk/c layout.
                        if (in_valid) begin
                            if (in_keep != 4'hf || in_last != (in_word == 871)) begin
                                error <= 1;
                                scrub_addr <= 0;
                                dzd_seen <= 0;
                                gzd_seen <= 0;
                                jzd_seen <= 0;
                                ezd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else begin
                                if (in_word < 600)
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        dk[in_word * 4 + lane] <= in_data[lane * 8 +: 8];
                                else
                                    for (lane = 0; lane < 4; lane = lane + 1)
                                        c[(in_word - 600) * 4 + lane] <= in_data[lane * 8 +: 8];
                                if (in_word == 871)
                                    state <= D_CMD;
                                else
                                    in_word <= in_word + 1;
                            end
                        end
                    D_CMD:
                        // Launch K-PKE.Decrypt(dkPKE, c).
                        if (dc_ready) begin
                            d_word <= 0;
                            dout_word <= 0;
                            state <= D_FEED;
                        end
                    D_FEED:
                        if (d_in_ready) begin
                            if (d_word == 559)
                                state <= D_WAIT;
                            else
                                d_word <= d_word + 1;
                        end
                    D_WAIT:
                        if (d_done)
                            state <= G_CMD;
                    G_CMD:
                        // Launch G(m_prime || H(ek)).
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
                            state <= J_CMD;
                    J_CMD:
                        // Launch J(z || c) before re-encryption; both paths run.
                        if (jc_ready) begin
                            j_word <= 0;
                            jout_word <= 0;
                            state <= J_FEED;
                        end
                    J_FEED:
                        if (j_in_ready) begin
                            if (j_word == 279)
                                state <= J_WAIT;
                            else
                                j_word <= j_word + 1;
                        end
                    J_WAIT:
                        if (j_done)
                            state <= E_CMD;
                    E_CMD:
                        // Launch K-PKE.Encrypt(ek, m_prime, r_prime).
                        if (ec_ready) begin
                            e_word <= 0;
                            cp_word <= 0;
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
                            idx <= 0;
                            mismatch <= 0;
                            compare_count <= 0;
                            state <= COMPARE;
                        end
                    COMPARE: begin
                        // Accumulate every ciphertext byte; no early exit.
                        mismatch <= mismatch | ((c[idx] ^ cp[idx]) != 0);
                        compare_count <= compare_count + 1;
                        if (idx == 1087) begin
                            mask <= (mismatch | ((c[idx] ^ cp[idx]) != 0)) ? 8'hff : 0;
                            idx <= 0;
                            state <= SELECT;
                        end else
                            idx <= idx + 1;
                    end
                    SELECT: begin
                        // Select K_prime on match, otherwise the J(z || c) fallback.
                        kout[idx[5 : 0]] <= (kp[idx[5 : 0]] & ~mask) | (kb[idx[5 : 0]] & mask);
                        select_count <= select_count + 1;
                        if (idx == 31) begin
                            mismatch <= 0;
                            mask <= 0;
                            out_word <= 0;
                            state <= OUTPUT;
                        end else
                            idx <= idx + 1;
                    end
                    OUTPUT:
                        // Stream the selected 32-byte shared secret.
                        if (out_valid && out_ready) begin
                            if (out_word == 7) begin
                                scrub_addr <= 0;
                                dzd_seen <= 0;
                                gzd_seen <= 0;
                                jzd_seen <= 0;
                                ezd_seen <= 0;
                                explicit_scrub <= 0;
                                state <= SCRUB;
                            end else
                                out_word <= out_word + 1;
                        end
                    SCRUB: begin
                        // Clear selected M8-local payload before returning ownership.
                        dk[scrub_addr] <= 0;
                        if (scrub_addr < 1088) begin
                            c[scrub_addr] <= 0;
                            cp[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 32) begin
                            mp[scrub_addr] <= 0;
                            kp[scrub_addr] <= 0;
                            rp[scrub_addr] <= 0;
                            kb[scrub_addr] <= 0;
                            kout[scrub_addr] <= 0;
                        end
                        if (scrub_addr == 2399)
                            state <= SCRUB_WAIT;
                        else
                            scrub_addr <= scrub_addr + 1;
                    end
                    SCRUB_WAIT:
                        // Wait for all launched children to acknowledge zeroize.
                        if ((dzd_seen || dzd) && (gzd_seen || gzd) && (jzd_seen || jzd) && (ezd_seen || ezd)) begin
                            busy <= 0;
                            if (explicit_scrub)
                                zeroize_done <= 1;
                            else
                                done <= 1;
                            explicit_scrub <= 0;
                            cycle_count <= 0;
                            compare_count <= 0;
                            select_count <= 0;
                            in_word <= 0;
                            d_word <= 0;
                            e_word <= 0;
                            cp_word <= 0;
                            j_word <= 0;
                            g_word <= 0;
                            gout_word <= 0;
                            dout_word <= 0;
                            jout_word <= 0;
                            out_word <= 0;
                            idx <= 0;
                            mismatch <= 0;
                            mask <= 0;
                            state <= IDLE;
                        end
                endcase
        end
    end
endmodule
