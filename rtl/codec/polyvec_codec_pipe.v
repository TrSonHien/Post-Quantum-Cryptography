`timescale 1ns / 1ps
// One-child serialized K=3 codec. ENCODE=1 selects coefficient-to-byte flow.
/*
 * Module: polyvec_codec_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Byte/bit, coefficient, or K-PKE record codec adapter.
 * Standard role: FIPS 203 encoding/decoding support.
 * Input representation: LSB-first coefficient bits, byte stream, or seed as named by ports.
 * Output representation: canonical coefficient, NTT coefficient, or byte stream as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module polyvec_codec_pipe
    #(parameter integer D = 12,
      parameter integer ENCODE = 1,
      parameter integer COMPRESS = 0)
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [1 : 0] domain,
        output reg busy,
        output reg done,
        output reg error,
        input wire coeff_in_valid,
        output wire coeff_in_ready,
        input wire [11 : 0] coeff_in,
        input wire byte_in_valid,
        output wire byte_in_ready,
        input wire [31 : 0] byte_in_data,
        input wire [3 : 0] byte_in_keep,
        input wire byte_in_last,
        output wire byte_out_valid,
        input wire byte_out_ready,
        output wire [31 : 0] byte_out_data,
        output wire [3 : 0] byte_out_keep,
        output wire byte_out_last,
        output wire coeff_out_valid,
        input wire coeff_out_ready,
        output wire [11 : 0] coeff_out,
        output wire [7 : 0] coeff_out_index,
        output wire [1 : 0] coeff_out_domain,
        output reg [1 : 0] poly_index,
        output reg noncanonical_seen,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    reg child_start, child_zeroize_req;
    reg [7 : 0] word_count;
    wire child_zeroize_busy, child_zeroize_done;
    wire cbusy, cdone, cerr, ce_ir, ce_ov, ce_last, cd_ir, cd_ov, cd_nc;
    wire [31 : 0] ce_data;
    wire [3 : 0] ce_keep;
    wire [11 : 0] cd_coeff;
    wire [7 : 0] cd_idx;
    wire [1 : 0] cd_domain;
    generate
        if (ENCODE) begin : ge
            if (COMPRESS)
                poly_compress_encode_pipe #(.D(D))
                    c(clk,
                      rst_n,
                      child_start,
                      domain,
                      cbusy,
                      cdone,
                      cerr,
                      coeff_in_valid && busy,
                      ce_ir,
                      coeff_in,
                      ce_ov,
                      byte_out_ready,
                      ce_data,
                      ce_keep,
                      ce_last,
                      child_zeroize_req,
                      child_zeroize_busy,
                      child_zeroize_done);
            else
                poly_encode12_pipe c(clk,
                                     rst_n,
                                     child_start,
                                     domain,
                                     cbusy,
                                     cdone,
                                     cerr,
                                     coeff_in_valid && busy,
                                     ce_ir,
                                     coeff_in,
                                     ce_ov,
                                     byte_out_ready,
                                     ce_data,
                                     ce_keep,
                                     ce_last,
                                     child_zeroize_req,
                                     child_zeroize_busy,
                                     child_zeroize_done);
        end else begin : gd
            if (COMPRESS)
                poly_decode_decompress_pipe #(.D(D))
                    c(clk,
                      rst_n,
                      child_start,
                      cbusy,
                      cdone,
                      cerr,
                      byte_in_valid && busy,
                      cd_ir,
                      byte_in_data,
                      byte_in_keep,
                      (word_count == 8 * D - 1),
                      cd_ov,
                      coeff_out_ready,
                      cd_coeff,
                      cd_idx,
                      cd_domain,
                      child_zeroize_req,
                      child_zeroize_busy,
                      child_zeroize_done);
            else
                poly_decode12_pipe c(clk,
                                     rst_n,
                                     child_start,
                                     domain,
                                     cbusy,
                                     cdone,
                                     cerr,
                                     byte_in_valid && busy,
                                     cd_ir,
                                     byte_in_data,
                                     byte_in_keep,
                                     (word_count == 8 * D - 1),
                                     cd_ov,
                                     coeff_out_ready,
                                     cd_coeff,
                                     cd_idx,
                                     cd_domain,
                                     cd_nc,
                                     child_zeroize_req,
                                     child_zeroize_busy,
                                     child_zeroize_done);
        end
    endgenerate
    assign coeff_in_ready = ENCODE && busy && !zeroize_busy && ce_ir;
    assign byte_in_ready = !ENCODE && busy && !zeroize_busy && cd_ir;
    assign byte_out_valid = ENCODE && !zeroize_busy && ce_ov;
    assign byte_out_data = zeroize_busy ? 0 : ce_data;
    assign byte_out_keep = zeroize_busy ? 0 : ce_keep;
    assign byte_out_last = !zeroize_busy && ce_last && (poly_index == 2);
    assign coeff_out_valid = !ENCODE && !zeroize_busy && cd_ov;
    assign coeff_out = zeroize_busy ? 0 : cd_coeff;
    assign coeff_out_index = zeroize_busy ? 0 : cd_idx;
    assign coeff_out_domain = zeroize_busy ? 0 : cd_domain;
    always @(posedge clk) begin
        child_start <= 0;
        done <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            busy <= 0;
            error <= 0;
            poly_index <= 0;
            word_count <= 0;
            noncanonical_seen <= 0;
            child_zeroize_req <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            busy <= 0;
            error <= 0;
            poly_index <= 0;
            word_count <= 0;
            noncanonical_seen <= 0;
            child_start <= 0;
            child_zeroize_req <= 1;
            zeroize_busy <= 1;
        end else if (zeroize_busy) begin
            busy <= 0;
            error <= 0;
            poly_index <= 0;
            word_count <= 0;
            noncanonical_seen <= 0;
            if (child_zeroize_done) begin
                child_zeroize_req <= 0;
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end
        end else if (start) begin
            if (busy)
                error <= 1;
            else begin
                busy <= 1;
                error <= 0;
                poly_index <= 0;
                word_count <= 0;
                noncanonical_seen <= 0;
                child_start <= 1;
            end
        end else if (busy) begin
            if (cerr) begin
                error <= 1;
                busy <= 0;
            end
            if (!ENCODE && byte_in_valid && byte_in_ready) begin
                if (byte_in_keep != 4'hf || byte_in_last != ((poly_index == 2) && (word_count == 8 * D - 1))) begin
                    error <= 1;
                    busy <= 0;
                end else if (word_count == 8 * D - 1)
                    word_count <= 0;
                else
                    word_count <= word_count + 1;
            end
            if (!ENCODE && cd_nc)
                noncanonical_seen <= 1;
            if (cdone) begin
                if (poly_index == 2) begin
                    busy <= 0;
                    done <= 1;
                end else begin
                    poly_index <= poly_index + 1;
                    child_start <= 1;
                end
            end
        end
    end
endmodule
