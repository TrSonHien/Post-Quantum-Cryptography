`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_intt_butterfly_pipe;

    reg         clk;
    reg         rst_n;
    reg         in_valid;
    reg  [11:0] u;
    reg  [11:0] v;
    reg  [11:0] zeta_mont;
    wire        out_valid;
    wire [11:0] out0;
    wire [11:0] out1;

    // Pipeline tracking (5-cycle latency)
    reg         val_pipe  [0:4];
    reg  [11:0] u_pipe    [0:4];
    reg  [11:0] v_pipe    [0:4];
    reg  [11:0] zeta_pipe [0:4];

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;

    reg [11:0] sum_expected;
    reg [11:0] diff_expected;
    reg [11:0] out1_expected;

    intt_butterfly_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .u(u),
        .v(v),
        .zeta_mont(zeta_mont),
        .out_valid(out_valid),
        .out0(out0),
        .out1(out1)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Expected functional model
    // sum_expected  = (u + v) % 3329
    // diff_expected = (v + 3329 - u) % 3329
    // out1_expected = (zeta_mont * diff_expected * 169) % 3329
    function [11:0] get_expected_sum;
        input [11:0] val_u;
        input [11:0] val_v;
        reg [12:0] temp;
        begin
            temp = val_u + val_v;
            get_expected_sum = temp % 3329;
        end
    endfunction

    function [11:0] get_expected_diff;
        input [11:0] val_u;
        input [11:0] val_v;
        reg [12:0] temp;
        begin
            if (val_v >= val_u) begin
                get_expected_diff = val_v - val_u;
            end else begin
                temp = val_v + 13'd3329 - val_u;
                get_expected_diff = temp % 3329;
            end
        end
    endfunction

    function [11:0] get_expected_prod;
        input [11:0] z;
        input [11:0] d;
        reg [63:0] temp;
        begin
            temp = z * d;
            temp = temp * 169;
            get_expected_prod = temp % 3329;
        end
    endfunction

    // Checker running on negedge clk to verify outputs 5 cycles later
    always @(negedge clk) begin
        if (rst_n) begin
            // Check valid/data alignment
            if (out_valid !== val_pipe[4]) begin
                fail_count = fail_count + 1;
                $display("ERROR alignment: out_valid=%b expected=%b", out_valid, val_pipe[4]);
            end else if (out_valid) begin
                // Check range boundaries
                if (out0 >= 12'd3329 || out1 >= 12'd3329) begin
                    fail_count = fail_count + 1;
                    $display("ERROR canonical range: out0=%d out1=%d must be < 3329", out0, out1);
                end
                
                // Compare calculation results
                sum_expected  = get_expected_sum(u_pipe[4], v_pipe[4]);
                diff_expected = get_expected_diff(u_pipe[4], v_pipe[4]);
                out1_expected = get_expected_prod(zeta_pipe[4], diff_expected);

                if (out0 !== sum_expected) begin
                    fail_count = fail_count + 1;
                    $display("ERROR calculation out0: u=%d v=%d got=%d expected=%d",
                             u_pipe[4], v_pipe[4], out0, sum_expected);
                end else if (out1 !== out1_expected) begin
                    fail_count = fail_count + 1;
                    $display("ERROR calculation out1: u=%d v=%d zeta=%d got=%d expected=%d",
                             u_pipe[4], v_pipe[4], zeta_pipe[4], out1, out1_expected);
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    end

    // Pipeline tracking logic
    always @(posedge clk) begin
        if (!rst_n) begin
            val_pipe[0] <= 1'b0; val_pipe[1] <= 1'b0; val_pipe[2] <= 1'b0; val_pipe[3] <= 1'b0; val_pipe[4] <= 1'b0;
            u_pipe[0]   <= 12'b0; u_pipe[1]   <= 12'b0; u_pipe[2]   <= 12'b0; u_pipe[3]   <= 12'b0; u_pipe[4]   <= 12'b0;
            v_pipe[0]   <= 12'b0; v_pipe[1]   <= 12'b0; v_pipe[2]   <= 12'b0; v_pipe[3]   <= 12'b0; v_pipe[4]   <= 12'b0;
            zeta_pipe[0]<= 12'b0; zeta_pipe[1]<= 12'b0; zeta_pipe[2]<= 12'b0; zeta_pipe[3]<= 12'b0; zeta_pipe[4]<= 12'b0;
        end else begin
            val_pipe[0] <= in_valid;
            val_pipe[1] <= val_pipe[0];
            val_pipe[2] <= val_pipe[1];
            val_pipe[3] <= val_pipe[2];
            val_pipe[4] <= val_pipe[3];
            
            u_pipe[0]   <= u;
            u_pipe[1]   <= u_pipe[0];
            u_pipe[2]   <= u_pipe[1];
            u_pipe[3]   <= u_pipe[2];
            u_pipe[4]   <= u_pipe[3];

            v_pipe[0]   <= v;
            v_pipe[1]   <= v_pipe[0];
            v_pipe[2]   <= v_pipe[1];
            v_pipe[3]   <= v_pipe[2];
            v_pipe[4]   <= v_pipe[3];

            zeta_pipe[0]<= zeta_mont;
            zeta_pipe[1]<= zeta_pipe[0];
            zeta_pipe[2]<= zeta_pipe[1];
            zeta_pipe[3]<= zeta_pipe[2];
            zeta_pipe[4]<= zeta_pipe[3];
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        u = 0;
        v = 0;
        zeta_mont = 0;
        pass_count = 0;
        fail_count = 0;
        seed = 32'hdeadbeef;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_intt_butterfly_pipe: starting directed tests");

        // 1. Directed inputs (using actual zetas from rom: 1701, 1807, 1460)
        in_valid = 1;
        u = 0; v = 0; zeta_mont = 1701; @(posedge clk); #1;
        u = 1; v = 1; zeta_mont = 1701; @(posedge clk); #1;
        u = 3328; v = 3328; zeta_mont = 1807; @(posedge clk); #1;
        u = 1000; v = 2000; zeta_mont = 1460; @(posedge clk); #1;
        u = 2000; v = 1000; zeta_mont = 1460; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        repeat(7) @(posedge clk); #1;

        // 2. Bubble tests
        $display("INFO tb_intt_butterfly_pipe: starting bubble tests");
        in_valid = 1; u = 100; v = 200; zeta_mont = 1701; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; u = 300; v = 400; zeta_mont = 1807; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        repeat(7) @(posedge clk); #1;

        // 3. Reset while transactions are pending
        $display("INFO tb_intt_butterfly_pipe: starting reset test");
        in_valid = 1;
        u = 10; v = 20; zeta_mont = 1701; @(posedge clk); #1;
        u = 30; v = 40; zeta_mont = 1807; @(posedge clk); #1;
        u = 50; v = 60; zeta_mont = 1460; @(posedge clk); #1;
        rst_n = 0; // Trigger reset
        @(posedge clk); #1;
        // Verify valid pipeline is flushed
        if (out_valid !== 1'b0 || val_pipe[0] !== 1'b0) begin
            fail_count = fail_count + 1;
            $display("ERROR reset: pipeline valids not cleared immediately");
        end
        rst_n = 1;
        in_valid = 0;
        repeat(7) @(posedge clk); #1;

        // 4. Deterministic random tests
        $display("INFO tb_intt_butterfly_pipe: running 2000 random inputs");
        in_valid = 1;
        for (i = 0; i < 2000; i = i + 1) begin
            u = ($random(seed) & 32'h7FFFFFFF) % 3329;
            v = ($random(seed) & 32'h7FFFFFFF) % 3329;
            zeta_mont = ($random(seed) & 32'h7FFFFFFF) % 3329;
            @(posedge clk); #1;
        end
        in_valid = 0;
        repeat(7) @(posedge clk); #1;

        #50;
        $display("INFO tb_intt_butterfly_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0 && pass_count > 0) begin
            $display("PASS tb_intt_butterfly_pipe");
            $finish;
        end else begin
            $display("FAIL tb_intt_butterfly_pipe");
            $fatal(1, "Mismatches detected in Inverse NTT butterfly pipeline");
        end
    end

endmodule
