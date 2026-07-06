`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_basemul_unit;

    localparam integer MAX_TX = 600;

    reg clk;
    reg rst_n;
    reg in_valid;

    reg  [`KYBER_Q_WIDTH-1:0] a0;
    reg  [`KYBER_Q_WIDTH-1:0] a1;
    reg  [`KYBER_Q_WIDTH-1:0] b0;
    reg  [`KYBER_Q_WIDTH-1:0] b1;
    reg  [`KYBER_Q_WIDTH-1:0] zeta;
    wire out_valid;
    wire [`KYBER_Q_WIDTH-1:0] r0;
    wire [`KYBER_Q_WIDTH-1:0] r1;

    integer pass_count;
    integer fail_count;
    integer valid_check_count;
    integer first_fail_seen;
    integer tx_count;
    integer cycle_count;
    integer i;
    integer idx;
    integer seed;
    integer rand_a0;
    integer rand_a1;
    integer rand_b0;
    integer rand_b1;
    integer rand_zeta;

    reg pipe_valid0;
    reg pipe_valid1;
    reg pipe_valid2;
    integer pipe_idx0;
    integer pipe_idx1;
    integer pipe_idx2;

    reg [`KYBER_Q_WIDTH-1:0] tx_a0   [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] tx_a1   [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] tx_b0   [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] tx_b1   [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] tx_zeta [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] exp_r0  [0:MAX_TX-1];
    reg [`KYBER_Q_WIDTH-1:0] exp_r1  [0:MAX_TX-1];

    basemul_unit dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .a0        (a0),
        .a1        (a1),
        .b0        (b0),
        .b1        (b1),
        .zeta      (zeta),
        .out_valid (out_valid),
        .r0        (r0),
        .r1        (r1)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function signed [15:0] expected_montgomery_reduce;
        input signed [31:0] x;
        reg signed [31:0] qinv;
        reg signed [15:0] u;
        reg signed [31:0] t;
        begin
            qinv = -3327;
            u = x * qinv;
            t = x - (u * `KYBER_Q);
            expected_montgomery_reduce = t >>> 16;
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] expected_mod_mul;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        reg signed [31:0] product;
        reg signed [15:0] mont_result;
        reg signed [16:0] mont_ext;
        begin
            product = x * y;
            mont_result = expected_montgomery_reduce(product);
            mont_ext = {mont_result[15], mont_result};
            if (mont_ext < 0) begin
                expected_mod_mul = mont_ext + `KYBER_Q;
            end else begin
                expected_mod_mul = mont_ext[`KYBER_Q_WIDTH-1:0];
            end
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] expected_mod_add;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        reg [`KYBER_SUM_WIDTH-1:0] sum;
        begin
            sum = x + y;
            if (sum >= `KYBER_Q) begin
                expected_mod_add = sum - `KYBER_Q;
            end else begin
                expected_mod_add = sum[`KYBER_Q_WIDTH-1:0];
            end
        end
    endfunction

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_basemul_unit: %0s", message);
            end
            $display("ERROR tb_basemul_unit: %0s", message);
        end
    endtask

    task reset_scoreboard;
        begin
            pipe_valid0 = 1'b0;
            pipe_valid1 = 1'b0;
            pipe_valid2 = 1'b0;
            pipe_idx0 = -1;
            pipe_idx1 = -1;
            pipe_idx2 = -1;
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            in_valid = 1'b0;
            a0 = {`KYBER_Q_WIDTH{1'b0}};
            a1 = {`KYBER_Q_WIDTH{1'b0}};
            b0 = {`KYBER_Q_WIDTH{1'b0}};
            b1 = {`KYBER_Q_WIDTH{1'b0}};
            zeta = {`KYBER_Q_WIDTH{1'b0}};
            reset_scoreboard();
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
            if (out_valid !== 1'b0)
                record_fail("out_valid must be low after reset");
            if ((r0 !== 0) || (r1 !== 0))
                record_fail("r0/r1 must reset to zero");
        end
    endtask

    task add_tx;
        input [`KYBER_Q_WIDTH-1:0] a0_val;
        input [`KYBER_Q_WIDTH-1:0] a1_val;
        input [`KYBER_Q_WIDTH-1:0] b0_val;
        input [`KYBER_Q_WIDTH-1:0] b1_val;
        input [`KYBER_Q_WIDTH-1:0] zeta_val;
        reg [`KYBER_Q_WIDTH-1:0] t0;
        reg [`KYBER_Q_WIDTH-1:0] t1;
        reg [`KYBER_Q_WIDTH-1:0] t2;
        reg [`KYBER_Q_WIDTH-1:0] t3;
        reg [`KYBER_Q_WIDTH-1:0] t4;
        begin
            if (tx_count >= MAX_TX) begin
                record_fail("transaction storage overflow");
            end else begin
                tx_a0[tx_count] = a0_val;
                tx_a1[tx_count] = a1_val;
                tx_b0[tx_count] = b0_val;
                tx_b1[tx_count] = b1_val;
                tx_zeta[tx_count] = zeta_val;

                t0 = expected_mod_mul(a1_val, b1_val);
                t1 = expected_mod_mul(t0, zeta_val);
                t2 = expected_mod_mul(a0_val, b0_val);
                exp_r0[tx_count] = expected_mod_add(t1, t2);

                t3 = expected_mod_mul(a0_val, b1_val);
                t4 = expected_mod_mul(a1_val, b0_val);
                exp_r1[tx_count] = expected_mod_add(t3, t4);

                tx_count = tx_count + 1;
            end
        end
    endtask

    task drive_cycle;
        input        valid;
        input integer tx_idx;
        begin
            @(negedge clk);
            in_valid = valid;
            if (valid) begin
                a0 = tx_a0[tx_idx];
                a1 = tx_a1[tx_idx];
                b0 = tx_b0[tx_idx];
                b1 = tx_b1[tx_idx];
                zeta = tx_zeta[tx_idx];
            end else begin
                a0 = {`KYBER_Q_WIDTH{1'b0}};
                a1 = {`KYBER_Q_WIDTH{1'b0}};
                b0 = {`KYBER_Q_WIDTH{1'b0}};
                b1 = {`KYBER_Q_WIDTH{1'b0}};
                zeta = {`KYBER_Q_WIDTH{1'b0}};
            end

            @(posedge clk);
            #1;

            pipe_valid2 = pipe_valid1;
            pipe_idx2 = pipe_idx1;
            pipe_valid1 = pipe_valid0;
            pipe_idx1 = pipe_idx0;
            pipe_valid0 = valid;
            pipe_idx0 = valid ? tx_idx : -1;

            valid_check_count = valid_check_count + 1;
            if (out_valid !== pipe_valid2) begin
                $display("ERROR tb_basemul_unit: cycle=%0d expected_out_valid=%0d actual_out_valid=%0d",
                         cycle_count, pipe_valid2, out_valid);
                record_fail("out_valid latency mismatch");
            end

            if (out_valid) begin
                if ((r0 !== exp_r0[pipe_idx2]) || (r1 !== exp_r1[pipe_idx2])) begin
                    fail_count = fail_count + 1;
                    if (!first_fail_seen) begin
                        first_fail_seen = 1;
                        $display("FIRST_FAIL tb_basemul_unit: tx=%0d a0=%0d a1=%0d b0=%0d b1=%0d zeta=%0d exp_r0=%0d got_r0=%0d exp_r1=%0d got_r1=%0d",
                                 pipe_idx2,
                                 tx_a0[pipe_idx2], tx_a1[pipe_idx2],
                                 tx_b0[pipe_idx2], tx_b1[pipe_idx2],
                                 tx_zeta[pipe_idx2],
                                 exp_r0[pipe_idx2], r0,
                                 exp_r1[pipe_idx2], r1);
                    end
                    $display("ERROR tb_basemul_unit: tx=%0d a0=%0d a1=%0d b0=%0d b1=%0d zeta=%0d exp_r0=%0d got_r0=%0d exp_r1=%0d got_r1=%0d",
                             pipe_idx2,
                             tx_a0[pipe_idx2], tx_a1[pipe_idx2],
                             tx_b0[pipe_idx2], tx_b1[pipe_idx2],
                             tx_zeta[pipe_idx2],
                             exp_r0[pipe_idx2], r0,
                             exp_r1[pipe_idx2], r1);
                end else begin
                    pass_count = pass_count + 1;
                end
            end

            cycle_count = cycle_count + 1;
        end
    endtask

    task flush_pipeline;
        integer j;
        begin
            for (j = 0; j < 4; j = j + 1)
                drive_cycle(1'b0, -1);
        end
    endtask

    task add_random_tx;
        begin
            rand_a0 = $random(seed);
            rand_a1 = $random(seed);
            rand_b0 = $random(seed);
            rand_b1 = $random(seed);
            rand_zeta = $random(seed);
            if (rand_a0 < 0) rand_a0 = -rand_a0;
            if (rand_a1 < 0) rand_a1 = -rand_a1;
            if (rand_b0 < 0) rand_b0 = -rand_b0;
            if (rand_b1 < 0) rand_b1 = -rand_b1;
            if (rand_zeta < 0) rand_zeta = -rand_zeta;
            add_tx(rand_a0 % `KYBER_Q,
                   rand_a1 % `KYBER_Q,
                   rand_b0 % `KYBER_Q,
                   rand_b1 % `KYBER_Q,
                   rand_zeta % `KYBER_Q);
        end
    endtask

    initial begin
        $dumpfile("sim/waves/basemul_unit.vcd");
        $dumpvars(0, tb_basemul_unit);

        pass_count = 0;
        fail_count = 0;
        valid_check_count = 0;
        first_fail_seen = 0;
        tx_count = 0;
        cycle_count = 0;
        seed = 32'h42415345;

        $display("INFO tb_basemul_unit: KYBER_Q=%0d", `KYBER_Q);
        apply_reset();

        // Single valid transaction.
        add_tx(1, 2, 3, 4, 2571);
        drive_cycle(1'b1, tx_count - 1);
        flush_pipeline();

        // Back-to-back valid transactions.
        add_tx(0, 0, 0, 0, 0);
        add_tx(1, 0, 1, 0, 2285);
        add_tx(0, 1, 0, 1, 2285);
        add_tx(123, 456, 789, 1011, 2970);
        add_tx(`KYBER_Q-1, `KYBER_Q-1, `KYBER_Q-1, `KYBER_Q-1, 1812);
        add_tx(3328, 1, 2, 3327, 1493);
        add_tx(17, 31, 43, 59, 1422);
        add_tx(202, 287, 622, 1577, 1855);
        for (i = tx_count - 8; i < tx_count; i = i + 1)
            drive_cycle(1'b1, i);
        flush_pipeline();

        // Valid bubble pattern: 1, 1, 0, 1, 0, 0, 1, 1.
        idx = tx_count;
        add_tx(7, 11, 13, 19, 2004);
        add_tx(23, 29, 37, 41, 264);
        add_tx(53, 61, 67, 71, 383);
        add_tx(73, 79, 83, 89, 2500);
        add_tx(97, 101, 103, 107, 1458);
        drive_cycle(1'b1, idx + 0);
        drive_cycle(1'b1, idx + 1);
        drive_cycle(1'b0, -1);
        drive_cycle(1'b1, idx + 2);
        drive_cycle(1'b0, -1);
        drive_cycle(1'b0, -1);
        drive_cycle(1'b1, idx + 3);
        drive_cycle(1'b1, idx + 4);
        flush_pipeline();

        // Random canonical coefficient tuples, driven back-to-back.
        idx = tx_count;
        for (i = 0; i < 500; i = i + 1)
            add_random_tx();
        for (i = idx; i < tx_count; i = i + 1)
            drive_cycle(1'b1, i);
        flush_pipeline();

        in_valid = 1'b0;

        $display("INFO tb_basemul_unit: tx_count=%0d valid_check_count=%0d", tx_count, valid_check_count);
        $display("INFO tb_basemul_unit: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        if ((fail_count == 0) && (pass_count == tx_count)) begin
            $display("PASS tb_basemul_unit");
        end else begin
            $display("FAIL tb_basemul_unit");
            $fatal(1, "tb_basemul_unit detected mismatches");
        end
        $finish;
    end

endmodule
