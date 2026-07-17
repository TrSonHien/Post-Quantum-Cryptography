`timescale 1ns / 1ps
// Constant-work 1088-byte compare and full-mask 32-byte secret selection.
/*
 * Module: mlkem_ct_compare_select
 * Status: TEST_OR_COMPATIBILITY_ONLY
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_ct_compare_select
    (
        input wire clk,
        input wire rst_n,
        input wire load_start,
        input wire in_valid,
        output wire in_ready,
        input wire [1 : 0] in_kind,
        input wire [7 : 0] in_data,
        input wire in_last,
        input wire start,
        output wire busy,
        output reg done,
        output reg error,
        output wire out_valid,
        input wire out_ready,
        output wire [7 : 0] out_data,
        output wire out_last,
        output reg [10 : 0] compare_count,
        output reg [5 : 0] select_count,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam C = 0, CP = 1, KP = 2, KB = 3;
    localparam IDLE = 0, LOAD = 1, COMPARE = 2, SELECT = 3, AUTO_SCRUB = 4, OUTPUT = 5;
    reg [2 : 0] state;
    reg [7 : 0] c[0 : 1087], cp[0 : 1087], kp[0 : 31], kb[0 : 31], kout[0 : 31];
    reg [10 : 0] load_count, index, scrub_addr;
    reg [1 : 0] expected_kind;
    reg [5 : 0] out_index;
    reg mismatch_acc;
    reg [7 : 0] reject_mask;
    wire [10 : 0] kind_len = (in_kind < 2) ? 1088 : 32;
    assign in_ready = state == LOAD && !zeroize_busy;
    assign busy = (state != IDLE) || zeroize_busy;
    assign out_valid = state == OUTPUT;
    assign out_data = kout[out_index];
    assign out_last = state == OUTPUT && out_index == 31;
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            load_count <= 0;
            index <= 0;
            scrub_addr <= 0;
            expected_kind <= 0;
            out_index <= 0;
            mismatch_acc <= 0;
            reject_mask <= 0;
            compare_count <= 0;
            select_count <= 0;
            done <= 0;
            error <= 0;
            zeroize_busy <= 0;
        end else if (zeroize && !zeroize_busy) begin
            state <= IDLE;
            load_count <= 0;
            index <= 0;
            out_index <= 0;
            mismatch_acc <= 0;
            reject_mask <= 0;
            compare_count <= 0;
            select_count <= 0;
            scrub_addr <= 0;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            c[scrub_addr] <= 0;
            cp[scrub_addr] <= 0;
            if (scrub_addr < 32) begin
                kp[scrub_addr] <= 0;
                kb[scrub_addr] <= 0;
                kout[scrub_addr] <= 0;
            end
            if (scrub_addr == 1087) begin
                scrub_addr <= 0;
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end else
                scrub_addr <= scrub_addr + 1'b1;
        end else begin
            if (load_start) begin
                if (state != IDLE)
                    error <= 1;
                else begin
                    state <= LOAD;
                    load_count <= 0;
                    expected_kind <= 0;
                    error <= 0;
                    compare_count <= 0;
                    select_count <= 0;
                    mismatch_acc <= 0;
                    reject_mask <= 0;
                end
            end
            if (in_valid && in_ready) begin
                if (in_kind != expected_kind || in_last != (load_count == kind_len - 1)) begin
                    state <= IDLE;
                    error <= 1;
                end else begin
                    case (in_kind)
                        C:
                            c[load_count] <= in_data;
                        CP:
                            cp[load_count] <= in_data;
                        KP:
                            kp[load_count] <= in_data;
                        default:
                            kb[load_count] <= in_data;
                    endcase
                    if (load_count == kind_len - 1) begin
                        load_count <= 0;
                        if (expected_kind == KB)
                            state <= IDLE;
                        else
                            expected_kind <= expected_kind + 1'b1;
                    end else
                        load_count <= load_count + 1'b1;
                end
            end
            if (in_valid && !in_ready && !load_start)
                error <= 1;
            if (start) begin
                if (state != IDLE || expected_kind != KB)
                    error <= 1;
                else begin
                    state <= COMPARE;
                    index <= 0;
                    compare_count <= 0;
                    mismatch_acc <= 0;
                end
            end
            case (state)
                COMPARE: begin
                    mismatch_acc <= mismatch_acc | (|(c[index] ^ cp[index]));
                    compare_count <= compare_count + 1'b1;
                    if (index == 1087) begin
                        reject_mask <= (mismatch_acc | (|(c[index] ^ cp[index]))) ? 8'hff : 8'h00;
                        index <= 0;
                        state <= SELECT;
                    end else
                        index <= index + 1'b1;
                end
                SELECT: begin
                    kout[index[5 : 0]] <= (kp[index[5 : 0]] & ~reject_mask) | (kb[index[5 : 0]] & reject_mask);
                    select_count <= select_count + 1'b1;
                    if (index == 31) begin
                        mismatch_acc <= 0;
                        reject_mask <= 0;
                        scrub_addr <= 0;
                        state <= AUTO_SCRUB;
                    end else
                        index <= index + 1'b1;
                end
                AUTO_SCRUB: begin
                    c[scrub_addr] <= 0;
                    cp[scrub_addr] <= 0;
                    if (scrub_addr < 32) begin
                        kp[scrub_addr] <= 0;
                        kb[scrub_addr] <= 0;
                    end
                    if (scrub_addr == 1087) begin
                        scrub_addr <= 0;
                        out_index <= 0;
                        state <= OUTPUT;
                    end else
                        scrub_addr <= scrub_addr + 1'b1;
                end
                OUTPUT:
                    if (out_valid && out_ready) begin
                        kout[out_index] <= 0;
                        if (out_index == 31) begin
                            state <= IDLE;
                            expected_kind <= 0;
                            done <= 1;
                        end else
                            out_index <= out_index + 1'b1;
                    end
            endcase
        end
    end
endmodule
