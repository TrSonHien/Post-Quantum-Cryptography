`timescale 1ns / 1ps

// Fixed-capacity byte storage with exact stream loading and physical scrub.
// Reset invalidates metadata only; scrub overwrites every payload address.
/*
 * Module: mlkem_byte_buffer
 * Status: WRAPPER_OR_ADAPTER
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
module mlkem_byte_buffer
    #(
        parameter integer CAPACITY = 32,
        parameter integer ADDR_W = 5)
    (
        input wire clk,
        input wire rst_n,
        input wire load_start,
        input wire [31 : 0] load_len_bytes,
        input wire load_valid,
        output wire load_ready,
        input wire [31 : 0] load_data,
        input wire [3 : 0] load_keep,
        input wire load_last,
        output reg complete,
        output reg error,
        input wire read_req,
        input wire [ADDR_W - 1 : 0] read_addr,
        output reg read_valid,
        output reg [7 : 0] read_data,
        input wire zeroize,
        output reg zeroize_busy,
        output reg zeroize_done);
    reg [7 : 0] mem[0 : CAPACITY - 1];
    reg [31 : 0] expected_len;
    reg [31 : 0] write_count;
    reg loading;
    reg [ADDR_W - 1 : 0] scrub_addr;
    integer lane;
    reg [2 : 0] accepted;

    function [2 : 0] keep_count;
        input [3 : 0] keep;
        begin
            case (keep)
                4'b0001:
                    keep_count = 1;
                4'b0011:
                    keep_count = 2;
                4'b0111:
                    keep_count = 3;
                4'b1111:
                    keep_count = 4;
                default:
                    keep_count = 0;
            endcase
        end
    endfunction

    assign load_ready = loading && !zeroize_busy &&
                        (write_count < expected_len);

    always @(posedge clk) begin
        read_valid <= 1'b0;
        zeroize_done <= 1'b0;
        if (!rst_n) begin
            expected_len <= 0;
            write_count <= 0;
            loading <= 0;
            complete <= 0;
            error <= 0;
            read_data <= 0;
            read_valid <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            scrub_addr <= 0;
        end else if (zeroize && !zeroize_busy) begin
            loading <= 0;
            complete <= 0;
            error <= 0;
            write_count <= 0;
            scrub_addr <= 0;
            zeroize_busy <= 1'b1;
        end else if (zeroize_busy) begin
            mem[scrub_addr] <= 8'h00;
            if (scrub_addr == CAPACITY - 1) begin
                scrub_addr <= 0;
                zeroize_busy <= 0;
                zeroize_done <= 1'b1;
            end else begin
                scrub_addr <= scrub_addr + 1'b1;
            end
        end else begin
            if (load_start) begin
                complete <= 0;
                error <= 0;
                write_count <= 0;
                expected_len <= load_len_bytes;
                if (loading || load_len_bytes == 0 || load_len_bytes > CAPACITY) begin
                    loading <= 0;
                    error <= 1'b1;
                end else begin
                    loading <= 1'b1;
                end
            end

            if (load_valid && load_ready) begin
                accepted = keep_count(load_keep);
                if (accepted == 0 || write_count + accepted > expected_len ||
                    load_last != (write_count + accepted == expected_len)) begin
                    loading <= 0;
                    complete <= 0;
                    error <= 1'b1;
                end else begin
                    for (lane = 0; lane < 4; lane = lane + 1)
                        if (lane < accepted)
                            mem[write_count + lane] <= load_data[lane * 8 +: 8];
                    write_count <= write_count + accepted;
                    if (write_count + accepted == expected_len) begin
                        loading <= 0;
                        complete <= 1'b1;
                    end
                end
            end

            if (load_valid && !load_ready && !load_start)
                error <= 1'b1;
            if (read_req) begin
                read_valid <= 1'b1;
                if (complete && read_addr < expected_len)
                    read_data <= mem[read_addr];
                else begin
                    read_data <= 0;
                    error <= 1'b1;
                end
            end
        end
    end
endmodule
