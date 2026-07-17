`timescale 1ns / 1ps
/*
 * Module: mlkem768_top
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: Unified public ML-KEM-768 command, stream, RNG, and status mux.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mlkem_decaps, mlkem_encaps, mlkem_keygen.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem768_top
    (
        input wire clk,
        input wire rst_n,
        input wire cmd_valid,
        output wire cmd_ready,
        input wire [1 : 0] cmd_mode,
        output wire busy,
        output reg done,
        output reg error,
        input wire in_valid,
        output wire in_ready,
        input wire [31 : 0] in_data,
        input wire [3 : 0] in_keep,
        input wire in_last,
        input wire [1 : 0] in_kind,
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
        output wire [1 : 0] out_kind);
    localparam KEYGEN = 0, ENCAPS = 1, DECAPS = 2, ZEROIZE = 3;
    localparam BOOT_REQ = 0, BOOT_WAIT = 1, IDLE = 2, ACTIVE = 3, ZERO_REQ = 4, ZERO_WAIT = 5;
    reg [2 : 0] state;
    reg [1 : 0] active;
    reg [2 : 0] child_zeroize_req, child_zeroized;
    wire kr, krq, krd, kov, kol, kok, kb, kdone, kerr, kzb, kzd;
    wire [15 : 0] krlen;
    wire [31 : 0] kod;
    wire [3 : 0] kokeep;
    wire er, eir, erq, erd, eov, eol, eok, eb, edone, eerr, ezb, ezd;
    wire [15 : 0] erlen;
    wire [31 : 0] eod;
    wire [3 : 0] eokeep;
    wire dr, dir, dov, dol, db, ddone, derr, dzb, dzd;
    wire [31 : 0] dod;
    wire [3 : 0] dokeep;
    wire [2 : 0] child_zeroize_done = {dzd, ezd, kzd};
    assign cmd_ready = (state == IDLE) || ((state == ACTIVE) && (cmd_mode == ZEROIZE));
    assign busy = (state != IDLE);
    mlkem_keygen kg(clk,
                    rst_n,
                    cmd_valid && cmd_ready && state == IDLE && cmd_mode == KEYGEN,
                    kr,
                    krq,
                    rng_req_ready,
                    krlen,
                    rng_data_valid,
                    krd,
                    rng_data,
                    rng_keep,
                    rng_last,
                    rng_fail,
                    kov,
                    state == ACTIVE && active == KEYGEN && out_ready,
                    kod,
                    kokeep,
                    kol,
                    kok,
                    kb,
                    kdone,
                    kerr,
                    child_zeroize_req[0],
                    kzb,
                    kzd);
    mlkem_encaps en(clk,
                    rst_n,
                    cmd_valid && cmd_ready && state == IDLE && cmd_mode == ENCAPS,
                    er,
                    in_valid && state == ACTIVE && active == ENCAPS,
                    eir,
                    in_data,
                    (in_kind == 0) ? in_keep : 4'b0,
                    in_last,
                    erq,
                    rng_req_ready,
                    erlen,
                    rng_data_valid,
                    erd,
                    rng_data,
                    rng_keep,
                    rng_last,
                    rng_fail,
                    eov,
                    state == ACTIVE && active == ENCAPS && out_ready,
                    eod,
                    eokeep,
                    eol,
                    eok,
                    eb,
                    edone,
                    eerr,
                    child_zeroize_req[1],
                    ezb,
                    ezd);
    mlkem_decaps de(clk,
                    rst_n,
                    cmd_valid && cmd_ready && state == IDLE && cmd_mode == DECAPS,
                    dr,
                    in_valid && state == ACTIVE && active == DECAPS,
                    dir,
                    (in_kind == 2),
                    in_data,
                    ((in_kind == 1) || (in_kind == 2)) ? in_keep : 4'b0,
                    in_last,
                    dov,
                    state == ACTIVE && active == DECAPS && out_ready,
                    dod,
                    dokeep,
                    dol,
                    db,
                    ddone,
                    derr,
                    child_zeroize_req[2],
                    dzb,
                    dzd);
    assign in_ready = state == ACTIVE && active == ENCAPS ? eir : state == ACTIVE && active == DECAPS ? dir
                                                                                                      : 1'b0;
    assign rng_req_valid = state == ACTIVE && active == KEYGEN ? krq : state == ACTIVE && active == ENCAPS ? erq
                                                                                                           : 1'b0;
    assign rng_req_len_bytes = (state == ACTIVE && active == KEYGEN) ? krlen : (state == ACTIVE && active == ENCAPS) ? erlen
                                                                                                                     : 16'd0;
    assign rng_data_ready = state == ACTIVE && active == KEYGEN ? krd : state == ACTIVE && active == ENCAPS ? erd
                                                                                                            : 1'b0;
    assign out_valid = state == ACTIVE && active == KEYGEN ? kov : state == ACTIVE && active == ENCAPS ? eov
                                                               : state == ACTIVE && active == DECAPS   ? dov
                                                                                                       : 1'b0;
    assign out_data = active == KEYGEN ? kod : active == ENCAPS ? eod
                                                                : dod;
    assign out_keep = active == KEYGEN ? kokeep : active == ENCAPS ? eokeep
                                                                   : dokeep;
    assign out_last = active == KEYGEN ? kol : active == ENCAPS ? eol
                                                                : dol;
    assign out_kind = active == KEYGEN ? (kok ? 2'd1 : 2'd0) : active == ENCAPS ? (eok ? 2'd3 : 2'd2)
                                                                                : 2'd2;
    always @(posedge clk) begin
        done <= 0;
        if (!rst_n) begin
            state <= BOOT_REQ;
            active <= 0;
            done <= 0;
            error <= 0;
            child_zeroize_req <= 0;
            child_zeroized <= 0;
        end else
            case (state)
                BOOT_REQ: begin
                    error <= 0;
                    child_zeroize_req <= 3'b111;
                    child_zeroized <= 0;
                    state <= BOOT_WAIT;
                end
                BOOT_WAIT: begin
                    child_zeroize_req <= 0;
                    child_zeroized <= child_zeroized | child_zeroize_done;
                    if (&(child_zeroized | child_zeroize_done)) begin
                        child_zeroized <= 0;
                        state <= IDLE;
                    end
                end
                IDLE:
                    if (cmd_valid) begin
                        error <= 0;
                        if (cmd_mode == ZEROIZE)
                            state <= ZERO_REQ;
                        else begin
                            active <= cmd_mode;
                            state <= ACTIVE;
                        end
                    end
                ACTIVE: begin
                    if (cmd_valid && cmd_mode == ZEROIZE)
                        state <= ZERO_REQ;
                    else if ((active == KEYGEN && kdone) || (active == ENCAPS && edone) || (active == DECAPS && ddone)) begin
                        error <= (active == KEYGEN) ? kerr : (active == ENCAPS) ? eerr
                                                                                : derr;
                        done <= 1;
                        state <= IDLE;
                    end
                end
                ZERO_REQ: begin
                    error <= 0;
                    child_zeroize_req <= 3'b111;
                    child_zeroized <= 0;
                    state <= ZERO_WAIT;
                end
                ZERO_WAIT: begin
                    child_zeroize_req <= 0;
                    child_zeroized <= child_zeroized | child_zeroize_done;
                    if (&(child_zeroized | child_zeroize_done)) begin
                        child_zeroized <= 0;
                        done <= 1;
                        state <= IDLE;
                    end
                end
                default:
                    state <= BOOT_REQ;
            endcase
    end
endmodule
