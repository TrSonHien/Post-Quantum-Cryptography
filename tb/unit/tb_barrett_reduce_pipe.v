`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_barrett_reduce_pipe;

    reg         clk;
    reg         rst_n;
    reg         in_valid;
    reg  [31:0] a;
    wire        out_valid;
    wire [11:0] r;

    // Shift registers to track input pipeline for checking (3-cycle latency)
    reg         val_pipe [0:2];
    reg  [31:0] a_pipe   [0:2];

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;

    barrett_reduce_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .a(a),
        .out_valid(out_valid),
        .r(r)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Expected functional model
    function [11:0] get_expected;
        input [31:0] val;
        begin
            get_expected = val % 3329;
        end
    endfunction

    // Checker running on negedge clk to verify outputs 3 cycles later
    always @(negedge clk) begin
        if (rst_n) begin
            // Check valid/data alignment
            if (out_valid !== val_pipe[2]) begin
                fail_count = fail_count + 1;
                $display("ERROR alignment: out_valid=%b expected=%b", out_valid, val_pipe[2]);
            end else if (out_valid) begin
                // Check range boundary
                if (r >= 12'd3329) begin
                    fail_count = fail_count + 1;
                    $display("ERROR canonical: r=%d is not < 3329", r);
                end
                // Check mathematical equivalence
                if (r !== get_expected(a_pipe[2])) begin
                    fail_count = fail_count + 1;
                    $display("ERROR calculation: a=%u got=%d expected=%d",
                             a_pipe[2], r, get_expected(a_pipe[2]));
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    end

    // Pipeline tracking logic
    always @(posedge clk) begin
        if (!rst_n) begin
            val_pipe[0] <= 1'b0; val_pipe[1] <= 1'b0; val_pipe[2] <= 1'b0;
            a_pipe[0]   <= 32'b0; a_pipe[1]   <= 32'b0; a_pipe[2]   <= 32'b0;
        end else begin
            val_pipe[0] <= in_valid;
            val_pipe[1] <= val_pipe[0];
            val_pipe[2] <= val_pipe[1];
            
            a_pipe[0]   <= a;
            a_pipe[1]   <= a_pipe[0];
            a_pipe[2]   <= a_pipe[1];
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        a = 0;
        pass_count = 0;
        fail_count = 0;
        seed = 32'h55aa55aa;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_barrett_reduce_pipe: starting directed tests");

        // 1. Directed inputs: 0, 1, q-1, q, q+1, 2*q-1, 2*q, 16'hFFFF, 32'h7FFF_FFFF, 32'hFFFF_FFFE, 32'hFFFF_FFFF
        in_valid = 1;
        a = 32'd0; @(posedge clk); #1;
        a = 32'd1; @(posedge clk); #1;
        a = 32'd3328; @(posedge clk); #1; // q-1
        a = 32'd3329; @(posedge clk); #1; // q
        a = 32'd3330; @(posedge clk); #1; // q+1
        a = 32'd6657; @(posedge clk); #1; // 2*q-1
        a = 32'd6658; @(posedge clk); #1; // 2*q
        a = 32'hFFFF; @(posedge clk); #1;
        a = 32'h7FFF_FFFF; @(posedge clk); #1;
        a = 32'hFFFF_FFFE; @(posedge clk); #1;
        a = 32'hFFFF_FFFF; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        // Wait for pipeline to drain
        repeat(5) @(posedge clk); #1;

        // 2. Bubble tests
        $display("INFO tb_barrett_reduce_pipe: starting bubble tests");
        in_valid = 1; a = 32'd1000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 32'd4000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 32'h8000_0000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        repeat(5) @(posedge clk); #1;

        // 3. Reset while transactions are pending
        $display("INFO tb_barrett_reduce_pipe: starting reset test");
        in_valid = 1;
        a = 32'd7000; @(posedge clk); #1;
        a = 32'd8000; @(posedge clk); #1;
        a = 32'd9000; @(posedge clk); #1;
        rst_n = 0; // Trigger reset
        @(posedge clk); #1;
        // Verify valid pipeline is flushed
        if (out_valid !== 1'b0 || val_pipe[0] !== 1'b0) begin
            fail_count = fail_count + 1;
            $display("ERROR reset: pipeline valids not cleared immediately");
        end
        rst_n = 1;
        in_valid = 0;
        repeat(5) @(posedge clk); #1;

        // 4. Deterministic random tests
        $display("INFO tb_barrett_reduce_pipe: running 2000 random inputs");
        in_valid = 1;
        for (i = 0; i < 2000; i = i + 1) begin
            // Concatenate random bits to form a full 32-bit unsigned number
            a = {$random(seed), $random(seed)};
            @(posedge clk); #1;
        end
        in_valid = 0;
        repeat(5) @(posedge clk); #1;

        #50;
        $display("INFO tb_barrett_reduce_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0 && pass_count > 0) begin
            $display("PASS tb_barrett_reduce_pipe");
            $finish;
        end else begin
            $display("FAIL tb_barrett_reduce_pipe");
            $fatal(1, "Mismatches detected in Barrett reduction pipeline");
        end
    end

endmodule
