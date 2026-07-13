`timescale 1ns/1ps

module tb_ntt_core_pipe;
    initial if ($test$plusargs("DEBUG_WAVES")) begin
        $dumpfile("sim/waves/tb_ntt_core_pipe.vcd");
        $dumpvars(0, tb_ntt_core_pipe);
    end
    localparam N = 256;
    localparam Q = 3329;
    localparam NUM_VECTORS = 28;
    localparam WORDS_PER_VECTOR = 512;
    localparam WATCHDOG_CYCLES = 1600;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    wire busy;
    wire done;
    wire error;
    reg preload_en = 1'b0;
    reg [7:0] preload_idx = 8'd0;
    reg [11:0] preload_coeff = 12'd0;
    wire preload_ready;
    reg result_rd_req = 1'b0;
    reg [7:0] result_rd_idx = 8'd0;
    wire result_rd_valid;
    wire [11:0] result_rd_data;

    ntt_core_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .error(error),
        .preload_en(preload_en),
        .preload_idx(preload_idx),
        .preload_coeff(preload_coeff),
        .preload_ready(preload_ready),
        .result_rd_req(result_rd_req),
        .result_rd_idx(result_rd_idx),
        .result_rd_valid(result_rd_valid),
        .result_rd_data(result_rd_data)
    );

    always #5 clk = ~clk;

    reg [11:0] vector_mem [0:NUM_VECTORS*WORDS_PER_VECTOR-1];
    reg [1023:0] vector_file;
    integer pass_count = 0;
    integer fail_count = 0;
    integer coefficient_checks = 0;
    integer transform_cycles = 0;
    integer expected_transform_cycles = -1;
    integer done_pulses = 0;
    integer stage_write_count [0:6];
    integer stage_first_issue_cycle [0:6];
    integer stage_last_issue_cycle [0:6];
    reg stage_write_seen [0:6][0:255];
    integer mon_stage;
    integer mon_index;
    integer vec;
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (mon_stage = 0; mon_stage < 7; mon_stage = mon_stage + 1) begin
                stage_write_count[mon_stage] = 0;
                stage_first_issue_cycle[mon_stage] = -1;
                stage_last_issue_cycle[mon_stage] = -1;
                for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                    stage_write_seen[mon_stage][mon_index] = 1'b0;
            end
        end else begin
            if (dut.core_read_req && dut.sched_bfly_idx == 0)
                stage_first_issue_cycle[dut.sched_stage] = dut.transform_cycle_count + 1;
            if (dut.core_read_req && dut.sched_bfly_idx == 127)
                stage_last_issue_cycle[dut.sched_stage] = dut.transform_cycle_count + 1;
            if (busy && dut.mem_dst_wr_en && !dut.run_write_setup_valid)
                $fatal(1, "NTT invariant: busy write without butterfly output/metadata valid");
            if (dut.run_write_setup_valid) begin
                if (stage_write_seen[dut.write_stage][dut.write_u_idx] ||
                    stage_write_seen[dut.write_stage][dut.write_v_idx])
                    $fatal(1, "NTT invariant: duplicate logical write stage=%0d u=%0d v=%0d",
                           dut.write_stage, dut.write_u_idx, dut.write_v_idx);
                stage_write_seen[dut.write_stage][dut.write_u_idx] = 1'b1;
                stage_write_seen[dut.write_stage][dut.write_v_idx] = 1'b1;
                stage_write_count[dut.write_stage] = stage_write_count[dut.write_stage] + 2;
            end
            if (done && (dut.pending_reads != 0 || dut.pending_butterflies != 0 ||
                         dut.pending_writes != 0))
                $fatal(1, "NTT invariant: done with pending traffic");
        end
    end

    task fail;
        input [1023:0] msg;
        begin
            fail_count = fail_count + 1;
            $display("ERROR: %0s", msg);
        end
    endtask

    task dump_state;
        begin
            $display("DUMP cycle=%0d core_state=%0d sched_state=%0d sched_stage=%0d group=%0d bfly=%0d",
                     transform_cycles, dut.state, dut.u_scheduler.state, dut.sched_stage,
                     dut.sched_group_idx, dut.sched_bfly_idx);
            $display("DUMP issue_valid=%b accepted_reads=%0d ram_responses=%0d bfly_inputs=%0d bfly_outputs=%0d committed_writes=%0d",
                     dut.sched_issue_valid, dut.accepted_read_count, dut.ram_response_count,
                     dut.butterfly_input_count, dut.butterfly_output_count, dut.committed_write_count);
            $display("DUMP pending_reads=%0d pending_bflies=%0d pending_writes=%0d last_issue_stage=%b write_last_stage=%b write_last_transform=%b",
                     dut.pending_reads, dut.pending_butterflies, dut.pending_writes,
                     dut.sched_last_issue_in_stage, dut.write_commit_last_stage,
                     dut.write_commit_last_transform);
            $display("DUMP swap_roles=%b stage_advance=%b busy=%b done=%b error=%b role_select=%b",
                     dut.swap_roles, dut.sched_stage_advance, busy, done, error, dut.role_select);
            $display("DUMP delayed stage=%0d group=%0d bfly=%0d zeta=%0d",
                     dut.write_stage, dut.write_group_idx, dut.write_bfly_idx, dut.write_zeta_addr);
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            preload_en = 1'b0;
            preload_idx = 8'd0;
            preload_coeff = 12'd0;
            result_rd_req = 1'b0;
            result_rd_idx = 8'd0;
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
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

    task preload_one;
        input [7:0] idx;
        input [11:0] coeff;
        begin
            @(negedge clk);
            if (!preload_ready)
                fail("preload_ready low while idle");
            preload_en = 1'b1;
            preload_idx = idx;
            preload_coeff = coeff;
            @(negedge clk);
            preload_en = 1'b0;
            preload_idx = 8'd0;
            preload_coeff = 12'd0;
        end
    endtask

    task load_vector;
        input integer vector_index;
        integer base;
        integer pair;
        begin
            base = vector_index * WORDS_PER_VECTOR;
            for (pair = 0; pair < 128; pair = pair + 1) begin
                preload_one(pair[7:0], vector_mem[base + pair]);
                preload_one((pair + 128), vector_mem[base + pair + 128]);
            end
            repeat (2) @(negedge clk);
        end
    endtask

    task wait_for_done_bounded;
        integer cycles;
        begin
            cycles = 0;
            done_pulses = 0;
            while (cycles < WATCHDOG_CYCLES && done_pulses == 0) begin
                @(posedge clk);
                #1;
                if (done)
                    done_pulses = done_pulses + 1;
                cycles = cycles + 1;
            end
            transform_cycles = cycles;
            if (done_pulses == 0) begin
                fail("watchdog expired before done");
                dump_state();
            end
            repeat (4) begin
                @(posedge clk);
                #1;
                if (done)
                    done_pulses = done_pulses + 1;
            end
            if (done_pulses != 1) begin
                fail("done pulse count mismatch");
                dump_state();
            end
        end
    endtask

    task check_counts;
        begin
            if (dut.accepted_read_count !== 11'd896) fail("accepted read count mismatch");
            if (dut.ram_response_count !== 11'd896) fail("RAM response count mismatch");
            if (dut.butterfly_input_count !== 11'd896) fail("butterfly input count mismatch");
            if (dut.butterfly_output_count !== 11'd896) fail("butterfly output count mismatch");
            if (dut.committed_write_count !== 11'd896) fail("committed write count mismatch");
            if (dut.stage_drain_count !== 4'd7) fail("stage drain count mismatch");
            if (dut.stage_advance_count !== 4'd7) fail("stage advance count mismatch");
            if (dut.stage_role_swap_count !== 4'd7) fail("stage role swap count mismatch");
            if (dut.pending_reads !== 8'd0) fail("pending read count not zero");
            if (dut.pending_butterflies !== 8'd0) fail("pending butterfly count not zero");
            if (dut.pending_writes !== 8'd0) fail("pending write count not zero");
            for (mon_stage = 0; mon_stage < 7; mon_stage = mon_stage + 1) begin
                if ((stage_last_issue_cycle[mon_stage] - stage_first_issue_cycle[mon_stage] + 1) != 128)
                    fail("stage issue window is not 128 contiguous cycles");
                if (mon_stage > 0 &&
                    (stage_first_issue_cycle[mon_stage] - stage_last_issue_cycle[mon_stage-1] - 1) != 8)
                    fail("inter-stage no-issue overhead mismatch");
                if (stage_write_count[mon_stage] != 256)
                    fail("stage logical write count mismatch");
                for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                    if (!stage_write_seen[mon_stage][mon_index])
                        fail("missing logical coefficient write");
            end
            if (error) fail("error asserted after legal transform");
            if (busy) fail("busy still high after done");
            if (expected_transform_cycles < 0)
                expected_transform_cycles = transform_cycles;
            else if (transform_cycles != expected_transform_cycles)
                fail("transform cycle count changed between vectors");
        end
    endtask

    task read_and_check_vector;
        input integer vector_index;
        integer base;
        integer idx;
        reg [11:0] expected;
        begin
            base = vector_index * WORDS_PER_VECTOR;
            for (idx = 0; idx < N; idx = idx + 1) begin
                @(negedge clk);
                result_rd_req = 1'b1;
                result_rd_idx = idx[7:0];
                @(posedge clk);
                #1;
                expected = vector_mem[base + N + idx];
                if (!result_rd_valid) begin
                    fail("result_rd_valid low during readback");
                    dump_state();
                end else if (result_rd_data !== expected) begin
                    fail_count = fail_count + 1;
                    if (fail_count < 8) begin
                        $display("FIRST_MISMATCH vector=%0d index=%0d expected=%0d actual=%0d",
                                 vector_index, idx, expected, result_rd_data);
                        dump_state();
                    end
                end else begin
                    pass_count = pass_count + 1;
                end
                coefficient_checks = coefficient_checks + 1;
            end
            @(negedge clk);
            result_rd_req = 1'b0;
            result_rd_idx = 8'd0;
        end
    endtask

    task run_vector;
        input integer vector_index;
        begin
            $display("INFO tb_ntt_core_pipe: vector %0d start", vector_index);
            apply_reset();
            load_vector(vector_index);
            pulse_start();
            wait_for_done_bounded();
            check_counts();
            read_and_check_vector(vector_index);
            $display("INFO tb_ntt_core_pipe: vector %0d done cycles=%0d", vector_index, transform_cycles);
        end
    endtask

    task expect_error_after_busy_pulse;
        input integer mode;
        begin
            apply_reset();
            load_vector(0);
            pulse_start();
            repeat (20) @(negedge clk);
            if (!busy)
                fail("core not busy during control test");
            if (mode == 0) begin
                start = 1'b1;
            end else if (mode == 1) begin
                preload_en = 1'b1;
                preload_idx = 8'd0;
                preload_coeff = 12'd1;
            end else begin
                result_rd_req = 1'b1;
                result_rd_idx = 8'd0;
            end
            @(posedge clk);
            #1;
            if (!error) begin
                fail("expected busy-time protocol error");
                dump_state();
            end
            start = 1'b0;
            preload_en = 1'b0;
            result_rd_req = 1'b0;
        end
    endtask

    task reset_mid_run_and_restart;
        input integer delay_cycles;
        begin
            apply_reset();
            load_vector(0);
            pulse_start();
            repeat (delay_cycles) @(negedge clk);
            rst_n = 1'b0;
            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
            if (busy || done || error)
                fail("reset did not clear control state");
            load_vector(0);
            pulse_start();
            wait_for_done_bounded();
            check_counts();
        end
    endtask

    task run_control_tests;
        begin
            $display("INFO tb_ntt_core_pipe: control tests start");
            expect_error_after_busy_pulse(0);
            expect_error_after_busy_pulse(1);
            expect_error_after_busy_pulse(2);
            reset_mid_run_and_restart(30);
            reset_mid_run_and_restart(135);
            reset_mid_run_and_restart(145);
            reset_mid_run_and_restart(850);
            $display("INFO tb_ntt_core_pipe: control tests done");
        end
    endtask

    initial begin
        if (!$value$plusargs("VECTOR_FILE=%s", vector_file))
            vector_file = "sim/outputs/ntt_core_pipe_vectors.mem";
        $readmemh(vector_file, vector_mem);

        run_control_tests();
        for (vec = 0; vec < NUM_VECTORS; vec = vec + 1)
            run_vector(vec);

        $display("INFO tb_ntt_core_pipe: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        $display("INFO tb_ntt_core_pipe: tested_polynomials=%0d coefficient_checks=%0d transform_cycles=%0d", NUM_VECTORS, coefficient_checks, expected_transform_cycles);
        $display("INFO tb_ntt_core_pipe: counts reads=%0d responses=%0d bfly_in=%0d bfly_out=%0d writes=%0d stage_swaps=%0d stage_advances=%0d total_role_swaps=%0d",
                 dut.accepted_read_count, dut.ram_response_count, dut.butterfly_input_count,
                 dut.butterfly_output_count, dut.committed_write_count,
                 dut.stage_role_swap_count, dut.stage_advance_count, dut.total_role_swap_count);
        $display("INFO tb_ntt_core_pipe: first_issue_cycle=%0d per_stage_issue=128 inter_stage_idle=8",
                 stage_first_issue_cycle[0]);
        if (fail_count == 0)
            $display("PASS tb_ntt_core_pipe");
        else
            $fatal(1, "FAIL tb_ntt_core_pipe");
        $finish;
    end
endmodule
