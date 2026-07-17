`timescale 1ns / 1ps
// FIPS 203 public encapsulation-key length and modulus check.
/*
 * Module: mlkem_ek_check
 * Status: ACTIVE_RELEASE_PATH
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
module mlkem_ek_check
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        output wire busy,
        input wire in_valid,
        output wire in_ready,
        input wire [31 : 0] in_data,
        input wire [3 : 0] in_keep,
        input wire in_last,
        output reg done,
        output reg error,
        output reg checked_key_valid,
        output reg noncanonical_seen,
        output reg [9 : 0] coefficients_scanned,
        input wire read_req,
        input wire [10 : 0] read_addr,
        output reg read_valid,
        output reg [7 : 0] read_data,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam IDLE = 0, LOAD = 1, SCAN = 2, HOLD = 3;
    reg [1 : 0] state;
    reg [7 : 0] ek[0 : 1183];
    reg [8 : 0] word_count;
    reg [9 : 0] coeff_index;
    reg mismatch;
    reg [10 : 0] scrub_addr;
    wire [10 : 0] scan_bidx = (coeff_index >> 1) * 3;
    reg [11 : 0] raw12;
    integer lane, reset_i;
    assign busy = (state == LOAD) || (state == SCAN) || zeroize_busy;
    assign in_ready = (state == LOAD) && !zeroize_busy;
    always @* begin
        if (!coeff_index[0])
            raw12 = {ek[scan_bidx + 1][3 : 0], ek[scan_bidx]};
        else
            raw12 = {ek[scan_bidx + 2], ek[scan_bidx + 1][7 : 4]};
    end
    always @(posedge clk) begin
        done <= 0;
        read_valid <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            word_count <= 0;
            coeff_index <= 0;
            coefficients_scanned <= 0;
            mismatch <= 0;
            done <= 0;
            error <= 0;
            checked_key_valid <= 0;
            noncanonical_seen <= 0;
            read_valid <= 0;
            read_data <= 0;
            zeroize_busy <= 0;
            scrub_addr <= 0;
        end else if (zeroize && !zeroize_busy) begin
            state <= IDLE;
            checked_key_valid <= 0;
            noncanonical_seen <= 0;
            mismatch <= 0;
            word_count <= 0;
            coeff_index <= 0;
            coefficients_scanned <= 0;
            scrub_addr <= 0;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            ek[scrub_addr] <= 0;
            if (scrub_addr == 1183) begin
                scrub_addr <= 0;
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end else
                scrub_addr <= scrub_addr + 1'b1;
        end else begin
            if (start) begin
                if (state == LOAD || state == SCAN)
                    error <= 1;
                else begin
                    state <= LOAD;
                    word_count <= 0;
                    coeff_index <= 0;
                    coefficients_scanned <= 0;
                    mismatch <= 0;
                    error <= 0;
                    checked_key_valid <= 0;
                    noncanonical_seen <= 0;
                end
            end
            if (in_valid && in_ready) begin
                if (in_keep != 4'hf || in_last != (word_count == 295)) begin
                    state <= HOLD;
                    error <= 1;
                    checked_key_valid <= 0;
                    done <= 1;
                end else begin
                    for (lane = 0; lane < 4; lane = lane + 1)
                        ek[word_count * 4 + lane] <= in_data[lane * 8 +: 8];
                    if (word_count == 295) begin
                        coeff_index <= 0;
                        coefficients_scanned <= 0;
                        state <= SCAN;
                    end else
                        word_count <= word_count + 1'b1;
                end
            end
            if (in_valid && !in_ready && !start)
                error <= 1;
            if (state == SCAN) begin
                coefficients_scanned <= coefficients_scanned + 1'b1;
                if (raw12 >= 3329) begin
                    mismatch <= 1;
                    noncanonical_seen <= 1;
                end
                if (coeff_index == 767) begin
                    checked_key_valid <= !(mismatch || (raw12 >= 3329));
                    done <= 1;
                    state <= HOLD;
                end else
                    coeff_index <= coeff_index + 1'b1;
            end
            if (read_req) begin
                read_valid <= 1;
                if ((state == HOLD) && read_addr < 1184)
                    read_data <= ek[read_addr];
                else begin
                    read_data <= 0;
                    error <= 1;
                end
            end
        end
    end
endmodule
