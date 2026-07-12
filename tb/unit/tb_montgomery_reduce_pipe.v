`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_montgomery_reduce_pipe;

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

    montgomery_reduce_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .a(a),
        .out_valid(out_valid),
        .r(r)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Mathematical equivalence check in the testbench
    function [11:0] get_expected;
        input [31:0] val;
        reg [63:0] temp;
        integer k;
        begin
            // Modulo arithmetic equivalence check:
            // r = val * R^-1 mod q  <=>  r * R = val mod q
            // We search for r in [0, 3328] satisfying this equivalence.
            get_expected = 12'd0;
            for (k = 0; k < 3329; k = k + 1) begin
                temp = k * 65536;
                if ((temp % 3329) == (val % 3329)) begin
                    get_expected = k[11:0];
                end
            end
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
                    $display("ERROR calculation: a=%d got=%d expected=%d",
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
            val_pipe[0] <= 1'b0;
            val_pipe[1] <= 1'b0;
            val_pipe[2] <= 1'b0;
            a_pipe[0]   <= 32'b0;
            a_pipe[1]   <= 32'b0;
            a_pipe[2]   <= 32'b0;
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
        seed = 32'hdeadbeef;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_montgomery_reduce_pipe: starting directed tests");

        // 1. Directed inputs: 0, 1, q-1, q, q+1, (q-1)^2, q*R-1
        in_valid = 1;
        a = 32'd0; @(posedge clk); #1;
        a = 32'd1; @(posedge clk); #1;
        a = 32'd3328; @(posedge clk); #1; // q-1
        a = 32'd3329; @(posedge clk); #1; // q
        a = 32'd3330; @(posedge clk); #1; // q+1
        a = 32'd3328 * 32'd3328; @(posedge clk); #1; // (q-1)^2 = 11,075,584
        a = 32'd3329 * 32'd65536 - 32'd1; @(posedge clk); #1; // q*R-1 = 218,169,343
        in_valid = 0; @(posedge clk); #1;

        // Wait for pipeline to drain
        repeat(5) @(posedge clk); #1;

        // 2. Bubble tests
        $display("INFO tb_montgomery_reduce_pipe: starting bubble tests");
        in_valid = 1; a = 32'd1000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 32'd2000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;
        in_valid = 1; a = 32'd3000; @(posedge clk); #1;
        in_valid = 0; @(posedge clk); #1;

        repeat(5) @(posedge clk); #1;

        // 3. Reset while transactions are pending
        $display("INFO tb_montgomery_reduce_pipe: starting reset test");
        in_valid = 1;
        a = 32'd4000; @(posedge clk); #1;
        a = 32'd5000; @(posedge clk); #1;
        a = 32'd6000; @(posedge clk); #1;
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
        $display("INFO tb_montgomery_reduce_pipe: running 1000 random inputs");
        in_valid = 1;
        for (i = 0; i < 1000; i = i + 1) begin
            // Generate values strictly less than q*R = 218169344
            a = ($random(seed) & 32'h7FFFFFFF) % 32'd218169344;
            @(posedge clk); #1;
        end
        in_valid = 0;
        repeat(5) @(posedge clk); #1;

        #50;
        $display("INFO tb_montgomery_reduce_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0 && pass_count > 0) begin
            $display("PASS tb_montgomery_reduce_pipe");
            $finish;
        end else begin
            $display("FAIL tb_montgomery_reduce_pipe");
            $fatal(1, "Mismatches detected in Montgomery reduction pipeline");
        end
    end

endmodule
