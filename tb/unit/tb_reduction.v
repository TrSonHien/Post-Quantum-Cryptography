`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_reduction;

    reg  [31:0] mont_in;
    wire [15:0] mont_out;

    reg  [31:0] barrett_in;
    wire [15:0] barrett_out;

    reg  [15:0] csub_in;
    wire [15:0] csub_out;

    integer pass_count;
    integer fail_count;
    integer i;
    integer seed;
    reg [31:0] rand_val;

    montgomery_reduce u_montgomery_reduce (
        .a(mont_in),
        .r(mont_out)
    );

    barrett_reduce u_barrett_reduce (
        .a(barrett_in),
        .r(barrett_out)
    );

    conditional_sub_q u_conditional_sub_q (
        .a(csub_in),
        .r(csub_out)
    );

    function [15:0] expected_montgomery_reduce;
        input [31:0] x;
        reg [63:0] m;
        reg [63:0] t;
        begin
            m = (x * 32'd3327) & 64'hffff;
            t = (x + (m * `KYBER_Q)) >> 16;
            if (t >= `KYBER_Q)
                expected_montgomery_reduce = t - `KYBER_Q;
            else
                expected_montgomery_reduce = t[15:0];
        end
    endfunction

    function [15:0] expected_barrett_reduce;
        input [31:0] x;
        begin
            expected_barrett_reduce = x % `KYBER_Q;
        end
    endfunction

    function [15:0] expected_conditional_sub_q;
        input [15:0] x;
        begin
            if (x >= `KYBER_Q) begin
                expected_conditional_sub_q = x - `KYBER_Q;
            end else begin
                expected_conditional_sub_q = x;
            end
        end
    endfunction

    task check_montgomery;
        input [31:0] x;
        reg [15:0] expected;
        begin
            mont_in = x;
            #1;
            expected = expected_montgomery_reduce(x);
            if (mont_out !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL montgomery_reduce a=%0d got=%0d expected=%0d", x, mont_out, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_barrett;
        input [31:0] x;
        reg [15:0] expected;
        begin
            barrett_in = x;
            #1;
            expected = expected_barrett_reduce(x);
            if (barrett_out !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL barrett_reduce a=%0d got=%0d expected=%0d", x, barrett_out, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_csubq;
        input [15:0] x;
        reg [15:0] expected;
        begin
            csub_in = x;
            #1;
            expected = expected_conditional_sub_q(x);
            if (csub_out !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL conditional_sub_q a=%0d got=%0d expected=%0d", x, csub_out, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        seed = 32'h52454431;

        $display("INFO tb_reduction: KYBER_Q=%0d", `KYBER_Q);

        check_montgomery(0);
        check_montgomery(1);
        check_montgomery(3329);
        check_montgomery(123456);
        check_montgomery((`KYBER_Q * 32'd65536) - 1);

        check_barrett(0);
        check_barrett(1);
        check_barrett(3328);
        check_barrett(3329);
        check_barrett(6656);
        check_barrett(32'hffff_ffff);
        check_barrett(32'h8000_0000);

        check_csubq(0);
        check_csubq(1);
        check_csubq(`KYBER_Q-1);
        check_csubq(`KYBER_Q);
        check_csubq(`KYBER_Q+1);
        check_csubq((2*`KYBER_Q)-1);

        for (i = 0; i < 200; i = i + 1) begin
            rand_val = $random(seed);
            check_montgomery(rand_val % (`KYBER_Q * 32'd65536));
            check_barrett(rand_val);
            check_csubq(rand_val % (2*`KYBER_Q));
        end

        $display("INFO tb_reduction: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_reduction");
            $finish;
        end else begin
            $display("FAIL tb_reduction");
            $fatal(1, "tb_reduction detected mismatches");
        end
    end

endmodule
