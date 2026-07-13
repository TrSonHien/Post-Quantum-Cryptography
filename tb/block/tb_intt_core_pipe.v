`timescale 1ns/1ps

module tb_intt_core_pipe;
    initial if ($test$plusargs("DEBUG_WAVES")) begin
        $dumpfile("sim/waves/tb_intt_core_pipe.vcd");
        $dumpvars(0, tb_intt_core_pipe);
    end
    localparam VECTOR_COUNT = 31;
    localparam WORDS_PER_VECTOR = 512;
    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    wire busy, done, error;
    reg preload_en = 0;
    reg [7:0] preload_idx = 0;
    reg [11:0] preload_coeff = 0;
    wire preload_ready;
    reg result_rd_req = 0;
    reg [7:0] result_rd_idx = 0;
    wire result_rd_valid;
    wire [11:0] result_rd_data;
    reg [11:0] vectors [0:VECTOR_COUNT*WORDS_PER_VECTOR-1];
    reg [11:0] zero_poly [0:255];
    integer failures = 0;
    integer coefficient_checks = 0;
    integer vector_index;
    integer i;
    integer cycles;
    integer first_inverse_cycles = 0;
    integer first_transform_cycles = 0;
    integer stage_write_count [0:6];
    integer stage_first_issue_cycle [0:6];
    integer stage_last_issue_cycle [0:6];
    reg stage_write_seen [0:6][0:255];
    reg scale_write_seen [0:255];
    integer scale_logical_write_count = 0;
    integer mon_stage;
    integer mon_index;
    string vector_file;

    always @(posedge clk) begin
        if (!rst_n) begin
            scale_logical_write_count = 0;
            for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                scale_write_seen[mon_index] = 1'b0;
            for (mon_stage = 0; mon_stage < 7; mon_stage = mon_stage + 1) begin
                stage_write_count[mon_stage] = 0;
                stage_first_issue_cycle[mon_stage] = -1;
                stage_last_issue_cycle[mon_stage] = -1;
                for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                    stage_write_seen[mon_stage][mon_index] = 1'b0;
            end
        end else begin
            if (dut.intt_read_req && dut.sched_bfly_idx == 0)
                stage_first_issue_cycle[dut.sched_stage] = dut.transform_cycle_count + 1;
            if (dut.intt_read_req && dut.sched_bfly_idx == 127)
                stage_last_issue_cycle[dut.sched_stage] = dut.transform_cycle_count + 1;
            if (busy && dut.mem_dst_wr_en &&
                !(dut.intt_write_setup_valid || dut.scale_out_valid))
                $fatal(1, "INTT invariant: busy write without matching output/metadata valid");
            if (dut.intt_write_setup_valid) begin
                if (stage_write_seen[dut.write_stage][dut.write_u_idx] ||
                    stage_write_seen[dut.write_stage][dut.write_v_idx])
                    $fatal(1, "INTT invariant: duplicate stage write stage=%0d u=%0d v=%0d",
                           dut.write_stage, dut.write_u_idx, dut.write_v_idx);
                stage_write_seen[dut.write_stage][dut.write_u_idx] = 1'b1;
                stage_write_seen[dut.write_stage][dut.write_v_idx] = 1'b1;
                stage_write_count[dut.write_stage] = stage_write_count[dut.write_stage] + 2;
            end
            if (dut.scale_out_valid) begin
                if (scale_write_seen[{1'b0, dut.scale_out_pair}] ||
                    scale_write_seen[{1'b1, dut.scale_out_pair}])
                    $fatal(1, "INTT invariant: duplicate scaler write pair=%0d", dut.scale_out_pair);
                scale_write_seen[{1'b0, dut.scale_out_pair}] = 1'b1;
                scale_write_seen[{1'b1, dut.scale_out_pair}] = 1'b1;
                scale_logical_write_count = scale_logical_write_count + 2;
            end
            if (done && (dut.pending_reads != 0 || dut.pending_butterflies != 0 ||
                         dut.pending_writes != 0 || dut.scale_pending_reads != 0 ||
                         dut.scale_pending_mults != 0 || dut.scale_pending_writes != 0))
                $fatal(1, "INTT invariant: done with pending traffic");
        end
    end

    intt_core_pipe dut (.*);
    always #5 clk = ~clk;

    task apply_reset;
        begin
            rst_n = 0; start = 0; preload_en = 0; result_rd_req = 0;
            repeat (3) @(negedge clk);
            rst_n = 1;
            repeat (2) @(negedge clk);
            if (busy || done || error || dut.intt_bfly_out_valid || dut.scale_out_valid)
                failures = failures + 1;
        end
    endtask

    task load_vector;
        input integer base;
        begin
            for (i = 0; i < 256; i = i + 1) begin
                preload_en = 1;
                preload_idx = i[7:0];
                preload_coeff = vectors[base + i];
                @(negedge clk);
            end
            preload_en = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task load_zero;
        begin
            for (i = 0; i < 256; i = i + 1) begin
                preload_en = 1; preload_idx = i[7:0]; preload_coeff = 0;
                @(negedge clk);
            end
            preload_en = 0; repeat (2) @(negedge clk);
        end
    endtask

    task pulse_start;
        begin start = 1; @(negedge clk); start = 0; end
    endtask

    task wait_done;
        begin
            cycles = 0;
            while (!done && cycles < 1300) begin @(negedge clk); cycles = cycles + 1; end
            if (!done) begin
                failures = failures + 1;
                $display({"WATCHDOG cycle=%0d state=%0d sched_stage=%0d group=%0d offset=%0d ",
                          "reads=%0d responses=%0d bfly_in=%0d bfly_out=%0d writes=%0d ",
                          "pending=(%0d,%0d,%0d) scale_pending=(%0d,%0d,%0d) busy=%0b done=%0b error=%0b"},
                         cycles, dut.state, dut.sched_stage, dut.sched_group_idx, dut.sched_offset,
                         dut.accepted_read_count, dut.ram_response_count, dut.butterfly_input_count,
                         dut.butterfly_output_count, dut.committed_write_count,
                         dut.pending_reads, dut.pending_butterflies, dut.pending_writes,
                         dut.scale_pending_reads, dut.scale_pending_mults, dut.scale_pending_writes,
                         busy, done, error);
                $fatal(1, "INTT core timeout");
            end
        end
    endtask

    task check_structure;
        begin
            if (dut.accepted_read_count != 896 || dut.ram_response_count != 896 ||
                dut.butterfly_input_count != 896 || dut.butterfly_output_count != 896 ||
                dut.committed_write_count != 896 || dut.stage_drain_count != 7 ||
                dut.stage_role_swap_count != 7 || dut.stage_advance_count != 7 ||
                dut.scale_read_count != 128 || dut.scale_response_count != 128 ||
                dut.scale_coefficient_input_count != 256 ||
                dut.scale_coefficient_output_count != 256 ||
                dut.scale_output_pair_count != 128 || dut.scale_write_count != 128 ||
                dut.total_role_swap_count != 9 || dut.pending_reads != 0 ||
                dut.pending_butterflies != 0 || dut.pending_writes != 0 ||
                dut.scale_pending_reads != 0 || dut.scale_pending_mults != 0 ||
                dut.scale_pending_writes != 0) begin
                failures = failures + 1;
                $display({"COUNT_FAIL inv=(%0d,%0d,%0d,%0d,%0d) stages=(%0d,%0d,%0d) ",
                          "scale=(%0d,%0d,%0d,%0d,%0d,%0d) swaps=%0d"},
                         dut.accepted_read_count, dut.ram_response_count,
                         dut.butterfly_input_count, dut.butterfly_output_count,
                         dut.committed_write_count, dut.stage_drain_count,
                         dut.stage_role_swap_count, dut.stage_advance_count,
                         dut.scale_read_count, dut.scale_response_count,
                         dut.scale_coefficient_input_count, dut.scale_coefficient_output_count,
                         dut.scale_output_pair_count, dut.scale_write_count, dut.total_role_swap_count);
            end
            for (mon_stage = 0; mon_stage < 7; mon_stage = mon_stage + 1) begin
                if ((stage_last_issue_cycle[mon_stage] - stage_first_issue_cycle[mon_stage] + 1) != 128)
                    failures = failures + 1;
                if (mon_stage > 0 &&
                    (stage_first_issue_cycle[mon_stage] - stage_last_issue_cycle[mon_stage-1] - 1) != 8)
                    failures = failures + 1;
                if (stage_write_count[mon_stage] != 256)
                    failures = failures + 1;
                for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                    if (!stage_write_seen[mon_stage][mon_index])
                        failures = failures + 1;
            end
            if (scale_logical_write_count != 256)
                failures = failures + 1;
            for (mon_index = 0; mon_index < 256; mon_index = mon_index + 1)
                if (!scale_write_seen[mon_index])
                    failures = failures + 1;
        end
    endtask

    task check_results;
        input integer base;
        begin
            for (i = 0; i < 256; i = i + 1) begin
                result_rd_req = 1; result_rd_idx = i[7:0];
                @(negedge clk);
                if (!result_rd_valid || result_rd_data !== vectors[base + 256 + i]) begin
                    failures = failures + 1;
                    $display("RESULT_FAIL vector=%0d index=%0d expected=%0d got=%0d valid=%0b",
                             vector_index, i, vectors[base + 256 + i], result_rd_data, result_rd_valid);
                    $fatal(1, "First INTT differential mismatch");
                end
                coefficient_checks = coefficient_checks + 1;
            end
            result_rd_req = 0; repeat (2) @(negedge clk);
        end
    endtask

    task run_vector;
        input integer index;
        integer base;
        begin
            vector_index = index; base = index * WORDS_PER_VECTOR;
            apply_reset(); load_vector(base); pulse_start(); wait_done();
            if (error || busy) failures = failures + 1;
            check_structure();
            if (index == 0) begin
                first_inverse_cycles = dut.inverse_cycle_count;
                first_transform_cycles = dut.transform_cycle_count;
            end
            @(negedge clk);
            if (done) failures = failures + 1;
            check_results(base);
        end
    endtask

    task restart_zero;
        begin
            load_zero(); pulse_start(); wait_done();
            if (error) failures = failures + 1;
            check_structure();
        end
    endtask

    task abort_case;
        input integer mode;
        begin
            apply_reset(); load_zero(); pulse_start(); cycles = 0;
            case (mode)
                0: while (!(dut.state == 3 && dut.sched_issue_valid) && cycles++ < 1300) @(negedge clk);
                1: while (!(dut.state == 3 && dut.sched_stage_issue_done) && cycles++ < 1300) @(negedge clk);
                2: while (!dut.stage_drain_ready && cycles++ < 1300) @(negedge clk);
                3: while (!(dut.state == 3 && dut.sched_stage == 6) && cycles++ < 1300) @(negedge clk);
                4: while (!(dut.state == 5) && cycles++ < 1300) @(negedge clk);
                5: while (!(dut.state == 6) && cycles++ < 1300) @(negedge clk);
                6: while (!dut.scale_drain_ready && cycles++ < 1300) @(negedge clk);
            endcase
            if (cycles >= 1300) $fatal(1, "Abort-point timeout mode=%0d", mode);
            apply_reset();
            restart_zero();
        end
    endtask

    task control_error_case;
        input integer scale_mode;
        begin
            apply_reset(); load_zero(); pulse_start(); cycles = 0;
            if (scale_mode)
                while (dut.state != 5 && cycles++ < 1300) @(negedge clk);
            else
                while (!(dut.state == 3 && dut.sched_issue_valid) && cycles++ < 1300) @(negedge clk);
            start = 1; preload_en = 1; result_rd_req = 1;
            @(negedge clk);
            start = 0; preload_en = 0; result_rd_req = 0;
            if (!error || !busy) failures = failures + 1;
            wait_done();
            if (!error) failures = failures + 1;
        end
    endtask

    initial begin
        if (!$value$plusargs("VECTOR_FILE=%s", vector_file))
            $fatal(1, "Missing +VECTOR_FILE");
        $readmemh(vector_file, vectors);
        for (vector_index = 0; vector_index < VECTOR_COUNT; vector_index = vector_index + 1)
            run_vector(vector_index);

        control_error_case(0);
        control_error_case(1);
        for (i = 0; i < 7; i = i + 1)
            abort_case(i);

        if (failures == 0 && coefficient_checks == 7936) begin
            $display("PASS tb_intt_core_pipe polynomials=31 coefficient_checks=%0d inverse_cycles=%0d transform_cycles=%0d",
                     coefficient_checks, first_inverse_cycles, first_transform_cycles);
            $display("TIMELINE scale_first=%0d scale_final_issue=%0d scale_final_commit=%0d scale_swap=%0d done=%0d",
                     dut.scale_first_issue_cycle, dut.scale_final_issue_cycle,
                     dut.scale_final_commit_cycle, dut.scale_swap_cycle, dut.done_cycle);
            $display("COUNTS inverse=896/896/896/896/896 stage_swaps=7 scale=128/256/256/128 total_swaps=9");
        $display("ISSUE_WINDOWS first=%0d per_stage=128 inter_stage_idle=8",
                 stage_first_issue_cycle[0]);
            $finish;
        end
        $fatal(1, "FAIL tb_intt_core_pipe failures=%0d checks=%0d", failures, coefficient_checks);
    end

    initial begin
        repeat (100000) @(posedge clk);
        $fatal(1, "GLOBAL_WATCHDOG state=%0d vector=%0d checks=%0d", dut.state, vector_index, coefficient_checks);
    end
endmodule
