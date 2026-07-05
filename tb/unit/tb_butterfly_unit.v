`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_butterfly_unit;

    reg  [`KYBER_Q_WIDTH:0] a_in;
    reg  [`KYBER_Q_WIDTH:0] b_in;
    reg  [`KYBER_Q_WIDTH:0] zeta;
    wire [`KYBER_Q_WIDTH:0] a_out;
    wire [`KYBER_Q_WIDTH:0] b_out;

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;
    integer rand_a;
    integer rand_b;
    integer rand_zeta;

    butterfly_unit dut (
        .a_in(a_in),
        .b_in(b_in),
        .zeta(zeta),
        .a_out(a_out),
        .b_out(b_out)
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

    function [`KYBER_Q_WIDTH:0] canonical_montgomery_product;
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
                canonical_montgomery_product = mont_ext + `KYBER_Q;
            end else begin
                canonical_montgomery_product = mont_ext[`KYBER_Q_WIDTH:0];
            end
        end
    endfunction

    function [`KYBER_Q_WIDTH:0] expected_mod_add;
        input [`KYBER_Q_WIDTH:0] x;
        input [`KYBER_Q_WIDTH:0] y;
        reg [`KYBER_SUM_WIDTH-1:0] sum;
        begin
            sum = x + y;
            if (sum >= `KYBER_Q) begin
                expected_mod_add = sum - `KYBER_Q;
            end else begin
                expected_mod_add = sum[`KYBER_Q_WIDTH:0];
            end
        end
    endfunction

    function [`KYBER_Q_WIDTH:0] expected_mod_sub;
        input [`KYBER_Q_WIDTH:0] x;
        input [`KYBER_Q_WIDTH:0] y;
        begin
            if (x >= y) begin
                expected_mod_sub = x - y;
            end else begin
                expected_mod_sub = x + `KYBER_Q - y;
            end
        end
    endfunction

    task check_case;
        input [`KYBER_Q_WIDTH:0] a_val;
        input [`KYBER_Q_WIDTH:0] b_val;
        input [`KYBER_Q_WIDTH:0] zeta_val;
        reg [`KYBER_Q_WIDTH:0] t;
        reg [`KYBER_Q_WIDTH:0] expected_a;
        reg [`KYBER_Q_WIDTH:0] expected_b;
        begin
            a_in = a_val;
            b_in = b_val;
            zeta = zeta_val;
            #1;

            t = canonical_montgomery_product(zeta_val, b_val);
            expected_a = expected_mod_add(a_val, t);
            expected_b = expected_mod_sub(a_val, t);

            if ((a_out !== expected_a) || (b_out !== expected_b)) begin
                fail_count = fail_count + 1;
                $display("FAIL butterfly a=%0d b=%0d zeta=%0d got_a=%0d exp_a=%0d got_b=%0d exp_b=%0d t=%0d",
                         a_val, b_val, zeta_val, a_out, expected_a, b_out, expected_b, t);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        seed = 32'h42544631;

        $display("INFO tb_butterfly_unit: KYBER_Q=%0d", `KYBER_Q);

        check_case(0, 0, 2285);
        check_case(1, 1, 2285);
        check_case(1000, 2000, 2571);
        check_case(3328, 3328, 2970);
        check_case(0, 3328, 1812);
        check_case(3328, 0, 1493);

        for (i = 0; i < 200; i = i + 1) begin
            rand_a = $random(seed);
            rand_b = $random(seed);
            rand_zeta = $random(seed);
            if (rand_a < 0) begin
                rand_a = -rand_a;
            end
            if (rand_b < 0) begin
                rand_b = -rand_b;
            end
            if (rand_zeta < 0) begin
                rand_zeta = -rand_zeta;
            end
            check_case(rand_a % `KYBER_Q, rand_b % `KYBER_Q, rand_zeta % `KYBER_Q);
        end

        $display("INFO tb_butterfly_unit: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_butterfly_unit");
            $finish;
        end else begin
            $display("FAIL tb_butterfly_unit");
            $fatal(1, "tb_butterfly_unit detected mismatches");
        end
    end

endmodule
