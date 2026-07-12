`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_mod_mul_pipe;

    reg         clk;
    reg         rst_n;
    reg         in_valid;
    reg  [11:0] a;
    reg  [11:0] b;
    wire        out_valid;
    wire [11:0] r;

    // Shift registers to track input pipeline for checking (4-cycle latency)
    reg         val_pipe [0:3];
    reg  [11:0] a_pipe   [0:3];
    reg  [11:0] b_pipe   [0:3];

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;

    mod_mul_pipe dut (
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
    function [11:0] get_expected;
        input [11:0] x;
        input [11:0] y;
        reg [63:0] temp;
        begin
            // r = x * y * R^-1 mod q, where R^-1 mod q = 169
            temp = x * y;
            temp = temp * 169;
            get_expected = temp % 3329;
        end
    endfunction

    // Checker running on negedge clk to verify outputs 4 cycles later
    always @(negedge clk) begin
        if (rst_n) begin
            // Check valid/data alignment
            if (out_valid !== val_pipe[3]) begin
                fail_count = fail_count + 1;
                $display("ERROR alignment: out_valid=%b expected=%b", out_valid, val_pipe[3]);
            end else if (out_valid) begin
                // Check range boundary
                if (r >= 12'd3329) begin
                    fail_count = fail_count + 1;
                    $display("ERROR canonical: r=%d is not < 3329", r);
                end
                // Check mathematical equivalence
                if (r !== get_expected(a_pipe[3], b_pipe[3])) begin
                    fail_count = fail_count + 1;
                    $display("ERROR calculation: %d * %d got=%d expected=%d",
                             a_pipe[3], b_pipe[3], r, get_expected(a_pipe[3], b_pipe[3]));
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    end

    // Pipeline tracking logic
    always @(posedge clk) begin
        if (!rst_n) begin
            val_pipe[0] <= 1'b0; val_pipe[1] <= 1'b0; val_pipe[2] <= 1'b0; val_pipe[3] <= 1'b0;
            a_pipe[0]   <= 12'b0; a_pipe[1]   <= 12'b0; a_pipe[2]   <= 12'b0; a_pipe[3]   <= 12'b0;
            b_pipe[0]   <= 12'b0; b_pipe[1]   <= 12'b0; b_pipe[2]   <= 12'b0; b_pipe[3]   <= 12'b0;
        end else begin
            val_pipe[0] <= in_valid;
            val_pipe[1] <= val_pipe[0];
            val_pipe[2] <= val_pipe[1];
            val_pipe[3] <= val_pipe[2];
            
            a_pipe[0]   <= a;
            a_pipe[1]   <= a_pipe[0];
            a_pipe[2]   <= a_pipe[1];
            a_pipe[3]   <= a_pipe[2];

            b_pipe[0]   <= b;
            b_pipe[1]   <= b_pipe[0];
            b_pipe[2]   <= b_pipe[1];
            b_pipe[3]   <= b_pipe[2];
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
        seed = 32'ha1b2c3d4;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_mod_mul_pipe: starting directed tests");

        // 1. Directed cases
        in_valid = 1;
        a = 0; b = 0; @(posedge clk); #1;
        a = 0; b = 3328; @(posedge clk); #1;
        a = 1; b = 1; @(posedge clk); #1;
        a = 1; b = 3328; @(posedge clk); #1;
        a = 3328; b = 3328; @(posedge clk); #1;
        a = 1664; b = 1665; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        // Wait for pipeline to drain
        repeat(6) @(posedge clk); #1;

        // 2. Bubble tests
        $display("INFO tb_mod_mul_pipe: starting bubble tests");
        in_valid = 1; a = 100; b = 200; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 300; b = 400; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 500; b = 600; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        repeat(6) @(posedge clk); #1;

        // 3. Reset while transactions are pending
        $display("INFO tb_mod_mul_pipe: starting reset test");
        in_valid = 1;
        a = 1000; b = 1000; @(posedge clk); #1;
        a = 2000; b = 2000; @(posedge clk); #1;
        a = 3000; b = 3000; @(posedge clk); #1;
        rst_n = 0; // Trigger reset
        @(posedge clk); #1;
        // Verify valid pipeline is flushed
        if (out_valid !== 1'b0 || val_pipe[0] !== 1'b0) begin
            fail_count = fail_count + 1;
            $display("ERROR reset: pipeline valids not cleared immediately");
        end
        rst_n = 1;
        in_valid = 0;
        repeat(6) @(posedge clk); #1;

        // 4. Deterministic random tests
        $display("INFO tb_mod_mul_pipe: running 2000 random inputs");
        in_valid = 1;
        for (i = 0; i < 2000; i = i + 1) begin
            a = ($random(seed) & 32'h7FFFFFFF) % 3329;
            b = ($random(seed) & 32'h7FFFFFFF) % 3329;
            @(posedge clk); #1;
        end
        in_valid = 0;
        repeat(6) @(posedge clk); #1;

        #50;
        $display("INFO tb_mod_mul_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0 && pass_count > 0) begin
            $display("PASS tb_mod_mul_pipe");
            $finish;
        end else begin
            $display("FAIL tb_mod_mul_pipe");
            $fatal(1, "Mismatches detected in modular multiplier pipeline");
        end
    end

endmodule
