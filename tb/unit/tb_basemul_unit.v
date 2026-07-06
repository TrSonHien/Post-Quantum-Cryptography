`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_basemul_unit;

    reg clk;
    reg rst_n;
    reg start;
    wire busy;
    wire done;

    reg  [`KYBER_Q_WIDTH-1:0] a0;
    reg  [`KYBER_Q_WIDTH-1:0] a1;
    reg  [`KYBER_Q_WIDTH-1:0] b0;
    reg  [`KYBER_Q_WIDTH-1:0] b1;
    reg  [`KYBER_Q_WIDTH-1:0] zeta;
    wire [`KYBER_Q_WIDTH-1:0] r0;
    wire [`KYBER_Q_WIDTH-1:0] r1;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;
    integer i;
    integer seed;
    integer rand_a0;
    integer rand_a1;
    integer rand_b0;
    integer rand_b1;
    integer rand_zeta;

    basemul_unit dut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .busy  (busy),
        .done  (done),
        .a0    (a0),
        .a1    (a1),
        .b0    (b0),
        .b1    (b1),
        .zeta  (zeta),
        .r0    (r0),
        .r1    (r1)
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

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            a0 = {`KYBER_Q_WIDTH{1'b0}};
            a1 = {`KYBER_Q_WIDTH{1'b0}};
            b0 = {`KYBER_Q_WIDTH{1'b0}};
            b1 = {`KYBER_Q_WIDTH{1'b0}};
            zeta = {`KYBER_Q_WIDTH{1'b0}};
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

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

    task wait_done;
        integer cycles;
        integer done_pulses;
        begin
            cycles = 0;
            done_pulses = 0;
            while (cycles < 20) begin
                @(negedge clk);
                #1;
                if (done) begin
                    done_pulses = done_pulses + 1;
                    if (busy)
                        record_fail("busy must be low when done is high");
                    @(negedge clk);
                    #1;
                    if (done)
                        record_fail("done must pulse for exactly one cycle");
                    if (busy)
                        record_fail("busy must stay low after done");
                    cycles = 20;
                end else begin
                    cycles = cycles + 1;
                end
            end

            if (done_pulses != 1)
                record_fail("done pulse count mismatch");
        end
    endtask

    task check_case;
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
        reg [`KYBER_Q_WIDTH-1:0] expected_r0;
        reg [`KYBER_Q_WIDTH-1:0] expected_r1;
        begin
            t0 = expected_mod_mul(a1_val, b1_val);
            t1 = expected_mod_mul(t0, zeta_val);
            t2 = expected_mod_mul(a0_val, b0_val);
            expected_r0 = expected_mod_add(t1, t2);

            t3 = expected_mod_mul(a0_val, b1_val);
            t4 = expected_mod_mul(a1_val, b0_val);
            expected_r1 = expected_mod_add(t3, t4);

            @(negedge clk);
            a0 = a0_val;
            a1 = a1_val;
            b0 = b0_val;
            b1 = b1_val;
            zeta = zeta_val;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait_done();

            if ((r0 !== expected_r0) || (r1 !== expected_r1)) begin
                fail_count = fail_count + 1;
                if (!first_fail_seen) begin
                    first_fail_seen = 1;
                    $display("FIRST_FAIL tb_basemul_unit: a0=%0d a1=%0d b0=%0d b1=%0d zeta=%0d exp_r0=%0d got_r0=%0d exp_r1=%0d got_r1=%0d",
                             a0_val, a1_val, b0_val, b1_val, zeta_val,
                             expected_r0, r0, expected_r1, r1);
                end
                $display("ERROR tb_basemul_unit: a0=%0d a1=%0d b0=%0d b1=%0d zeta=%0d exp_r0=%0d got_r0=%0d exp_r1=%0d got_r1=%0d",
                         a0_val, a1_val, b0_val, b1_val, zeta_val,
                         expected_r0, r0, expected_r1, r1);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;
        seed = 32'h42415345;

        $display("INFO tb_basemul_unit: KYBER_Q=%0d", `KYBER_Q);
        apply_reset();

        check_case(0, 0, 0, 0, 0);
        check_case(1, 0, 1, 0, 2285);
        check_case(0, 1, 0, 1, 2285);
        check_case(1, 2, 3, 4, 2571);
        check_case(123, 456, 789, 1011, 2970);
        check_case(`KYBER_Q-1, `KYBER_Q-1, `KYBER_Q-1, `KYBER_Q-1, 1812);
        check_case(3328, 1, 2, 3327, 1493);

        for (i = 0; i < 500; i = i + 1) begin
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
            check_case(rand_a0 % `KYBER_Q,
                       rand_a1 % `KYBER_Q,
                       rand_b0 % `KYBER_Q,
                       rand_b1 % `KYBER_Q,
                       rand_zeta % `KYBER_Q);
        end

        $display("INFO tb_basemul_unit: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("PASS tb_basemul_unit");
        end else begin
            $display("FAIL tb_basemul_unit");
        end
        $finish;
    end

endmodule
