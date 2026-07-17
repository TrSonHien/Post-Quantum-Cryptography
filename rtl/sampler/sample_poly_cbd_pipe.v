`timescale 1ns / 1ps
/*
 * Module: sample_poly_cbd_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: CBD or SampleNTT stream-to-coefficient sampler.
 * Standard role: FIPS 203 Algorithms 7--8 support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module sample_poly_cbd_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [1 : 0] eta,
        output reg busy,
        output reg done,
        output reg error,
        input wire in_valid,
        output wire in_ready,
        input wire [31 : 0] in_data,
        input wire [3 : 0] in_keep,
        input wire in_last,
        output reg out_valid,
        input wire out_ready,
        output reg [11 : 0] out_coeff,
        output reg [7 : 0] out_index,
        output wire [1 : 0] out_domain,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    reg [1 : 0] eta_reg;
    reg [63 : 0] reservoir;
    reg [6 : 0] bit_count;
    reg [6 : 0] words_in;
    reg [8 : 0] coeff_count;
    reg [2 : 0] x, y;
    integer j;
    wire [6 : 0] expected_words = (eta_reg == 2) ? 32 : 48;
    wire [3 : 0] bits_per = eta_reg << 1;
    assign in_ready = !zeroize_busy && !(zeroize_req === 1'b1) && busy && words_in < expected_words && bit_count <= 32 && (!out_valid || out_ready);
    assign out_domain = 2'b01;
    always @* begin
        x = 0;
        y = 0;
        for (j = 0; j < 3; j = j + 1) begin
            if (j < eta_reg)
                x = x + reservoir[j];
            if (j < eta_reg)
                y = y + reservoir[eta_reg + j];
        end
    end
    always @(posedge clk) begin
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            busy <= 0;
            error <= 0;
            eta_reg <= 0;
            reservoir <= 0;
            bit_count <= 0;
            words_in <= 0;
            coeff_count <= 0;
            out_valid <= 0;
            out_coeff <= 0;
            out_index <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            busy <= 0;
            error <= 0;
            eta_reg <= 0;
            reservoir <= 0;
            bit_count <= 0;
            words_in <= 0;
            coeff_count <= 0;
            out_valid <= 0;
            out_coeff <= 0;
            out_index <= 0;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            busy <= 0;
            error <= 0;
            eta_reg <= 0;
            reservoir <= 0;
            bit_count <= 0;
            words_in <= 0;
            coeff_count <= 0;
            out_valid <= 0;
            out_coeff <= 0;
            out_index <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 1;
        end else if (start) begin
            if (busy)
                error <= 1;
            else if (eta != 2 && eta != 3)
                error <= 1;
            else begin
                busy <= 1;
                error <= 0;
                eta_reg <= eta;
                reservoir <= 0;
                bit_count <= 0;
                words_in <= 0;
                coeff_count <= 0;
                out_valid <= 0;
            end
        end else if (busy) begin
            if (out_valid && out_ready) begin
                if (coeff_count == 256) begin
                    busy <= 0;
                    done <= 1;
                end
                out_valid <= 0;
            end
            if (in_valid && in_ready) begin
                if (in_keep != 4'hf || in_last != (words_in == expected_words - 1)) begin
                    error <= 1;
                    busy <= 0;
                    out_valid <= 0;
                end else begin
                    reservoir <= reservoir | ({32'd0, in_data} << bit_count);
                    bit_count <= bit_count + 32;
                    words_in <= words_in + 1;
                end
            end else if ((!out_valid || out_ready) && bit_count >= bits_per && coeff_count < 256) begin
                out_valid <= 1;
                out_coeff <= (x >= y) ? (x - y) : 3329 - (y - x);
                out_index <= coeff_count[7 : 0];
                coeff_count <= coeff_count + 1;
                reservoir <= reservoir >> bits_per;
                bit_count <= bit_count - bits_per;
            end
        end
    end
endmodule
