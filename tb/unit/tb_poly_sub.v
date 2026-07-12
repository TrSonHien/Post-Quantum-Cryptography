`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_poly_sub;

    localparam integer CLK_PERIOD = 10;
    localparam integer NUM_PATTERNS = 4;
    localparam integer DONE_TIMEOUT = 200;

    reg clk;
    reg rst_n;
    reg start;

    reg                       a_load_en;
    reg  [`KYBER_N_WIDTH-1:0] a_load_addr;
    reg  [`KYBER_Q_WIDTH-1:0] a_load_data;
    reg                       b_load_en;
    reg  [`KYBER_N_WIDTH-1:0] b_load_addr;
    reg  [`KYBER_Q_WIDTH-1:0] b_load_data;
    reg  [`KYBER_N_WIDTH-1:0] r_read_addr;
    wire [`KYBER_Q_WIDTH-1:0] r_read_data;

    wire busy;
    wire done;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;
    integer pattern;
    integer wait_cycles;

    reg [`KYBER_Q_WIDTH-1:0] a_poly   [0:`KYBER_N-1];
    reg [`KYBER_Q_WIDTH-1:0] b_poly   [0:`KYBER_N-1];
    reg [`KYBER_Q_WIDTH-1:0] expected [0:`KYBER_N-1];

    poly_sub dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .busy        (busy),
        .done        (done),
        .a_load_en   (a_load_en),
        .a_load_addr (a_load_addr),
        .a_load_data (a_load_data),
        .b_load_en   (b_load_en),
        .b_load_addr (b_load_addr),
        .b_load_data (b_load_data),
        .r_read_addr (r_read_addr),
        .r_read_data (r_read_data)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/waves/poly_sub.vcd");
        $dumpvars(0, tb_poly_sub);
    end

    function [`KYBER_Q_WIDTH-1:0] expected_mod_sub;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        begin
            if (x >= y)
                expected_mod_sub = x - y;
            else
                expected_mod_sub = x + `KYBER_Q - y;
        end
    endfunction

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_poly_sub: %0s", message);
            end
            $display("ERROR tb_poly_sub: %0s", message);
        end
    endtask

    task init_pattern;
        input integer pattern_id;
        integer j;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                case (pattern_id)
                    0: begin
                        a_poly[j] = 0;
                        b_poly[j] = 0;
                    end
                    1: begin
                        a_poly[j] = j % `KYBER_Q;
                        b_poly[j] = j % `KYBER_Q;
                    end
                    2: begin
                        a_poly[j] = 0;
                        b_poly[j] = (`KYBER_Q - 1);
                    end
                    default: begin
                        a_poly[j] = ((j * 31) + 7) % `KYBER_Q;
                        b_poly[j] = ((j * 19) + 221) % `KYBER_Q;
                    end
                endcase

                expected[j] = expected_mod_sub(a_poly[j], b_poly[j]);
            end
        end
    endtask

    task load_polynomials;
        integer j;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                @(negedge clk);
                a_load_en   = 1'b1;
                a_load_addr = j[`KYBER_N_WIDTH-1:0];
                a_load_data = a_poly[j];
                b_load_en   = 1'b1;
                b_load_addr = j[`KYBER_N_WIDTH-1:0];
                b_load_data = b_poly[j];
            end

            @(negedge clk);
            a_load_en   = 1'b0;
            a_load_addr = {`KYBER_N_WIDTH{1'b0}};
            a_load_data = {`KYBER_Q_WIDTH{1'b0}};
            b_load_en   = 1'b0;
            b_load_addr = {`KYBER_N_WIDTH{1'b0}};
            b_load_data = {`KYBER_Q_WIDTH{1'b0}};
        end
    endtask

    task pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done_or_timeout;
        begin
            wait_cycles = 0;
            while (!done && wait_cycles < DONE_TIMEOUT) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (!done) begin
                record_fail("timeout waiting for done");
            end
        end
    endtask

    task check_results;
        integer j;
        reg [1023:0] fail_msg;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                r_read_addr = j[`KYBER_N_WIDTH-1:0];
                #1;
                if (r_read_data !== expected[j]) begin
                    $sformat(fail_msg,
                             "pattern=%0d index=%0d expected=%0d actual=%0d",
                             pattern, j, expected[j], r_read_data);
                    record_fail(fail_msg);
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        a_load_en = 1'b0;
        a_load_addr = {`KYBER_N_WIDTH{1'b0}};
        a_load_data = {`KYBER_Q_WIDTH{1'b0}};
        b_load_en = 1'b0;
        b_load_addr = {`KYBER_N_WIDTH{1'b0}};
        b_load_data = {`KYBER_Q_WIDTH{1'b0}};
        r_read_addr = {`KYBER_N_WIDTH{1'b0}};

        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        for (pattern = 0; pattern < NUM_PATTERNS; pattern = pattern + 1) begin
            $display("INFO tb_poly_sub: running pattern=%0d", pattern);
            init_pattern(pattern);
            load_polynomials();
            pulse_start();
            wait_done_or_timeout();
            @(negedge clk);
            check_results();

            if (busy !== 1'b0) begin
                record_fail("busy stayed high after done");
            end

            repeat (2) @(posedge clk);
        end

        $display("INFO tb_poly_sub: pass_count=%0d fail_count=%0d",
                 pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_poly_sub");
        end else begin
            $display("FAIL tb_poly_sub");
        end

        $finish;
    end

endmodule
