`timescale 1ns / 1ps

// Deterministic FIPS 203 Algorithm 13 controller for ML-KEM-768.
/*
 * Module: kpke_keygen
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: K-PKE controller or deterministic matrix/noise orchestration.
 * Standard role: FIPS 203 Algorithms 13--15 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: kpke_matrix_row_sampler, kpke_noise_vector_sampler, mlkem_g, poly_add_pipe, polyvec_basemul_acc_pipe, polyvec_encode12_pipe, polyvec_ntt_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module kpke_keygen
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
        output wire out_type,
        output reg busy,
        output reg done,
        output reg error,
        output reg [31 : 0] cycle_count,
        output reg [3 : 0] g_operations,
        output reg [3 : 0] sample_ntt_operations,
        output reg [3 : 0] noise_operations,
        output reg [3 : 0] polyvec_ntt_operations,
        output reg [3 : 0] dot_operations,
        output reg [3 : 0] poly_add_operations,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam NORMAL = 2'b01, NTT = 2'b10;
    localparam [5 : 0] IDLE = 0, INPUT = 1, G_CMD = 2, G_FEED = 3, G_WAIT = 4,
                       NOISE_S_START = 5, NOISE_S_WAIT = 6, NOISE_E_START = 7, NOISE_E_WAIT = 8,
                       NTT_BEGIN = 9, NTT_LOAD = 10, NTT_START = 11, NTT_WAIT = 12, NTT_READ = 13, NTT_DRAIN = 14, NTT_RELEASE = 15,
                       MAT_START = 16, MAT_WAIT = 17, BASE_BEGIN = 18, BASE_LOAD = 19, BASE_START = 20, BASE_WAIT = 21, BASE_READ = 22, BASE_DRAIN = 23, BASE_RELEASE = 24,
                       ADD_BEGIN = 25, ADD_LOAD = 26, ADD_START = 27, ADD_WAIT = 28, ADD_READ = 29, ADD_DRAIN = 30, ADD_RELEASE = 31,
                       ENC_START = 32, ENC_FEED = 33, ENC_WAIT = 34, OUTPUT = 35, SCRUB = 37, WAIT_CHILD_ZERO = 38;
    reg [5 : 0] state;
    reg [7 : 0] d[0 : 31], rho[0 : 31], sigma[0 : 31], ek[0 : 1183], dk[0 : 1151];
    reg [11 : 0] s[0 : 767], e[0 : 767], s_hat[0 : 767], e_hat[0 : 767], a_row[0 : 767], dot[0 : 255], t_hat[0 : 767];
    reg [9 : 0] linear, linear_d;
    reg [7 : 0] idx;
    reg [1 : 0] elem, row;
    reg operand, ntt_phase, enc_phase;
    reg [3 : 0] in_word;
    reg [4 : 0] g_in_word, g_out_word;
    reg [9 : 0] enc_word, out_word;
    reg [10 : 0] scrub_addr;
    reg [6 : 0] child_zeroize_req, child_done_seen;
    wire [6 : 0] child_zeroize_busy, child_zeroize_done;
    wire zeroize_req = (zeroize === 1'b1);
    integer j;
    wire g_cmd_valid, g_cmd_ready, g_in_valid, g_in_ready;
    reg [31 : 0] g_in_data;
    wire [3 : 0] g_in_keep;
    wire g_in_last;
    wire g_out_valid;
    wire [31 : 0] g_out_data;
    wire [3 : 0] g_out_keep;
    wire g_out_last, g_busy, g_done, g_error;
    wire noise_start, noise_busy, noise_done, noise_error, noise_valid;
    wire [11 : 0] noise_coeff;
    wire [7 : 0] noise_index, noise_nonce, noise_next;
    wire [1 : 0] noise_poly, noise_domain;
    wire [2 : 0] noise_samples;
    wire ntt_load_begin, ntt_load_we, ntt_load_ready, ntt_start, ntt_busy, ntt_done, ntt_error, ntt_rv, ntt_rr;
    wire [11 : 0] ntt_rc, ntt_load_coeff;
    wire [1 : 0] ntt_rd, ntt_load_poly;
    wire ntt_complete;
    wire mat_start, mat_busy, mat_done, mat_error, mat_valid;
    wire [11 : 0] mat_coeff;
    wire [7 : 0] mat_idx, mi0, mi1;
    wire [1 : 0] mat_poly, mat_domain;
    wire [2 : 0] mat_samples;
    wire base_begin, base_we, base_lr, base_start, base_busy, base_done, base_error, base_rv;
    wire [11 : 0] base_rc, base_lc;
    wire [1 : 0] base_rd;
    wire base_complete;
    wire add_begin, add_start, add_busy, add_done, add_error, add_rv;
    wire [11 : 0] add_rc;
    wire [1 : 0] add_rd;
    wire add_complete, add_lr;
    wire enc_start, enc_busy, enc_done, enc_error, enc_in_ready, enc_out_valid;
    wire [31 : 0] enc_out_data;
    wire [3 : 0] enc_out_keep;
    wire enc_out_last;
    wire [1 : 0] enc_poly;

    assign cmd_ready = (state == IDLE);
    assign in_ready = (state == INPUT);
    assign out_valid = (state == OUTPUT);
    assign out_keep = 4'hf;
    assign out_type = (out_word >= 296);
    assign out_last = (state == OUTPUT) && ((out_word == 295) || (out_word == 583));
    assign out_data = (out_word < 296) ? {ek[out_word * 4 + 3], ek[out_word * 4 + 2], ek[out_word * 4 + 1], ek[out_word * 4]} : {dk[(out_word - 296) * 4 + 3], dk[(out_word - 296) * 4 + 2], dk[(out_word - 296) * 4 + 1], dk[(out_word - 296) * 4]};

    // G(d || byte(k)), byte(k)=03.
    assign g_cmd_valid = (state == G_CMD);
    assign g_in_valid = (state == G_FEED);
    assign g_in_keep = (g_in_word == 8) ? 4'b0001 : 4'hf;
    assign g_in_last = (g_in_word == 8);
    always @* begin
        if (g_in_word < 8)
            g_in_data = {d[g_in_word * 4 + 3], d[g_in_word * 4 + 2], d[g_in_word * 4 + 1], d[g_in_word * 4]};
        else
            g_in_data = 32'h00000003;
    end
    mlkem_g g(.clk(clk),
              .rst_n(rst_n),
              .cmd_valid(g_cmd_valid),
              .cmd_ready(g_cmd_ready),
              .msg_len_bytes(33),
              .in_valid(g_in_valid),
              .in_ready(g_in_ready),
              .in_data(g_in_data),
              .in_keep(g_in_keep),
              .in_last(g_in_last),
              .out_valid(g_out_valid),
              .out_ready(1'b1),
              .out_data(g_out_data),
              .out_keep(g_out_keep),
              .out_last(g_out_last),
              .busy(g_busy),
              .done(g_done),
              .error(g_error),
              .zeroize_req(child_zeroize_req[0]),
              .zeroize_busy(child_zeroize_busy[0]),
              .zeroize_done(child_zeroize_done[0]));

    // Shared noise-vector helper.
    assign noise_start = (state == NOISE_S_START) || (state == NOISE_E_START);
    kpke_noise_vector_sampler nv(.clk(clk),
                                 .rst_n(rst_n),
                                 .start(noise_start),
                                 .seed({sigma[31], sigma[30], sigma[29], sigma[28], sigma[27], sigma[26], sigma[25], sigma[24], sigma[23], sigma[22], sigma[21], sigma[20], sigma[19], sigma[18], sigma[17], sigma[16], sigma[15], sigma[14], sigma[13], sigma[12], sigma[11], sigma[10], sigma[9], sigma[8], sigma[7], sigma[6], sigma[5], sigma[4], sigma[3], sigma[2], sigma[1], sigma[0]}),
                                 .start_nonce((state == NOISE_E_START || state == NOISE_E_WAIT) ? 8'd3 : 8'd0),
                                 .eta(2),
                                 .busy(noise_busy),
                                 .done(noise_done),
                                 .error(noise_error),
                                 .out_valid(noise_valid),
                                 .out_ready(1'b1),
                                 .out_coeff(noise_coeff),
                                 .out_index(noise_index),
                                 .out_poly_index(noise_poly),
                                 .out_domain(noise_domain),
                                 .active_nonce(noise_nonce),
                                 .next_nonce(noise_next),
                                 .samples_started(noise_samples),
                                 .zeroize_req(child_zeroize_req[1]),
                                 .zeroize_busy(child_zeroize_busy[1]),
                                 .zeroize_done(child_zeroize_done[1]));

    // One serialized polyvec NTT engine, used for s then e.
    assign ntt_load_begin = (state == NTT_BEGIN);
    assign ntt_load_we = (state == NTT_LOAD);
    assign ntt_start = (state == NTT_START);
    assign ntt_rr = (state == NTT_READ);
    assign ntt_load_poly = elem;
    assign ntt_load_coeff = ntt_phase ? e[{elem, idx}] : s[{elem, idx}];
    polyvec_ntt_pipe pn(.clk(clk),
                        .rst_n(rst_n),
                        .load_begin(ntt_load_begin),
                        .load_operand(1'b0),
                        .load_poly_idx(ntt_load_poly),
                        .load_domain(NORMAL),
                        .load_we(ntt_load_we),
                        .load_idx(idx),
                        .load_coeff(ntt_load_coeff),
                        .load_ready(ntt_load_ready),
                        .start(ntt_start),
                        .busy(ntt_busy),
                        .done(ntt_done),
                        .error(ntt_error),
                        .result_req(ntt_rr),
                        .result_poly_idx(elem),
                        .result_idx(idx),
                        .result_valid(ntt_rv),
                        .result_coeff(ntt_rc),
                        .result_domain(ntt_rd),
                        .result_complete(ntt_complete),
                        .result_release(state == NTT_RELEASE),
                        .zeroize_req(child_zeroize_req[2]),
                        .zeroize_busy(child_zeroize_busy[2]),
                        .zeroize_done(child_zeroize_done[2]));

    // Matrix row helper.
    assign mat_start = (state == MAT_START);
    kpke_matrix_row_sampler mr(.clk(clk),
                               .rst_n(rst_n),
                               .start(mat_start),
                               .rho({rho[31], rho[30], rho[29], rho[28], rho[27], rho[26], rho[25], rho[24], rho[23], rho[22], rho[21], rho[20], rho[19], rho[18], rho[17], rho[16], rho[15], rho[14], rho[13], rho[12], rho[11], rho[10], rho[9], rho[8], rho[7], rho[6], rho[5], rho[4], rho[3], rho[2], rho[1], rho[0]}),
                               .row(row),
                               .transpose(1'b0),
                               .busy(mat_busy),
                               .done(mat_done),
                               .error(mat_error),
                               .out_valid(mat_valid),
                               .out_ready(1'b1),
                               .out_coeff(mat_coeff),
                               .out_index(mat_idx),
                               .out_poly_index(mat_poly),
                               .out_domain(mat_domain),
                               .sample_index0(mi0),
                               .sample_index1(mi1),
                               .samples_started(mat_samples),
                               .zeroize_req(child_zeroize_req[3]),
                               .zeroize_busy(child_zeroize_busy[3]),
                               .zeroize_done(child_zeroize_done[3]));

    // Shared polyvec dot-product engine.
    assign base_begin = (state == BASE_BEGIN);
    assign base_we = (state == BASE_LOAD);
    assign base_start = (state == BASE_START);
    assign base_lc = operand ? s_hat[{elem, idx}] : a_row[{elem, idx}];
    polyvec_basemul_acc_pipe ba(.clk(clk),
                                .rst_n(rst_n),
                                .load_begin(base_begin),
                                .load_operand(operand),
                                .load_poly_idx(elem),
                                .load_domain(NTT),
                                .load_we(base_we),
                                .load_idx(idx),
                                .load_coeff(base_lc),
                                .load_ready(base_lr),
                                .start(base_start),
                                .busy(base_busy),
                                .done(base_done),
                                .error(base_error),
                                .result_req(state == BASE_READ),
                                .result_idx(idx),
                                .result_valid(base_rv),
                                .result_coeff(base_rc),
                                .result_domain(base_rd),
                                .result_complete(base_complete),
                                .result_release(state == BASE_RELEASE),
                                .zeroize_req(child_zeroize_req[4]),
                                .zeroize_busy(child_zeroize_busy[4]),
                                .zeroize_done(child_zeroize_done[4]));

    // Shared NTT-domain polynomial addition.
    assign add_begin = (state == ADD_BEGIN);
    assign add_start = (state == ADD_START);
    poly_add_pipe pa(.clk(clk),
                     .rst_n(rst_n),
                     .load_begin(add_begin),
                     .load_operand(operand),
                     .load_domain(NTT),
                     .a_load_we((state == ADD_LOAD) && !operand),
                     .a_load_idx(idx),
                     .a_load_coeff(dot[idx]),
                     .b_load_we((state == ADD_LOAD) && operand),
                     .b_load_idx(idx),
                     .b_load_coeff(e_hat[{row, idx}]),
                     .load_ready(add_lr),
                     .start(add_start),
                     .busy(add_busy),
                     .done(add_done),
                     .error(add_error),
                     .result_req(state == ADD_READ),
                     .result_idx(idx),
                     .result_valid(add_rv),
                     .result_coeff(add_rc),
                     .result_domain(add_rd),
                     .result_complete(add_complete),
                     .result_release(state == ADD_RELEASE),
                     .zeroize_req(child_zeroize_req[5]),
                     .zeroize_busy(child_zeroize_busy[5]),
                     .zeroize_done(child_zeroize_done[5]));

    // One d12 polyvec encoder, first t_hat then s_hat.
    assign enc_start = (state == ENC_START);
    polyvec_encode12_pipe pe(.clk(clk),
                             .rst_n(rst_n),
                             .start(enc_start),
                             .input_domain(NTT),
                             .busy(enc_busy),
                             .done(enc_done),
                             .error(enc_error),
                             .in_valid(state == ENC_FEED),
                             .in_ready(enc_in_ready),
                             .in_coeff(enc_phase ? s_hat[linear] : t_hat[linear]),
                             .out_valid(enc_out_valid),
                             .out_ready(1'b1),
                             .out_data(enc_out_data),
                             .out_keep(enc_out_keep),
                             .out_last(enc_out_last),
                             .poly_index(enc_poly),
                             .zeroize_req(child_zeroize_req[6]),
                             .zeroize_busy(child_zeroize_busy[6]),
                             .zeroize_done(child_zeroize_done[6]));

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            cycle_count <= 0;
            in_word <= 0;
            g_in_word <= 0;
            g_out_word <= 0;
            linear <= 0;
            linear_d <= 0;
            idx <= 0;
            elem <= 0;
            row <= 0;
            operand <= 0;
            ntt_phase <= 0;
            enc_phase <= 0;
            enc_word <= 0;
            out_word <= 0;
            scrub_addr <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            g_operations <= 0;
            sample_ntt_operations <= 0;
            noise_operations <= 0;
            polyvec_ntt_operations <= 0;
            dot_operations <= 0;
            poly_add_operations <= 0;
        end else begin
            done <= 0;
            zeroize_done <= 0;
            if (zeroize_busy) begin
                child_done_seen <= child_done_seen | child_zeroize_done;
                child_zeroize_req <= child_zeroize_req & ~child_zeroize_done;
            end
            if (busy)
                cycle_count <= cycle_count + 1;
            if (cmd_valid && !cmd_ready && !zeroize_req)
                error <= 1;
            if (in_valid && !in_ready && !zeroize_busy)
                error <= 1;
            if (g_error || noise_error || ntt_error || mat_error || base_error || add_error || enc_error)
                error <= 1;
            if (g_out_valid) begin
                if (g_out_word < 8) begin
                    rho[g_out_word * 4] <= g_out_data[7 : 0];
                    rho[g_out_word * 4 + 1] <= g_out_data[15 : 8];
                    rho[g_out_word * 4 + 2] <= g_out_data[23 : 16];
                    rho[g_out_word * 4 + 3] <= g_out_data[31 : 24];
                end else begin
                    sigma[(g_out_word - 8) * 4] <= g_out_data[7 : 0];
                    sigma[(g_out_word - 8) * 4 + 1] <= g_out_data[15 : 8];
                    sigma[(g_out_word - 8) * 4 + 2] <= g_out_data[23 : 16];
                    sigma[(g_out_word - 8) * 4 + 3] <= g_out_data[31 : 24];
                end
                g_out_word <= g_out_word + 1'b1;
            end
            if (noise_valid) begin
                if (state == NOISE_S_WAIT)
                    s[{noise_poly, noise_index}] <= noise_coeff;
                else
                    e[{noise_poly, noise_index}] <= noise_coeff;
            end
            if (ntt_rr)
                linear_d <= {elem, idx};
            if (ntt_rv) begin
                if (ntt_phase)
                    e_hat[linear_d] <= ntt_rc;
                else
                    s_hat[linear_d] <= ntt_rc;
            end
            if (mat_valid)
                a_row[{mat_poly, mat_idx}] <= mat_coeff;
            if (state == BASE_READ)
                linear_d <= {2'b0, idx};
            if (base_rv)
                dot[linear_d[7 : 0]] <= base_rc;
            if (state == ADD_READ)
                linear_d <= {2'b0, idx};
            if (add_rv)
                t_hat[{row, linear_d[7 : 0]}] <= add_rc;
            if (enc_out_valid) begin
                if (enc_phase) begin
                    dk[enc_word * 4] <= enc_out_data[7 : 0];
                    dk[enc_word * 4 + 1] <= enc_out_data[15 : 8];
                    dk[enc_word * 4 + 2] <= enc_out_data[23 : 16];
                    dk[enc_word * 4 + 3] <= enc_out_data[31 : 24];
                end else begin
                    ek[enc_word * 4] <= enc_out_data[7 : 0];
                    ek[enc_word * 4 + 1] <= enc_out_data[15 : 8];
                    ek[enc_word * 4 + 2] <= enc_out_data[23 : 16];
                    ek[enc_word * 4 + 3] <= enc_out_data[31 : 24];
                end
                enc_word <= enc_word + 1'b1;
            end
            if (zeroize_req && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                error <= 0;
                zeroize_busy <= 1;
                child_zeroize_req <= 7'h7f;
                child_done_seen <= 0;
                scrub_addr <= 0;
            end else
                case (state)
                    IDLE:
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            cycle_count <= 0;
                            in_word <= 0;
                            g_operations <= 0;
                            sample_ntt_operations <= 0;
                            noise_operations <= 0;
                            polyvec_ntt_operations <= 0;
                            dot_operations <= 0;
                            poly_add_operations <= 0;
                            state <= INPUT;
                        end
                    INPUT:
                        if (in_valid) begin
                            if (in_keep != 4'hf || in_last != (in_word == 7)) begin
                                error <= 1;
                                busy <= 0;
                                state <= IDLE;
                            end else begin
                                d[in_word * 4] <= in_data[7 : 0];
                                d[in_word * 4 + 1] <= in_data[15 : 8];
                                d[in_word * 4 + 2] <= in_data[23 : 16];
                                d[in_word * 4 + 3] <= in_data[31 : 24];
                                if (in_word == 7)
                                    state <= G_CMD;
                                else
                                    in_word <= in_word + 1'b1;
                            end
                        end
                    G_CMD:
                        if (g_cmd_ready) begin
                            g_in_word <= 0;
                            g_out_word <= 0;
                            g_operations <= g_operations + 1'b1;
                            state <= G_FEED;
                        end
                    G_FEED:
                        if (g_in_ready) begin
                            if (g_in_word == 8)
                                state <= G_WAIT;
                            else
                                g_in_word <= g_in_word + 1'b1;
                        end
                    G_WAIT:
                        if (g_done)
                            state <= NOISE_S_START;
                    NOISE_S_START: begin
                        noise_operations <= noise_operations + 3;
                        state <= NOISE_S_WAIT;
                    end
                    NOISE_S_WAIT:
                        if (noise_done)
                            state <= NOISE_E_START;
                    NOISE_E_START: begin
                        noise_operations <= noise_operations + 3;
                        state <= NOISE_E_WAIT;
                    end
                    NOISE_E_WAIT:
                        if (noise_done) begin
                            ntt_phase <= 0;
                            elem <= 0;
                            idx <= 0;
                            state <= NTT_BEGIN;
                        end
                    NTT_BEGIN: begin
                        idx <= 0;
                        state <= NTT_LOAD;
                    end
                    NTT_LOAD:
                        if (ntt_load_ready) begin
                            if (idx == 255) begin
                                if (elem == 2)
                                    state <= NTT_START;
                                else begin
                                    elem <= elem + 1'b1;
                                    state <= NTT_BEGIN;
                                end
                            end else
                                idx <= idx + 1'b1;
                        end
                    NTT_START: begin
                        polyvec_ntt_operations <= polyvec_ntt_operations + 1'b1;
                        state <= NTT_WAIT;
                    end
                    NTT_WAIT:
                        if (ntt_done) begin
                            elem <= 0;
                            idx <= 0;
                            state <= NTT_READ;
                        end
                    NTT_READ: begin
                        if (idx == 255)
                            state <= NTT_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    end
                    NTT_DRAIN:
                        if (ntt_rv && linear_d[7 : 0] == 255) begin
                            if (elem == 2)
                                state <= NTT_RELEASE;
                            else begin
                                elem <= elem + 1'b1;
                                idx <= 0;
                                state <= NTT_READ;
                            end
                        end
                    NTT_RELEASE:
                        if (!ntt_phase) begin
                            ntt_phase <= 1;
                            elem <= 0;
                            idx <= 0;
                            state <= NTT_BEGIN;
                        end else begin
                            row <= 0;
                            state <= MAT_START;
                        end
                    MAT_START: begin
                        sample_ntt_operations <= sample_ntt_operations + 3;
                        state <= MAT_WAIT;
                    end
                    MAT_WAIT:
                        if (mat_done) begin
                            operand <= 0;
                            elem <= 0;
                            idx <= 0;
                            state <= BASE_BEGIN;
                        end
                    BASE_BEGIN: begin
                        idx <= 0;
                        state <= BASE_LOAD;
                    end
                    BASE_LOAD:
                        if (base_lr) begin
                            if (idx == 255) begin
                                if (elem == 2) begin
                                    if (!operand) begin
                                        operand <= 1;
                                        elem <= 0;
                                        state <= BASE_BEGIN;
                                    end else
                                        state <= BASE_START;
                                end else begin
                                    elem <= elem + 1'b1;
                                    state <= BASE_BEGIN;
                                end
                            end else
                                idx <= idx + 1'b1;
                        end
                    BASE_START: begin
                        dot_operations <= dot_operations + 1'b1;
                        state <= BASE_WAIT;
                    end
                    BASE_WAIT:
                        if (base_done) begin
                            idx <= 0;
                            state <= BASE_READ;
                        end
                    BASE_READ: begin
                        if (idx == 255)
                            state <= BASE_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    end
                    BASE_DRAIN:
                        if (base_rv && linear_d[7 : 0] == 255)
                            state <= BASE_RELEASE;
                    BASE_RELEASE: begin
                        operand <= 0;
                        idx <= 0;
                        state <= ADD_BEGIN;
                    end
                    ADD_BEGIN: begin
                        idx <= 0;
                        state <= ADD_LOAD;
                    end
                    ADD_LOAD:
                        if (add_lr) begin
                            if (idx == 255) begin
                                if (!operand) begin
                                    operand <= 1;
                                    state <= ADD_BEGIN;
                                end else
                                    state <= ADD_START;
                            end else
                                idx <= idx + 1'b1;
                        end
                    ADD_START: begin
                        poly_add_operations <= poly_add_operations + 1'b1;
                        state <= ADD_WAIT;
                    end
                    ADD_WAIT:
                        if (add_done) begin
                            idx <= 0;
                            state <= ADD_READ;
                        end
                    ADD_READ: begin
                        if (idx == 255)
                            state <= ADD_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    end
                    ADD_DRAIN:
                        if (add_rv && linear_d[7 : 0] == 255)
                            state <= ADD_RELEASE;
                    ADD_RELEASE:
                        if (row == 2) begin
                            enc_phase <= 0;
                            enc_word <= 0;
                            linear <= 0;
                            for (j = 0; j < 32; j = j + 1)
                                ek[1152 + j] <= rho[j];
                            state <= ENC_START;
                        end else begin
                            row <= row + 1'b1;
                            state <= MAT_START;
                        end
                    ENC_START: begin
                        linear <= 0;
                        enc_word <= 0;
                        state <= ENC_FEED;
                    end
                    ENC_FEED:
                        if (enc_in_ready) begin
                            if (linear == 767)
                                state <= ENC_WAIT;
                            else
                                linear <= linear + 1'b1;
                        end
                    ENC_WAIT:
                        if (enc_done) begin
                            if (!enc_phase) begin
                                enc_phase <= 1;
                                state <= ENC_START;
                            end else begin
                                out_word <= 0;
                                state <= OUTPUT;
                            end
                        end
                    OUTPUT:
                        if (out_valid && out_ready) begin
                            if (out_word == 583) begin
                                busy <= 0;
                                done <= 1;
                                state <= IDLE;
                            end else
                                out_word <= out_word + 1'b1;
                        end
                    SCRUB: begin
                        if (scrub_addr < 32) begin
                            d[scrub_addr] <= 0;
                            rho[scrub_addr] <= 0;
                            sigma[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 1184)
                            ek[scrub_addr] <= 0;
                        if (scrub_addr < 1152)
                            dk[scrub_addr] <= 0;
                        if (scrub_addr < 768) begin
                            s[scrub_addr] <= 0;
                            e[scrub_addr] <= 0;
                            s_hat[scrub_addr] <= 0;
                            e_hat[scrub_addr] <= 0;
                            a_row[scrub_addr] <= 0;
                            t_hat[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 256)
                            dot[scrub_addr] <= 0;
                        if (scrub_addr == 1183) begin
                            scrub_addr <= 0;
                            state <= WAIT_CHILD_ZERO;
                        end else
                            scrub_addr <= scrub_addr + 1'b1;
                    end
                    WAIT_CHILD_ZERO:
                        if (&(child_done_seen | child_zeroize_done)) begin
                            child_zeroize_req <= 0;
                            child_done_seen <= 0;
                            zeroize_busy <= 0;
                            zeroize_done <= 1;
                            busy <= 0;
                            state <= IDLE;
                        end
                    default:
                        state <= IDLE;
                endcase
        end
    end
endmodule
