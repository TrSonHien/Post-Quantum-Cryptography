`timescale 1ns/1ps

module tb_intt_scaler_pipe;
    reg clk = 0;
    reg rst_n = 0;
    reg in_valid = 0;
    reg [11:0] in0 = 0;
    reg [11:0] in1 = 0;
    reg [6:0] pair_idx = 0;
    reg last_in = 0;
    wire out_valid;
    wire [11:0] out0, out1;
    wire [6:0] pair_idx_out;
    wire last_out;

    reg [11:0] exp0 [0:3];
    reg [11:0] exp1 [0:3];
    reg [6:0] exp_idx [0:3];
    reg exp_valid [0:3];
    reg exp_last [0:3];
    integer i;
    integer pipe_i;
    integer failures = 0;
    integer checks = 0;

    intt_scaler_pipe dut (.*);
    always #5 clk = ~clk;

    function [11:0] scaled;
        input integer value;
        begin scaled = (value * 3303) % 3329; end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            exp_valid[0] <= 0; exp_valid[1] <= 0;
            exp_valid[2] <= 0; exp_valid[3] <= 0;
        end else begin
            exp_valid[0] <= in_valid;
            exp_valid[1] <= exp_valid[0];
            exp_valid[2] <= exp_valid[1];
            exp_valid[3] <= exp_valid[2];
            if (in_valid) begin
                exp0[0] <= scaled(in0); exp1[0] <= scaled(in1);
                exp_idx[0] <= pair_idx; exp_last[0] <= last_in;
            end
            for (pipe_i = 1; pipe_i < 4; pipe_i = pipe_i + 1) begin
                if (exp_valid[pipe_i-1]) begin
                    exp0[pipe_i] <= exp0[pipe_i-1]; exp1[pipe_i] <= exp1[pipe_i-1];
                    exp_idx[pipe_i] <= exp_idx[pipe_i-1]; exp_last[pipe_i] <= exp_last[pipe_i-1];
                end
            end
        end
    end

    always @(negedge clk) begin
        if (rst_n) begin
            if (out_valid !== exp_valid[3]) begin
                failures = failures + 1;
                $display("VALID_FAIL got=%0b expected=%0b", out_valid, exp_valid[3]);
            end else if (out_valid) begin
                checks = checks + 2;
                if (out0 !== exp0[3] || out1 !== exp1[3] ||
                    pair_idx_out !== exp_idx[3] || last_out !== exp_last[3]) begin
                    failures = failures + 1;
                    $display("SCALER_FAIL idx=%0d got=(%0d,%0d,%0b) expected=(%0d,%0d,%0b)",
                             pair_idx_out, out0, out1, last_out,
                             exp0[3], exp1[3], exp_last[3]);
                end
            end
        end
    end

    task reset_dut;
        begin
            rst_n = 0; in_valid = 0;
            repeat (3) @(negedge clk);
            rst_n = 1;
            repeat (2) @(negedge clk);
        end
    endtask

    task send_pair;
        input integer a;
        input integer b;
        input integer idx;
        input integer is_last;
        begin
            in_valid = 1; in0 = a; in1 = b;
            pair_idx = idx; last_in = is_last;
            @(negedge clk);
        end
    endtask

    initial begin
        reset_dut();
        send_pair(0, 1, 0, 0);
        send_pair(3328, 512, 1, 0);
        send_pair(1441, 17, 2, 1);
        in_valid = 0; repeat (6) @(negedge clk);

        // Exhaust all canonical values across both lanes at II=1.
        for (i = 0; i < 3329; i = i + 2)
            send_pair(i, (i + 1 < 3329) ? i + 1 : 0, (i >> 1) & 127,
                      (i + 2 >= 3329));
        in_valid = 0; repeat (6) @(negedge clk);
        $display("INFO scaler checks_before_reset=%0d failures=%0d", checks, failures);

        // Reset flushes valid transactions without requiring payload reset.
        send_pair(123, 456, 7, 1);
        rst_n = 0; in_valid = 0; @(negedge clk); rst_n = 1;
        repeat (6) @(negedge clk);
        if (out_valid) failures = failures + 1;

        if (failures == 0 && checks == 3336) begin
            $display("PASS tb_intt_scaler_pipe latency=4 coefficient_checks=%0d", checks);
            $finish;
        end
        $fatal(1, "FAIL tb_intt_scaler_pipe failures=%0d checks=%0d", failures, checks);
    end

    initial begin
        repeat (5000) @(posedge clk);
        $fatal(1, "WATCHDOG tb_intt_scaler_pipe checks=%0d failures=%0d", checks, failures);
    end
endmodule
