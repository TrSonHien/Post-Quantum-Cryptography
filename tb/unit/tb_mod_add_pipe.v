`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_mod_add_pipe;

    reg         clk;
    reg         rst_n;
    reg         in_valid;
    reg  [11:0] a;
    reg  [11:0] b;
    wire        out_valid;
    wire [11:0] r;

    // Track input pipeline for checking
    reg         pipe_valid;
    reg  [11:0] pipe_a;
    reg  [11:0] pipe_b;

    integer pass_count;
    integer fail_count;
    integer i, j;
    integer seed;

    mod_add_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .a(a),
        .b(b),
        .out_valid(out_valid),
        .r(r)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Expected functional model
    function [11:0] expected_add;
        input [11:0] x;
        input [11:0] y;
        reg [12:0] sum;
        begin
            sum = {1'b0, x} + {1'b0, y};
            if (sum >= 13'd3329) begin
                expected_add = sum - 13'd3329;
            end else begin
                expected_add = sum[11:0];
            end
        end
    endfunction

    // Checker task that runs at negedge to verify outputs from the previous posedge
    always @(negedge clk) begin
        if (rst_n) begin
            // Verify alignment
            if (out_valid !== pipe_valid) begin
                fail_count = fail_count + 1;
                $display("ERROR alignment: out_valid=%b expected=%b", out_valid, pipe_valid);
            end else if (out_valid) begin
                if (r !== expected_add(pipe_a, pipe_b)) begin
                    fail_count = fail_count + 1;
                    $display("ERROR calculation: a=%d b=%d got=%d expected=%d",
                             pipe_a, pipe_b, r, expected_add(pipe_a, pipe_b));
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    end

    // Pipeline driver
    always @(posedge clk) begin
        if (!rst_n) begin
            pipe_valid <= 1'b0;
            pipe_a     <= 12'b0;
            pipe_b     <= 12'b0;
        end else begin
            pipe_valid <= in_valid;
            pipe_a     <= a;
            pipe_b     <= b;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        a = 0;
        b = 0;
        pass_count = 0;
        fail_count = 0;
        seed = 32'h12345678;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_mod_add_pipe: starting directed tests");

        // 1. Basic directed testcases
        in_valid = 1;
        a = 0; b = 0; @(posedge clk); #1;
        a = 0; b = 3328; @(posedge clk); #1;
        a = 3328; b = 0; @(posedge clk); #1;
        a = 3328; b = 3328; @(posedge clk); #1; // crossing q
        a = 1664; b = 1665; @(posedge clk); #1; // exact q
        a = 100; b = 200; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        // 2. Bubble test
        in_valid = 1; a = 10; b = 20; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 30; b = 40; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        // 3. Reset test with pending valid data
        in_valid = 1; a = 50; b = 60; @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        // Verify out_valid is cleared on reset
        if (out_valid !== 1'b0) begin
            fail_count = fail_count + 1;
            $display("ERROR reset: out_valid not cleared immediately");
        end
        rst_n = 1;
        in_valid = 0;
        @(posedge clk); #1;

        // 4. Exhaustive stepped test over [0, q-1]
        $display("INFO tb_mod_add_pipe: running exhaustive stepped test");
        in_valid = 1;
        for (i = 0; i < 3329; i = i + 7) begin
            for (j = 0; j < 3329; j = j + 11) begin
                a = i;
                b = j;
                @(posedge clk); #1;
            end
        end
        in_valid = 0;
        @(posedge clk); #1;

        // 5. Random test for additional coverage
        $display("INFO tb_mod_add_pipe: running random tests");
        in_valid = 1;
        for (i = 0; i < 5000; i = i + 1) begin
            a = $random(seed) % 3329;
            b = $random(seed) % 3329;
            @(posedge clk); #1;
        end
        in_valid = 0;
        @(posedge clk); #1;

        #50;
        $display("INFO tb_mod_add_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0 && pass_count > 0) begin
            $display("PASS tb_mod_add_pipe");
            $finish;
        end else begin
            $display("FAIL tb_mod_add_pipe");
            $fatal(1, "Mismatches found in modular addition pipeline");
        end
    end

endmodule
