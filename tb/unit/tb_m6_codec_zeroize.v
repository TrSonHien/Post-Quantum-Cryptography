`timescale 1ns/1ps

// Retained codec zeroize check for active release codec modules only.
module tb_m6_codec_zeroize;
    reg clk = 0, rst_n = 0;
    reg z_enc = 0, z_dec = 0, z_fmt = 0, z_pv = 0;
    wire zb_enc, zd_enc, zb_dec, zd_dec, zb_fmt, zd_fmt, zb_pv, zd_pv;
    reg [3:0] seen_done = 0;
    integer checks = 0;

    always #5 clk = ~clk;
    always @(posedge clk)
        if (!rst_n)
            seen_done <= 0;
        else
            seen_done <= seen_done | {zd_pv, zd_fmt, zd_dec, zd_enc};

    reg enc_start = 0;
    wire enc_busy, enc_done, enc_err, enc_ir, enc_ov, enc_last;
    wire [31:0] enc_od;
    wire [3:0] enc_ok;
    byte_encode_poly_pipe #(.D(12)) enc(
        clk, rst_n, enc_start, enc_busy, enc_done, enc_err, 1'b0, enc_ir,
        12'd0, enc_ov, 1'b0, enc_od, enc_ok, enc_last, z_enc, zb_enc, zd_enc);

    reg dec_start = 0;
    wire dec_busy, dec_done, dec_err, dec_ir, dec_ov, dec_nc;
    wire [11:0] dec_val;
    wire [7:0] dec_idx;
    byte_decode_poly_pipe #(.D(12)) dec(
        clk, rst_n, dec_start, dec_busy, dec_done, dec_err, 1'b0, dec_ir,
        32'd0, 4'hf, 1'b0, dec_ov, 1'b0, dec_val, dec_idx, dec_nc,
        z_dec, zb_dec, zd_dec);

    reg fmt_start = 0;
    wire fmt_busy, fmt_done, fmt_err, fmt_ir, fmt_ov, fmt_last, fmt_seg;
    wire [31:0] fmt_od;
    wire [3:0] fmt_ok;
    kpke_format_pipe #(.WORDS(4), .SPLIT_WORDS(2)) fmt(
        clk, rst_n, fmt_start, fmt_busy, fmt_done, fmt_err, 1'b0, fmt_ir,
        32'd0, 4'hf, 1'b0, fmt_ov, 1'b0, fmt_od, fmt_ok, fmt_last, fmt_seg,
        z_fmt, zb_fmt, zd_fmt);

    reg pv_start = 0;
    wire pv_busy, pv_done, pv_err, pv_cir, pv_bir, pv_bov, pv_cov, pv_bl, pv_nc;
    wire [31:0] pv_bd;
    wire [3:0] pv_bk;
    wire [11:0] pv_co;
    wire [7:0] pv_ci;
    wire [1:0] pv_cd, pv_pi;
    polyvec_codec_pipe #(.D(12), .ENCODE(1), .COMPRESS(0)) pv(
        clk, rst_n, pv_start, 2'b10, pv_busy, pv_done, pv_err, 1'b0, pv_cir,
        12'd0, 1'b0, pv_bir, 32'd0, 4'hf, 1'b0, pv_bov, 1'b0, pv_bd, pv_bk,
        pv_bl, pv_cov, 1'b0, pv_co, pv_ci, pv_cd, pv_pi, pv_nc, z_pv, zb_pv,
        zd_pv);

    task check_value;
        input condition;
        input [255:0] label;
        begin
            checks = checks + 1;
            if (!condition)
                $fatal(1, "codec zeroize check failed: %0s", label);
        end
    endtask

    task seed_state;
        begin
            enc.busy = 1; enc.reservoir = 64'h0123456789abcdef; enc.out_valid = 1;
            enc.out_data = 32'h12345678; enc.error = 1;
            dec.busy = 1; dec.reservoir = 64'h89abcdef01234567; dec.out_valid = 1;
            dec.out_value = 12'h321; dec.noncanonical_seen = 1; dec.error = 1;
            fmt.busy = 1; fmt.count = 10'h155; fmt.out_valid = 1;
            fmt.out_data = 32'hcafebabe; fmt.error = 1;
            pv.busy = 1; pv.poly_index = 2; pv.word_count = 8'h5a;
            pv.noncanonical_seen = 1; pv.error = 1; pv.child_start = 1;
        end
    endtask

    task check_zero;
        begin
            check_value({enc.busy, enc.reservoir, enc.out_valid, enc.out_data, enc.error} === 0,
                        "encode payload");
            check_value({dec.busy, dec.reservoir, dec.out_valid, dec.out_value,
                         dec.noncanonical_seen, dec.error} === 0, "decode payload");
            check_value({fmt.busy, fmt.count, fmt.out_valid, fmt.out_data, fmt.error} === 0,
                        "format payload");
            check_value({pv.busy, pv.poly_index, pv.word_count, pv.noncanonical_seen,
                         pv.error, pv.child_start} === 0, "polyvec parent");
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        seed_state();
        z_enc = 1; z_dec = 1; z_fmt = 1; z_pv = 1;
        @(negedge clk);
        check_value(zb_enc && zb_dec && zb_fmt && zb_pv, "busy asserted");
        z_enc = 0; z_dec = 0; z_fmt = 0; z_pv = 0;
        while (seen_done != 4'hf) @(negedge clk);
        check_zero();
        seed_state();
        z_dec = 1;
        @(negedge clk);
        rst_n = 0;
        z_dec = 0;
        @(negedge clk);
        check_value(!zb_dec && !zd_dec, "reset invalidates completion");
        rst_n = 1;
        @(negedge clk);
        z_dec = 1;
        @(negedge clk);
        z_dec = 0;
        while (!zd_dec) @(negedge clk);
        check_value(dec.reservoir === 0, "clean restart after reset");
        $display("PASS tb_m6_codec_zeroize checks=%0d active_owner_types=4", checks);
        $finish;
    end
endmodule
