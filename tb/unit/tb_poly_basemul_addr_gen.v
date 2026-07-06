`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_poly_basemul_addr_gen;

    localparam integer CLK_PERIOD = 10;
    localparam integer EXPECTED_OPS = 128;

    reg clk;
    reg rst_n;
    reg start;

    wire valid;
    wire busy;
    wire done;
    wire [`KYBER_N_WIDTH-1:0] a_addr0;
    wire [`KYBER_N_WIDTH-1:0] a_addr1;
    wire [`KYBER_N_WIDTH-1:0] b_addr0;
    wire [`KYBER_N_WIDTH-1:0] b_addr1;
    wire [`KYBER_N_WIDTH-1:0] r_addr0;
    wire [`KYBER_N_WIDTH-1:0] r_addr1;
    wire [6:0] zeta_addr;
    wire       zeta_neg;
    wire [6:0] op_index;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;
    integer run_count;

    poly_basemul_addr_gen dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .valid     (valid),
        .busy      (busy),
        .done      (done),
        .a_addr0   (a_addr0),
        .a_addr1   (a_addr1),
        .b_addr0   (b_addr0),
        .b_addr1   (b_addr1),
        .r_addr0   (r_addr0),
        .r_addr1   (r_addr1),
        .zeta_addr (zeta_addr),
        .zeta_neg  (zeta_neg),
        .op_index  (op_index)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/waves/poly_basemul_addr_gen.vcd");
        $dumpvars(0, tb_poly_basemul_addr_gen);
    end

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_poly_basemul_addr_gen: %0s", message);
            end
            $display("ERROR tb_poly_basemul_addr_gen: %0s", message);
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            repeat (5) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
            #1;

            if (valid !== 1'b0)
                record_fail("valid must be low after reset");
            if (busy !== 1'b0)
                record_fail("busy must be low after reset");
            if (done !== 1'b0)
                record_fail("done must be low after reset");
            if (op_index !== 7'd0)
                record_fail("op_index must reset to zero");
        end
    endtask

    task pulse_start_and_sample_first;
        begin
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;
            #1;
        end
    endtask

    task sample_next_cycle;
        begin
            @(negedge clk);
            #1;
        end
    endtask

    task check_op;
        input integer op;
        input integer run_id;
        reg [5:0] group_i;
        reg       is_odd;
        reg [`KYBER_N_WIDTH-1:0] base_addr;
        reg [`KYBER_N_WIDTH-1:0] expected_addr0;
        reg [`KYBER_N_WIDTH-1:0] expected_addr1;
        reg [6:0] expected_zeta_addr;
        begin
            group_i = op[6:1];
            is_odd = op[0];
            base_addr = {group_i, 2'b0};
            expected_addr0 = is_odd ? (base_addr + 8'd2) : base_addr;
            expected_addr1 = is_odd ? (base_addr + 8'd3) : (base_addr + 8'd1);
            expected_zeta_addr = 7'd64 + group_i;

            if (valid !== 1'b1) begin
                record_fail("valid low during active schedule");
            end

            if (busy !== 1'b1) begin
                record_fail("busy low during active schedule");
            end

            if (done !== 1'b0) begin
                record_fail("done asserted during active schedule");
            end

            if (op_index !== op[6:0]) begin
                fail_count = fail_count + 1;
                if (!first_fail_seen) begin
                    first_fail_seen = 1;
                    $display("FIRST_FAIL tb_poly_basemul_addr_gen: run=%0d op=%0d expected op_index=%0d actual=%0d",
                             run_id, op, op, op_index);
                end
                $display("ERROR tb_poly_basemul_addr_gen: run=%0d op=%0d expected op_index=%0d actual=%0d",
                         run_id, op, op, op_index);
            end

            if ((a_addr0 !== expected_addr0) ||
                (a_addr1 !== expected_addr1) ||
                (b_addr0 !== expected_addr0) ||
                (b_addr1 !== expected_addr1) ||
                (r_addr0 !== expected_addr0) ||
                (r_addr1 !== expected_addr1) ||
                (zeta_addr !== expected_zeta_addr) ||
                (zeta_neg !== is_odd)) begin
                fail_count = fail_count + 1;
                if (!first_fail_seen) begin
                    first_fail_seen = 1;
                    $display("FIRST_FAIL tb_poly_basemul_addr_gen: run=%0d op=%0d expected addr0=%0d addr1=%0d zeta_addr=%0d zeta_neg=%0d actual a0=%0d a1=%0d b0=%0d b1=%0d r0=%0d r1=%0d zeta_addr=%0d zeta_neg=%0d",
                             run_id, op,
                             expected_addr0, expected_addr1,
                             expected_zeta_addr, is_odd,
                             a_addr0, a_addr1, b_addr0, b_addr1,
                             r_addr0, r_addr1, zeta_addr, zeta_neg);
                end
                $display("ERROR tb_poly_basemul_addr_gen: run=%0d op=%0d expected addr0=%0d addr1=%0d zeta_addr=%0d zeta_neg=%0d actual a0=%0d a1=%0d b0=%0d b1=%0d r0=%0d r1=%0d zeta_addr=%0d zeta_neg=%0d",
                         run_id, op,
                         expected_addr0, expected_addr1,
                         expected_zeta_addr, is_odd,
                         a_addr0, a_addr1, b_addr0, b_addr1,
                         r_addr0, r_addr1, zeta_addr, zeta_neg);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_done_and_idle;
        input integer run_id;
        begin
            @(negedge clk);
            #1;
            if (done !== 1'b1) begin
                record_fail("done must assert immediately after final operation");
            end
            if (valid !== 1'b0) begin
                record_fail("valid must be low during done pulse");
            end
            if (busy !== 1'b0) begin
                record_fail("busy must be low during done pulse");
            end
            if (op_index !== 7'd0) begin
                record_fail("op_index must return to zero on done");
            end

            @(negedge clk);
            #1;
            if (done !== 1'b0) begin
                record_fail("done pulse must last exactly one cycle");
            end
            if (valid !== 1'b0) begin
                record_fail("valid must remain low after done");
            end
            if (busy !== 1'b0) begin
                record_fail("busy must remain low after done");
            end

            $display("INFO tb_poly_basemul_addr_gen: run=%0d checked %0d operations",
                     run_id, EXPECTED_OPS);
        end
    endtask

    task run_schedule;
        input integer run_id;
        input integer pulse_start_while_busy;
        integer op;
        begin
            pulse_start_and_sample_first();

            for (op = 0; op < EXPECTED_OPS; op = op + 1) begin
                if (op != 0) begin
                    sample_next_cycle();
                end

                if (pulse_start_while_busy && (op == 10)) begin
                    start = 1'b1;
                end else begin
                    start = 1'b0;
                end

                check_op(op, run_id);

                if (pulse_start_while_busy && (op == 10)) begin
                    @(negedge clk);
                    start = 1'b0;
                    #1;
                    op = op + 1;
                    check_op(op, run_id);
                end
            end

            check_done_and_idle(run_id);
            run_count = run_count + 1;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;
        run_count = 0;

        apply_reset();
        $display("INFO tb_poly_basemul_addr_gen: checking normal schedule");
        run_schedule(0, 0);

        repeat (4) @(posedge clk);
        $display("INFO tb_poly_basemul_addr_gen: checking restart and busy-start ignore behavior");
        run_schedule(1, 1);

        $display("INFO tb_poly_basemul_addr_gen: run_count=%0d pass_count=%0d fail_count=%0d",
                 run_count, pass_count, fail_count);

        if ((fail_count == 0) && (pass_count == (EXPECTED_OPS * 2))) begin
            $display("PASS tb_poly_basemul_addr_gen");
        end else begin
            $display("FAIL tb_poly_basemul_addr_gen");
            $fatal(1, "tb_poly_basemul_addr_gen detected mismatches");
        end

        $finish;
    end

endmodule
