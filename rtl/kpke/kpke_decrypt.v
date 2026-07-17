`timescale 1ns / 1ps
// Deterministic FIPS 203 Algorithm 15. Input stream is dkPKE || ciphertext.
/*
 * Module: kpke_decrypt
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: K-PKE controller or deterministic matrix/noise orchestration.
 * Standard role: FIPS 203 Algorithms 13--15 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: poly_decode_decompress_pipe, poly_intt_pipe, poly_sub_pipe, poly_to_message_pipe, polyvec_basemul_acc_pipe, polyvec_decode12_pipe, polyvec_decode_decompress10_pipe, polyvec_ntt_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module kpke_decrypt
    (
        input wire clk, rst_n,
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
        output reg busy, done, error,
        output reg noncanonical_seen,
        output reg [31 : 0] cycle_count,
        output reg [3 : 0] polyvec_ntt_operations, dot_operations, intt_operations, poly_sub_operations, message_operations,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam [1 : 0] NORMAL = 1, NTT = 2;
    localparam [5 : 0] IDLE = 0, INPUT = 1, DU_START = 2, DU_FEED = 3, DU_WAIT = 4, DV_START = 5, DV_FEED = 6, DV_WAIT = 7, DK_START = 8, DK_FEED = 9, DK_WAIT = 10,
                       N_BEGIN = 11, N_LOAD = 12, N_START = 13, N_WAIT = 14, N_READ = 15, N_DRAIN = 16, N_RELEASE = 17, B_BEGIN = 18, B_LOAD = 19, B_START = 20, B_WAIT = 21, B_READ = 22, B_DRAIN = 23, B_RELEASE = 24,
                       I_BEGIN = 25, I_LOAD = 26, I_START = 27, I_WAIT = 28, I_READ = 29, I_DRAIN = 30, I_RELEASE = 31, S_BEGIN = 32, S_LOAD = 33, S_START = 34, S_WAIT = 35, S_READ = 36, S_DRAIN = 37, S_RELEASE = 38,
                       MSG_START = 39, MSG_FEED = 40, MSG_WAIT = 41, OUTPUT = 42, SCRUB = 44, WAIT_CHILD_ZERO = 45;
    reg [5 : 0] state;
    reg [7 : 0] dk[0 : 1151], c[0 : 1087], msg[0 : 31];
    reg [11 : 0] u[0 : 767], vp[0 : 255], s_hat[0 : 767], u_hat[0 : 767], dot[0 : 255], product[0 : 255], wpoly[0 : 255];
    reg [9 : 0] word_count, linear, linear_d;
    reg [7 : 0] idx;
    reg [1 : 0] elem;
    reg operand;
    reg [3 : 0] msg_word, out_word;
    integer j;
    reg [10 : 0] scrub_addr;
    wire zeroize_req = (zeroize === 1'b1);
    reg [7 : 0] child_zeroize_req, child_zeroized;
    wire [7 : 0] child_zeroize_busy, child_zeroize_done;
    wire du_start, du_busy, du_done, du_error, du_ready, du_valid;
    wire [11 : 0] du_coeff;
    wire [7 : 0] du_idx;
    wire [1 : 0] du_domain, du_poly;
    wire dv_start, dv_busy, dv_done, dv_error, dv_ready, dv_valid;
    wire [11 : 0] dv_coeff;
    wire [7 : 0] dv_idx;
    wire [1 : 0] dv_domain;
    wire dk_start, dk_busy, dk_done, dk_error, dk_ready, dk_valid, dk_nc;
    wire [11 : 0] dk_coeff;
    wire [7 : 0] dk_idx;
    wire [1 : 0] dk_domain, dk_poly;
    wire n_begin, n_we, n_lr, n_start, n_busy, n_done, n_error, n_rr, n_rv, n_complete;
    wire [11 : 0] n_rc;
    wire [1 : 0] n_rd;
    wire b_begin, b_we, b_lr, b_start, b_busy, b_done, b_error, b_rv, b_complete;
    wire [11 : 0] b_lc, b_rc;
    wire [1 : 0] b_rd;
    wire i_begin, i_we, i_lr, i_start, i_busy, i_done, i_error, i_rv, i_complete;
    wire [11 : 0] i_rc;
    wire [1 : 0] i_rd;
    wire s_begin, s_lr, s_start, s_busy, s_done, s_error, s_rv, s_complete;
    wire [11 : 0] s_rc;
    wire [1 : 0] s_rd;
    wire msg_start, msg_busy, msg_done, msg_error, msg_ready, msg_valid;
    wire [31 : 0] msg_data;
    wire [3 : 0] msg_keep;
    wire msg_last;
    assign cmd_ready = state == IDLE;
    assign in_ready = state == INPUT;
    assign out_valid = state == OUTPUT;
    assign out_keep = 4'hf;
    assign out_last = state == OUTPUT && out_word == 7;
    assign out_data = {msg[out_word * 4 + 3], msg[out_word * 4 + 2], msg[out_word * 4 + 1], msg[out_word * 4]};
    assign du_start = state == DU_START;
    polyvec_decode_decompress10_pipe pdu(clk,
                                         rst_n,
                                         du_start,
                                         du_busy,
                                         du_done,
                                         du_error,
                                         state == DU_FEED,
                                         du_ready,
                                         {c[word_count * 4 + 3], c[word_count * 4 + 2], c[word_count * 4 + 1], c[word_count * 4]},
                                         4'hf,
                                         word_count == 239,
                                         du_valid,
                                         1'b1,
                                         du_coeff,
                                         du_idx,
                                         du_domain,
                                         du_poly,
                                         child_zeroize_req[0],
                                         child_zeroize_busy[0],
                                         child_zeroize_done[0]);
    assign dv_start = state == DV_START;
    poly_decode_decompress_pipe #(.D(4))
        pdv(clk,
            rst_n,
            dv_start,
            dv_busy,
            dv_done,
            dv_error,
            state == DV_FEED,
            dv_ready,
            {c[960 + word_count * 4 + 3], c[960 + word_count * 4 + 2], c[960 + word_count * 4 + 1], c[960 + word_count * 4]},
            4'hf,
            word_count == 31,
            dv_valid,
            1'b1,
            dv_coeff,
            dv_idx,
            dv_domain,
            child_zeroize_req[1],
            child_zeroize_busy[1],
            child_zeroize_done[1]);
    assign dk_start = state == DK_START;
    polyvec_decode12_pipe pdk(clk,
                              rst_n,
                              dk_start,
                              NTT,
                              dk_busy,
                              dk_done,
                              dk_error,
                              state == DK_FEED,
                              dk_ready,
                              {dk[word_count * 4 + 3], dk[word_count * 4 + 2], dk[word_count * 4 + 1], dk[word_count * 4]},
                              4'hf,
                              word_count == 287,
                              dk_valid,
                              1'b1,
                              dk_coeff,
                              dk_idx,
                              dk_domain,
                              dk_poly,
                              dk_nc,
                              child_zeroize_req[2],
                              child_zeroize_busy[2],
                              child_zeroize_done[2]);
    assign n_begin = state == N_BEGIN;
    assign n_we = state == N_LOAD;
    assign n_start = state == N_START;
    assign n_rr = state == N_READ;
    polyvec_ntt_pipe pn(clk,
                        rst_n,
                        n_begin,
                        1'b0,
                        elem,
                        NORMAL,
                        n_we,
                        idx,
                        u[{elem, idx}],
                        n_lr,
                        n_start,
                        n_busy,
                        n_done,
                        n_error,
                        n_rr,
                        elem,
                        idx,
                        n_rv,
                        n_rc,
                        n_rd,
                        n_complete,
                        state == N_RELEASE,
                        child_zeroize_req[3],
                        child_zeroize_busy[3],
                        child_zeroize_done[3]);
    assign b_begin = state == B_BEGIN;
    assign b_we = state == B_LOAD;
    assign b_start = state == B_START;
    assign b_lc = operand ? u_hat[{elem, idx}] : s_hat[{elem, idx}];
    polyvec_basemul_acc_pipe ba(clk,
                                rst_n,
                                b_begin,
                                operand,
                                elem,
                                NTT,
                                b_we,
                                idx,
                                b_lc,
                                b_lr,
                                b_start,
                                b_busy,
                                b_done,
                                b_error,
                                state == B_READ,
                                idx,
                                b_rv,
                                b_rc,
                                b_rd,
                                b_complete,
                                state == B_RELEASE,
                                child_zeroize_req[4],
                                child_zeroize_busy[4],
                                child_zeroize_done[4]);
    assign i_begin = state == I_BEGIN;
    assign i_we = state == I_LOAD;
    assign i_start = state == I_START;
    poly_intt_pipe pi(clk,
                      rst_n,
                      i_begin,
                      NTT,
                      i_we,
                      idx,
                      dot[idx],
                      i_lr,
                      i_start,
                      i_busy,
                      i_done,
                      i_error,
                      state == I_READ,
                      idx,
                      i_rv,
                      i_rc,
                      i_rd,
                      i_complete,
                      state == I_RELEASE,
                      child_zeroize_req[5],
                      child_zeroize_busy[5],
                      child_zeroize_done[5]);
    assign s_begin = state == S_BEGIN;
    assign s_start = state == S_START;
    poly_sub_pipe ps(clk,
                     rst_n,
                     s_begin,
                     operand,
                     NORMAL,
                     state == S_LOAD && !operand,
                     idx,
                     vp[idx],
                     state == S_LOAD && operand,
                     idx,
                     product[idx],
                     s_lr,
                     s_start,
                     s_busy,
                     s_done,
                     s_error,
                     state == S_READ,
                     idx,
                     s_rv,
                     s_rc,
                     s_rd,
                     s_complete,
                     state == S_RELEASE,
                     child_zeroize_req[6],
                     child_zeroize_busy[6],
                     child_zeroize_done[6]);
    assign msg_start = state == MSG_START;
    poly_to_message_pipe pm(clk,
                            rst_n,
                            msg_start,
                            NORMAL,
                            msg_busy,
                            msg_done,
                            msg_error,
                            state == MSG_FEED,
                            msg_ready,
                            wpoly[idx],
                            msg_valid,
                            1'b1,
                            msg_data,
                            msg_keep,
                            msg_last,
                            child_zeroize_req[7],
                            child_zeroize_busy[7],
                            child_zeroize_done[7]);
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            noncanonical_seen <= 0;
            cycle_count <= 0;
            word_count <= 0;
            linear <= 0;
            linear_d <= 0;
            idx <= 0;
            elem <= 0;
            operand <= 0;
            msg_word <= 0;
            out_word <= 0;
            polyvec_ntt_operations <= 0;
            dot_operations <= 0;
            intt_operations <= 0;
            poly_sub_operations <= 0;
            message_operations <= 0;
            scrub_addr <= 0;
            child_zeroize_req <= 0;
            child_zeroized <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
        end else begin
            done <= 0;
            zeroize_done <= 0;
            if (busy)
                cycle_count <= cycle_count + 1;
            if (cmd_valid && !cmd_ready && !zeroize_req)
                error <= 1;
            if (in_valid && !in_ready && !zeroize_busy)
                error <= 1;
            if (du_error || dv_error || dk_error || n_error || b_error || i_error || s_error || msg_error)
                error <= 1;
            if (dk_nc)
                noncanonical_seen <= 1;
            if (du_valid)
                u[{du_poly, du_idx}] <= du_coeff;
            if (dv_valid)
                vp[dv_idx] <= dv_coeff;
            if (dk_valid)
                s_hat[{dk_poly, dk_idx}] <= dk_coeff;
            if (n_rr)
                linear_d <= {elem, idx};
            if (n_rv)
                u_hat[linear_d] <= n_rc;
            if (state == B_READ)
                linear_d <= {2'b0, idx};
            if (b_rv)
                dot[linear_d[7 : 0]] <= b_rc;
            if (state == I_READ)
                linear_d <= {2'b0, idx};
            if (i_rv)
                product[linear_d[7 : 0]] <= i_rc;
            if (state == S_READ)
                linear_d <= {2'b0, idx};
            if (s_rv)
                wpoly[linear_d[7 : 0]] <= s_rc;
            if (msg_valid) begin
                msg[msg_word * 4] <= msg_data[7 : 0];
                msg[msg_word * 4 + 1] <= msg_data[15 : 8];
                msg[msg_word * 4 + 2] <= msg_data[23 : 16];
                msg[msg_word * 4 + 3] <= msg_data[31 : 24];
                msg_word <= msg_word + 1'b1;
            end
            if (zeroize_busy) begin
                child_zeroized <= child_zeroized | child_zeroize_done;
                child_zeroize_req <= child_zeroize_req & ~child_zeroize_done;
            end
            if (zeroize_req && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                done <= 0;
                error <= 0;
                noncanonical_seen <= 0;
                zeroize_busy <= 1;
                child_zeroize_req <= 8'hff;
                child_zeroized <= 0;
                scrub_addr <= 0;
            end else
                case (state)
                    IDLE:
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            noncanonical_seen <= 0;
                            cycle_count <= 0;
                            word_count <= 0;
                            polyvec_ntt_operations <= 0;
                            dot_operations <= 0;
                            intt_operations <= 0;
                            poly_sub_operations <= 0;
                            message_operations <= 0;
                            state <= INPUT;
                        end
                    INPUT:
                        if (in_valid) begin
                            if (in_keep != 4'hf || in_last != (word_count == 559)) begin
                                error <= 1;
                                busy <= 0;
                                state <= IDLE;
                            end else begin
                                if (word_count < 288) begin
                                    dk[word_count * 4] <= in_data[7 : 0];
                                    dk[word_count * 4 + 1] <= in_data[15 : 8];
                                    dk[word_count * 4 + 2] <= in_data[23 : 16];
                                    dk[word_count * 4 + 3] <= in_data[31 : 24];
                                end else begin
                                    c[(word_count - 288) * 4] <= in_data[7 : 0];
                                    c[(word_count - 288) * 4 + 1] <= in_data[15 : 8];
                                    c[(word_count - 288) * 4 + 2] <= in_data[23 : 16];
                                    c[(word_count - 288) * 4 + 3] <= in_data[31 : 24];
                                end
                                if (word_count == 559)
                                    state <= DU_START;
                                else
                                    word_count <= word_count + 1'b1;
                            end
                        end
                    DU_START: begin
                        word_count <= 0;
                        state <= DU_FEED;
                    end
                    DU_FEED:
                        if (du_ready) begin
                            if (word_count == 239)
                                state <= DU_WAIT;
                            else
                                word_count <= word_count + 1'b1;
                        end
                    DU_WAIT:
                        if (du_done)
                            state <= DV_START;
                    DV_START: begin
                        word_count <= 0;
                        state <= DV_FEED;
                    end
                    DV_FEED:
                        if (dv_ready) begin
                            if (word_count == 31)
                                state <= DV_WAIT;
                            else
                                word_count <= word_count + 1'b1;
                        end
                    DV_WAIT:
                        if (dv_done)
                            state <= DK_START;
                    DK_START: begin
                        word_count <= 0;
                        state <= DK_FEED;
                    end
                    DK_FEED:
                        if (dk_ready) begin
                            if (word_count == 287)
                                state <= DK_WAIT;
                            else
                                word_count <= word_count + 1'b1;
                        end
                    DK_WAIT:
                        if (dk_done) begin
                            elem <= 0;
                            idx <= 0;
                            state <= N_BEGIN;
                        end
                    N_BEGIN: begin
                        idx <= 0;
                        state <= N_LOAD;
                    end
                    N_LOAD:
                        if (n_lr) begin
                            if (idx == 255) begin
                                if (elem == 2)
                                    state <= N_START;
                                else begin
                                    elem <= elem + 1'b1;
                                    state <= N_BEGIN;
                                end
                            end else
                                idx <= idx + 1'b1;
                        end
                    N_START: begin
                        polyvec_ntt_operations <= polyvec_ntt_operations + 1;
                        state <= N_WAIT;
                    end
                    N_WAIT:
                        if (n_done) begin
                            elem <= 0;
                            idx <= 0;
                            state <= N_READ;
                        end
                    N_READ:
                        if (idx == 255)
                            state <= N_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    N_DRAIN:
                        if (n_rv && linear_d[7 : 0] == 255) begin
                            if (elem == 2)
                                state <= N_RELEASE;
                            else begin
                                elem <= elem + 1'b1;
                                idx <= 0;
                                state <= N_READ;
                            end
                        end
                    N_RELEASE: begin
                        operand <= 0;
                        elem <= 0;
                        idx <= 0;
                        state <= B_BEGIN;
                    end
                    B_BEGIN: begin
                        idx <= 0;
                        state <= B_LOAD;
                    end
                    B_LOAD:
                        if (b_lr) begin
                            if (idx == 255) begin
                                if (elem == 2) begin
                                    if (!operand) begin
                                        operand <= 1;
                                        elem <= 0;
                                        state <= B_BEGIN;
                                    end else
                                        state <= B_START;
                                end else begin
                                    elem <= elem + 1'b1;
                                    state <= B_BEGIN;
                                end
                            end else
                                idx <= idx + 1'b1;
                        end
                    B_START: begin
                        dot_operations <= dot_operations + 1;
                        state <= B_WAIT;
                    end
                    B_WAIT:
                        if (b_done) begin
                            idx <= 0;
                            state <= B_READ;
                        end
                    B_READ:
                        if (idx == 255)
                            state <= B_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    B_DRAIN:
                        if (b_rv && linear_d[7 : 0] == 255)
                            state <= B_RELEASE;
                    B_RELEASE: begin
                        idx <= 0;
                        state <= I_BEGIN;
                    end
                    I_BEGIN: begin
                        idx <= 0;
                        state <= I_LOAD;
                    end
                    I_LOAD:
                        if (i_lr) begin
                            if (idx == 255)
                                state <= I_START;
                            else
                                idx <= idx + 1'b1;
                        end
                    I_START: begin
                        intt_operations <= intt_operations + 1;
                        state <= I_WAIT;
                    end
                    I_WAIT:
                        if (i_done) begin
                            idx <= 0;
                            state <= I_READ;
                        end
                    I_READ:
                        if (idx == 255)
                            state <= I_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    I_DRAIN:
                        if (i_rv && linear_d[7 : 0] == 255)
                            state <= I_RELEASE;
                    I_RELEASE: begin
                        operand <= 0;
                        idx <= 0;
                        state <= S_BEGIN;
                    end
                    S_BEGIN: begin
                        idx <= 0;
                        state <= S_LOAD;
                    end
                    S_LOAD:
                        if (s_lr) begin
                            if (idx == 255) begin
                                if (!operand) begin
                                    operand <= 1;
                                    state <= S_BEGIN;
                                end else
                                    state <= S_START;
                            end else
                                idx <= idx + 1'b1;
                        end
                    S_START: begin
                        poly_sub_operations <= poly_sub_operations + 1;
                        state <= S_WAIT;
                    end
                    S_WAIT:
                        if (s_done) begin
                            idx <= 0;
                            state <= S_READ;
                        end
                    S_READ:
                        if (idx == 255)
                            state <= S_DRAIN;
                        else
                            idx <= idx + 1'b1;
                    S_DRAIN:
                        if (s_rv && linear_d[7 : 0] == 255)
                            state <= S_RELEASE;
                    S_RELEASE: begin
                        idx <= 0;
                        msg_word <= 0;
                        message_operations <= message_operations + 1;
                        state <= MSG_START;
                    end
                    MSG_START: begin
                        idx <= 0;
                        state <= MSG_FEED;
                    end
                    MSG_FEED:
                        if (msg_ready) begin
                            if (idx == 255)
                                state <= MSG_WAIT;
                            else
                                idx <= idx + 1'b1;
                        end
                    MSG_WAIT:
                        if (msg_done) begin
                            out_word <= 0;
                            state <= OUTPUT;
                        end
                    OUTPUT:
                        if (out_valid && out_ready) begin
                            if (out_word == 7) begin
                                busy <= 0;
                                done <= 1;
                                state <= IDLE;
                            end else
                                out_word <= out_word + 1'b1;
                        end
                    SCRUB: begin
                        if (scrub_addr < 1152)
                            dk[scrub_addr] <= 0;
                        if (scrub_addr < 1088)
                            c[scrub_addr] <= 0;
                        if (scrub_addr < 32)
                            msg[scrub_addr] <= 0;
                        if (scrub_addr < 768) begin
                            u[scrub_addr] <= 0;
                            s_hat[scrub_addr] <= 0;
                            u_hat[scrub_addr] <= 0;
                        end
                        if (scrub_addr < 256) begin
                            vp[scrub_addr] <= 0;
                            dot[scrub_addr] <= 0;
                            product[scrub_addr] <= 0;
                            wpoly[scrub_addr] <= 0;
                        end
                        if (scrub_addr == 1151) begin
                            scrub_addr <= 0;
                            state <= WAIT_CHILD_ZERO;
                        end else
                            scrub_addr <= scrub_addr + 1'b1;
                    end
                    WAIT_CHILD_ZERO: begin
                        word_count <= 0;
                        linear <= 0;
                        linear_d <= 0;
                        idx <= 0;
                        elem <= 0;
                        operand <= 0;
                        msg_word <= 0;
                        out_word <= 0;
                        cycle_count <= 0;
                        polyvec_ntt_operations <= 0;
                        dot_operations <= 0;
                        intt_operations <= 0;
                        poly_sub_operations <= 0;
                        message_operations <= 0;
                        if (&(child_zeroized | child_zeroize_done)) begin
                            child_zeroize_req <= 0;
                            child_zeroized <= 0;
                            zeroize_busy <= 0;
                            zeroize_done <= 1;
                            busy <= 0;
                            state <= IDLE;
                        end
                    end
                    default:
                        state <= IDLE;
                endcase
        end
    end
endmodule
