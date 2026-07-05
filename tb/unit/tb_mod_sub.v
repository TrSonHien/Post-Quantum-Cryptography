`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_mod_sub;

    reg  [`KYBER_Q_WIDTH-1:0] a;
    reg  [`KYBER_Q_WIDTH-1:0] b;
    wire [`KYBER_Q_WIDTH-1:0] c;

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;
    integer rand_a;
    integer rand_b;

    mod_sub dut (
        .a(a),
        .b(b),
        .c(c)
    );

    function [`KYBER_Q_WIDTH-1:0] expected_mod_sub;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        begin
            if (x >= y) begin
                expected_mod_sub = x - y;
            end else begin
                expected_mod_sub = x + `KYBER_Q - y;
            end
        end
    endfunction

    task check_case;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        reg [`KYBER_Q_WIDTH-1:0] expected;
        begin
            a = x;
            b = y;
            #1;
            expected = expected_mod_sub(x, y);

            if (c !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL mod_sub a=%0d b=%0d got=%0d expected=%0d", x, y, c, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        seed = 32'h53554231;

        $display("INFO tb_mod_sub: KYBER_Q=%0d", `KYBER_Q);
        $display("INFO tb_mod_sub: running directed tests");

        check_case(0, 0);
        check_case(1, 0);
        check_case(0, 1);
        check_case(`KYBER_Q-1, 0);
        check_case(0, `KYBER_Q-1);
        check_case(`KYBER_Q-1, `KYBER_Q-1);
        check_case(1000, 999);
        check_case(999, 1000);
        check_case(2000, 3000);
        check_case(3000, 2000);
        check_case(3328, 3327);
        check_case(3327, 3328);

        $display("INFO tb_mod_sub: running random tests");

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

        $display("INFO tb_mod_sub: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_mod_sub");
            $finish;
        end else begin
            $display("FAIL tb_mod_sub");
            $fatal(1, "tb_mod_sub detected mismatches");
        end
    end

endmodule
