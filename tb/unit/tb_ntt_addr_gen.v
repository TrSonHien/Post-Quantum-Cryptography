`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_ntt_addr_gen;

    localparam integer CLK_PERIOD = 10;
    localparam integer EXPECTED_VALID_CYCLES = 896;

    reg clk;
    reg rst_n;
    reg start;
    reg mode;

    wire valid;
    wire done;
    wire busy;
    wire [`KYBER_N_WIDTH-1:0] addr_a;
    wire [`KYBER_N_WIDTH-1:0] addr_b;
    wire [6:0] zeta_addr;
    wire [`KYBER_N_WIDTH-1:0] len_out;

    integer fail_count;
    integer pass_count;

    ntt_addr_gen dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .valid(valid),
        .done(done),
        .busy(busy),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .zeta_addr(zeta_addr),
        .len_out(len_out)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/waves/ntt_addr_gen.vcd");
        $dumpvars(0, tb_ntt_addr_gen);
    end

    task report_mismatch;
        input mode_value;
        input integer cycle_index;
        input integer expected_len;
        input integer expected_addr_a;
        input integer expected_addr_b;
        input integer expected_zeta_addr;
        begin
            fail_count = fail_count + 1;
            $display("ERROR ntt_addr_gen mode=%0d cycle=%0d expected len=%0d addr_a=%0d addr_b=%0d zeta_addr=%0d actual len=%0d addr_a=%0d addr_b=%0d zeta_addr=%0d",
                     mode_value,
                     cycle_index,
                     expected_len,
                     expected_addr_a,
                     expected_addr_b,
                     expected_zeta_addr,
                     len_out,
                     addr_a,
                     addr_b,
                     zeta_addr);
        end
    endtask

    task check_valid_cycle;
        input mode_value;
        input integer cycle_index;
        input integer expected_len;
        input integer expected_addr_a;
        input integer expected_addr_b;
        input integer expected_zeta_addr;
        begin
            if (!valid) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d cycle=%0d expected valid=1 actual valid=0",
                         mode_value, cycle_index);
            end

            if ((len_out !== expected_len) ||
                (addr_a !== expected_addr_a) ||
                (addr_b !== expected_addr_b) ||
                (zeta_addr !== expected_zeta_addr)) begin
                report_mismatch(mode_value,
                                cycle_index,
                                expected_len,
                                expected_addr_a,
                                expected_addr_b,
                                expected_zeta_addr);
            end else begin
                pass_count = pass_count + 1;
            end

            if (done) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d cycle=%0d done asserted during valid schedule",
                         mode_value, cycle_index);
            end
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            mode = 1'b0;
            repeat (5) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task start_mode_and_sample_first_edge;
        input mode_value;
        begin
            @(negedge clk);
            mode = mode_value;
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

    task check_done_and_idle;
        input mode_value;
        begin
            @(negedge clk);
            #1;
            if (!done) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d expected done pulse immediately after final valid schedule",
                         mode_value);
            end
            if (valid) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d expected valid low during done pulse", mode_value);
            end
            if (busy) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d expected busy low during done pulse", mode_value);
            end

            @(negedge clk);
            #1;
            if (done) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d done pulse lasted more than 1 cycle", mode_value);
            end
            if (valid) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d expected valid low after done", mode_value);
            end
            if (busy) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=%0d expected busy low after done", mode_value);
            end
        end
    endtask

    task run_forward_mode;
        integer len;
        integer start_idx;
        integer j;
        integer k;
        integer zeta;
        integer cycle_index;
        begin
            $display("INFO tb_ntt_addr_gen: starting forward mode");
            start_mode_and_sample_first_edge(1'b0);

            cycle_index = 0;
            k = 1;
            for (len = 128; len >= 2; len = len >> 1) begin
                for (start_idx = 0; start_idx < 256; start_idx = j + len) begin
                    zeta = k;
                    k = k + 1;
                    for (j = start_idx; j < start_idx + len; j = j + 1) begin
                        if (cycle_index != 0) begin
                            sample_next_cycle();
                        end
                        check_valid_cycle(1'b0, cycle_index, len, j, j + len, zeta);
                        cycle_index = cycle_index + 1;
                    end
                end
            end

            if (cycle_index != EXPECTED_VALID_CYCLES) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=0 expected valid cycles=%0d actual=%0d",
                         EXPECTED_VALID_CYCLES, cycle_index);
            end else begin
                $display("INFO tb_ntt_addr_gen: forward valid cycles=%0d", cycle_index);
            end

            check_done_and_idle(1'b0);
        end
    endtask

    task run_inverse_mode;
        integer len;
        integer start_idx;
        integer j;
        integer k;
        integer zeta;
        integer cycle_index;
        begin
            $display("INFO tb_ntt_addr_gen: starting inverse mode");
            start_mode_and_sample_first_edge(1'b1);

            cycle_index = 0;
            k = 0;
            for (len = 2; len <= 128; len = len << 1) begin
                for (start_idx = 0; start_idx < 256; start_idx = j + len) begin
                    zeta = k;
                    k = k + 1;
                    for (j = start_idx; j < start_idx + len; j = j + 1) begin
                        if (cycle_index != 0) begin
                            sample_next_cycle();
                        end
                        check_valid_cycle(1'b1, cycle_index, len, j, j + len, zeta);
                        cycle_index = cycle_index + 1;
                    end
                end
            end

            if (cycle_index != EXPECTED_VALID_CYCLES) begin
                fail_count = fail_count + 1;
                $display("ERROR ntt_addr_gen mode=1 expected valid cycles=%0d actual=%0d",
                         EXPECTED_VALID_CYCLES, cycle_index);
            end else begin
                $display("INFO tb_ntt_addr_gen: inverse valid cycles=%0d", cycle_index);
            end

            check_done_and_idle(1'b1);
        end
    endtask

    initial begin
        fail_count = 0;
        pass_count = 0;

        apply_reset();
        run_forward_mode();
        repeat (4) @(posedge clk);
        run_inverse_mode();
        repeat (4) @(posedge clk);

        $display("INFO tb_ntt_addr_gen: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_ntt_addr_gen");
            $finish;
        end else begin
            $display("FAIL tb_ntt_addr_gen");
            $fatal(1, "tb_ntt_addr_gen detected mismatches");
        end
    end

    initial begin
        #1000000;
        fail_count = fail_count + 1;
        $display("FAIL tb_ntt_addr_gen timeout");
        $fatal(1, "tb_ntt_addr_gen timeout");
    end

endmodule
