`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_mod_mul;

    reg  [`KYBER_Q_WIDTH:0] a;
    reg  [`KYBER_Q_WIDTH:0] b;
    wire [`KYBER_Q_WIDTH:0] c;

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;
    integer rand_a;
    integer rand_b;

    mod_mul dut (
        .a(a),
        .b(b),
        .c(c)
    );

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

    function [`KYBER_Q_WIDTH:0] expected_mod_mul;
        input [`KYBER_Q_WIDTH:0] x;
        input [`KYBER_Q_WIDTH:0] y;
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
                expected_mod_mul = mont_ext[`KYBER_Q_WIDTH:0];
            end
        end
    endfunction

    task check_case;
        input [`KYBER_Q_WIDTH:0] x;
        input [`KYBER_Q_WIDTH:0] y;
        reg [`KYBER_Q_WIDTH:0] expected;
        begin
            a = x;
            b = y;
            #1;
            expected = expected_mod_mul(x, y);
            if (c !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL mod_mul a=%0d b=%0d got=%0d expected=%0d", x, y, c, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        seed = 32'h4d554c31;

        $display("INFO tb_mod_mul: KYBER_Q=%0d", `KYBER_Q);

        check_case(0, 0);
        check_case(0, 1);
        check_case(1, 0);
        check_case(1, 1);
        check_case(2, 3);
        check_case(`KYBER_Q-1, 1);
        check_case(1, `KYBER_Q-1);
        check_case(`KYBER_Q-1, `KYBER_Q-1);
        check_case(123, 456);
        check_case(3328, 3328);

        for (i = 0; i < 1000; i = i + 1) begin
            rand_a = $random(seed);
            rand_b = $random(seed);
            if (rand_a < 0) begin
                rand_a = -rand_a;
            end
            if (rand_b < 0) begin
                rand_b = -rand_b;
            end
            check_case(rand_a % `KYBER_Q, rand_b % `KYBER_Q);
        end

        $display("INFO tb_mod_mul: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_mod_mul");
            $finish;
        end else begin
            $display("FAIL tb_mod_mul");
            $fatal(1, "tb_mod_mul detected mismatches");
        end
    end

endmodule
