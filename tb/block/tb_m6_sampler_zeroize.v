`timescale 1ns/1ps

// Retained sampler zeroize check for active release sampler modules only.
module tb_m6_sampler_zeroize;
    reg clk = 0, rst_n = 0;
    reg z_cbd = 0, z_parser = 0, z_noise = 0, z_ntt = 0;
    wire zb_cbd, zd_cbd, zb_parser, zd_parser, zb_noise, zd_noise, zb_ntt, zd_ntt;
    reg [3:0] seen_done = 0;
    integer checks = 0;

    always #5 clk = ~clk;
    always @(posedge clk)
        if (!rst_n)
            seen_done <= 0;
        else
            seen_done <= seen_done | {zd_ntt, zd_noise, zd_parser, zd_cbd};

    wire cbd_busy, cbd_done, cbd_err, cbd_ir, cbd_ov;
    wire [11:0] cbd_oc;
    wire [7:0] cbd_oi;
    wire [1:0] cbd_dom;
    sample_poly_cbd_pipe cbd(
        clk, rst_n, 1'b0, 2'd2, cbd_busy, cbd_done, cbd_err, 1'b0, cbd_ir,
        32'd0, 4'hf, 1'b0, cbd_ov, 1'b0, cbd_oc, cbd_oi, cbd_dom,
        z_cbd, zb_cbd, zd_cbd);

    wire p_busy, p_done, p_err, p_ir, p_ov;
    wire [11:0] p_oc;
    wire [7:0] p_oi;
    wire [1:0] p_dom;
    wire [31:0] p_g, p_a, p_r;
    sample_ntt_parser parser(
        clk, rst_n, 1'b0, p_busy, p_done, p_err, 1'b0, p_ir, 24'd0, p_ov,
        1'b0, p_oc, p_oi, p_dom, p_g, p_a, p_r, z_parser, zb_parser, zd_parser);

    wire n_busy, n_done, n_err, n_ov;
    wire [11:0] n_oc;
    wire [7:0] n_oi;
    wire [1:0] n_dom;
    mlkem_noise_sampler noise(
        clk, rst_n, 1'b0, 256'd0, 8'd0, 2'd2, n_busy, n_done, n_err, n_ov,
        1'b0, n_oc, n_oi, n_dom, z_noise, zb_noise, zd_noise);

    wire s_busy, s_done, s_err, s_ov;
    wire [11:0] s_oc;
    wire [7:0] s_oi;
    wire [1:0] s_dom;
    wire [31:0] s_g, s_a, s_r;
    mlkem_sample_ntt sntt(
        clk, rst_n, 1'b0, 256'd0, 8'd0, 8'd0, 1'b0, 272'd0, s_busy, s_done,
        s_err, s_ov, 1'b0, s_oc, s_oi, s_dom, s_g, s_a, s_r,
        z_ntt, zb_ntt, zd_ntt);

    task check_value;
        input condition;
        input [255:0] label;
        begin
            checks = checks + 1;
            if (!condition)
                $fatal(1, "sampler zeroize check failed: %0s", label);
        end
    endtask

    task seed_state;
        begin
            cbd.busy = 1; cbd.reservoir = 64'h0123456789abcdef; cbd.out_coeff = 12'h789;
            parser.busy = 1; parser.q0 = 12'habc; parser.q1 = 12'hdef; parser.qcount = 2;
            noise.busy = 1; noise.error = 1; noise.p.seed_reg = {8{32'h89abcdef}};
            noise.c.reservoir = 64'hfedcba9876543210;
            sntt.busy = 1; sntt.error = 1; sntt.req_pending = 1;
            sntt.x.input_reg = {8{34'h2aaaaaaaa}}; sntt.p.q0 = 12'h888;
        end
    endtask

    task check_zero;
        begin
            check_value({cbd.busy, cbd.reservoir, cbd.out_coeff} === 0, "CBD payload");
            check_value({parser.busy, parser.q0, parser.q1, parser.qcount} === 0,
                        "SampleNTT parser");
            check_value({noise.busy, noise.error, noise.p.seed_reg, noise.c.reservoir} === 0,
                        "noise hierarchy");
            check_value({sntt.busy, sntt.error, sntt.req_pending, sntt.x.input_reg,
                         sntt.p.q0} === 0, "SampleNTT hierarchy");
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        seed_state();
        z_cbd = 1; z_parser = 1; z_noise = 1; z_ntt = 1;
        @(negedge clk);
        check_value(zb_cbd && zb_parser && zb_noise && zb_ntt, "all busy");
        z_cbd = 0; z_parser = 0; z_noise = 0; z_ntt = 0;
        while (seen_done != 4'hf) @(negedge clk);
        check_zero();
        seed_state();
        z_noise = 1;
        @(negedge clk);
        rst_n = 0;
        z_noise = 0;
        @(negedge clk);
        check_value(!zb_noise && !zd_noise, "reset invalidates noise scrub");
        $display("PASS tb_m6_sampler_zeroize checks=%0d active_owner_types=4", checks);
        $finish;
    end
endmodule
