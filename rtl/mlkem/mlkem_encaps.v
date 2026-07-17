`timescale 1ns / 1ps
// Public FIPS 203 Algorithm 20: checked EK, then fresh external m.
/*
 * Module: mlkem_encaps
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: mlkem_ek_check, mlkem_encaps_internal.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_encaps
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
        output wire rng_req_valid,
        input wire rng_req_ready,
        output wire [15 : 0] rng_req_len_bytes,
        input wire rng_data_valid,
        output wire rng_data_ready,
        input wire [31 : 0] rng_data,
        input wire [3 : 0] rng_keep,
        input wire rng_last,
        input wire rng_fail,
        output wire out_valid,
        input wire out_ready,
        output wire [31 : 0] out_data,
        output wire [3 : 0] out_keep,
        output wire out_last,
        output wire out_kind,
        output reg busy,
        output reg done,
        output reg error,
        input wire zeroize_req,
        output wire zeroize_busy,
        output reg zeroize_done);
    localparam IDLE = 0, LOAD = 1, CWAIT = 2, CZ = 3, CZW = 4, RREQ = 5, RDATA = 6, I_CMD = 7, I_FEED = 8, I_WAIT = 9, SCRUB = 10, SCRUB_WAIT = 11;
    reg [3 : 0] state;
    reg [7 : 0] ek[0 : 1183], m[0 : 31];
    reg [8 : 0] word_count;
    reg [10 : 0] scrub_addr;
    reg check_pass, explicit_scrub;
    reg [1 : 0] child_zeroize_req, child_zeroized;
    integer lane, reset_i;
    wire cbusy, crdy, cdone, cerror, cvalid, cnc, crv, czb, czd;
    wire [9 : 0] cscan;
    wire [7 : 0] crdata;
    wire icr, iir, iov, iol, iok, ib, id, ie, izb, izd;
    wire [31 : 0] iod, icy;
    wire [3 : 0] iokeep;
    assign zeroize_busy = explicit_scrub && ((state == SCRUB) || (state == SCRUB_WAIT));
    assign cmd_ready = state == IDLE && !zeroize_req;
    assign in_ready = state == LOAD && crdy && !zeroize_req;
    assign rng_req_valid = state == RREQ && !zeroize_req;
    assign rng_req_len_bytes = 32;
    assign rng_data_ready = state == RDATA && !zeroize_req;
    assign out_valid = state == I_WAIT && iov;
    assign out_data = iod;
    assign out_keep = iokeep;
    assign out_last = iol;
    assign out_kind = iok;
    mlkem_ek_check chk(clk,
                       rst_n,
                       cmd_valid && cmd_ready,
                       cbusy,
                       in_valid && state == LOAD,
                       crdy,
                       in_data,
                       in_keep,
                       in_last,
                       cdone,
                       cerror,
                       cvalid,
                       cnc,
                       cscan,
                       1'b0,
                       11'd0,
                       crv,
                       crdata,
                       (state == CZ) || child_zeroize_req[0],
                       czb,
                       czd);
    wire [31 : 0] ifeed = word_count < 296 ? {ek[word_count * 4 + 3], ek[word_count * 4 + 2], ek[word_count * 4 + 1], ek[word_count * 4]} : {m[(word_count - 296) * 4 + 3], m[(word_count - 296) * 4 + 2], m[(word_count - 296) * 4 + 1], m[(word_count - 296) * 4]};
    mlkem_encaps_internal core(clk,
                               rst_n,
                               state == I_CMD,
                               icr,
                               state == I_FEED,
                               iir,
                               ifeed,
                               4'hf,
                               word_count == 303,
                               iov,
                               state == I_WAIT && out_ready,
                               iod,
                               iokeep,
                               iol,
                               iok,
                               ib,
                               id,
                               ie,
                               icy,
                               child_zeroize_req[1],
                               izb,
                               izd);
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            word_count <= 0;
            scrub_addr <= 0;
            check_pass <= 0;
            explicit_scrub <= 0;
            child_zeroize_req <= 0;
            child_zeroized <= 0;
            zeroize_done <= 0;
        end else begin
            if (czd && state != CZW) begin
                child_zeroized[0] <= 1;
                child_zeroize_req[0] <= 0;
            end
            if (izd) begin
                child_zeroized[1] <= 1;
                child_zeroize_req[1] <= 0;
            end
            if ((zeroize_req === 1'b1) && !zeroize_busy) begin
                state <= SCRUB;
                busy <= 1;
                done <= 0;
                error <= 0;
                word_count <= 0;
                scrub_addr <= 0;
                check_pass <= 0;
                explicit_scrub <= 1;
                child_zeroize_req <= 2'b11;
                child_zeroized <= 0;
            end else
                case (state)
                    IDLE:
                        if (cmd_valid) begin
                            busy <= 1;
                            error <= 0;
                            word_count <= 0;
                            explicit_scrub <= 0;
                            state <= LOAD;
                        end
                    LOAD:
                        if (in_valid && in_ready) begin
                            for (lane = 0; lane < 4; lane = lane + 1)
                                ek[word_count * 4 + lane] <= in_data[lane * 8 +: 8];
                            if (word_count == 295)
                                state <= CWAIT;
                            else
                                word_count <= word_count + 1;
                        end
                    CWAIT:
                        if (cdone) begin
                            check_pass <= cvalid && !cerror;
                            state <= CZ;
                        end
                    CZ:
                        state <= CZW;
                    CZW:
                        if (czd) begin
                            if (check_pass)
                                state <= RREQ;
                            else begin
                                error <= 1;
                                scrub_addr <= 0;
                                child_zeroize_req <= 2'b11;
                                child_zeroized <= 0;
                                state <= SCRUB;
                            end
                        end
                    RREQ:
                        if (rng_fail) begin
                            error <= 1;
                            scrub_addr <= 0;
                            child_zeroize_req <= 2'b11;
                            child_zeroized <= 0;
                            state <= SCRUB;
                        end else if (rng_req_ready) begin
                            word_count <= 0;
                            state <= RDATA;
                        end
                    RDATA:
                        if (rng_fail) begin
                            error <= 1;
                            scrub_addr <= 0;
                            child_zeroize_req <= 2'b11;
                            child_zeroized <= 0;
                            state <= SCRUB;
                        end else if (rng_data_valid) begin
                            if (rng_keep != 4'hf || rng_last != (word_count == 7)) begin
                                error <= 1;
                                scrub_addr <= 0;
                                child_zeroize_req <= 2'b11;
                                child_zeroized <= 0;
                                state <= SCRUB;
                            end else begin
                                for (lane = 0; lane < 4; lane = lane + 1)
                                    m[word_count * 4 + lane] <= rng_data[lane * 8 +: 8];
                                if (word_count == 7)
                                    state <= I_CMD;
                                else
                                    word_count <= word_count + 1;
                            end
                        end
                    I_CMD:
                        if (icr) begin
                            word_count <= 0;
                            state <= I_FEED;
                        end
                    I_FEED:
                        if (iir) begin
                            if (word_count == 303)
                                state <= I_WAIT;
                            else
                                word_count <= word_count + 1;
                        end
                    I_WAIT:
                        if (ie) begin
                            error <= 1;
                            scrub_addr <= 0;
                            child_zeroize_req <= 2'b11;
                            child_zeroized <= 0;
                            state <= SCRUB;
                        end else if (id) begin
                            scrub_addr <= 0;
                            child_zeroize_req <= 2'b11;
                            child_zeroized <= 0;
                            state <= SCRUB;
                        end
                    SCRUB: begin
                        ek[scrub_addr] <= 0;
                        if (scrub_addr < 32)
                            m[scrub_addr] <= 0;
                        if (scrub_addr == 1183) begin
                            scrub_addr <= 0;
                            state <= SCRUB_WAIT;
                        end else
                            scrub_addr <= scrub_addr + 1;
                    end
                    SCRUB_WAIT:
                        if (&(child_zeroized | {izd, czd})) begin
                            busy <= 0;
                            if (explicit_scrub)
                                zeroize_done <= 1;
                            else
                                done <= 1;
                            explicit_scrub <= 0;
                            child_zeroize_req <= 0;
                            child_zeroized <= 0;
                            word_count <= 0;
                            check_pass <= 0;
                            state <= IDLE;
                        end
                endcase
        end
    end
endmodule
