`timescale 1ns/1ps

module tb_intt_scheduler_pipe;
    initial if ($test$plusargs("DEBUG_WAVES")) begin
        $dumpfile("sim/waves/tb_intt_scheduler_pipe.vcd");
        $dumpvars(0, tb_intt_scheduler_pipe);
    end
    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    reg stage_advance = 0;
    wire busy, error, issue_valid;
    wire [7:0] u_idx, v_idx;
    wire src_u_bank, src_v_bank, dst_u_bank, dst_v_bank;
    wire [6:0] src_u_addr, src_v_addr, dst_u_addr, dst_v_addr;
    wire [6:0] zeta_addr, bfly_idx, group_idx, offset;
    wire [2:0] stage;
    wire last_issue_in_stage, last_issue_in_transform;
    wire stage_issue_done, schedule_done;

    integer failures = 0;
    integer requests = 0;
    integer waits = 0;
    integer advances = 0;
    integer expected_stage;
    integer expected_bfly;
    integer len;
    integer group_expected;
    integer offset_expected;
    integer u_expected;
    integer zeta_expected;

    intt_scheduler_pipe dut (
        .clk(clk), .rst_n(rst_n), .start(start), .stage_advance(stage_advance),
        .busy(busy), .error(error), .issue_valid(issue_valid),
        .src_u_idx(u_idx), .src_v_idx(v_idx),
        .src_u_bank(src_u_bank), .src_u_addr(src_u_addr),
        .src_v_bank(src_v_bank), .src_v_addr(src_v_addr),
        .dst_u_bank(dst_u_bank), .dst_u_addr(dst_u_addr),
        .dst_v_bank(dst_v_bank), .dst_v_addr(dst_v_addr),
        .zeta_addr(zeta_addr), .stage(stage), .bfly_idx(bfly_idx),
        .group_idx(group_idx), .offset(offset),
        .last_issue_in_stage(last_issue_in_stage),
        .last_issue_in_transform(last_issue_in_transform),
        .stage_issue_done(stage_issue_done), .schedule_done(schedule_done)
    );

    always #5 clk = ~clk;

    function integer remove_bit;
        input integer idx;
        input integer bitpos;
        integer low_mask;
        begin
            low_mask = (1 << bitpos) - 1;
            remove_bit = (idx & low_mask) | ((idx >> (bitpos + 1)) << bitpos);
        end
    endfunction

    function integer map_bank;
        input integer idx;
        input integer p;
        input integer r;
        input integer x;
        begin
            map_bank = ((idx >> p) ^ (x ? (idx >> r) : 0)) & 1;
        end
    endfunction

    task check_request;
        integer sp, sr, sx, dp, dr, dx;
        begin
            len = 2 << expected_stage;
            group_expected = expected_bfly >> (expected_stage + 1);
            offset_expected = expected_bfly & (len - 1);
            u_expected = group_expected * (2 * len) + offset_expected;
            zeta_expected = (127 >> expected_stage) - group_expected;
            sp = expected_stage + 1;
            sr = (expected_stage == 0) ? 1 : expected_stage;
            sx = (expected_stage != 0);
            dp = (expected_stage == 6) ? 7 : expected_stage + 2;
            dr = expected_stage + 1;
            dx = (expected_stage != 6);
            if (stage !== expected_stage || bfly_idx !== expected_bfly ||
                group_idx !== group_expected || offset !== offset_expected ||
                u_idx !== u_expected || v_idx !== u_expected + len ||
                zeta_addr !== zeta_expected) begin
                failures = failures + 1;
                $display("SCHEDULE_FAIL stage=%0d bfly=%0d got_stage=%0d got_bfly=%0d u=%0d v=%0d zeta=%0d",
                         expected_stage, expected_bfly, stage, bfly_idx, u_idx, v_idx, zeta_addr);
            end
            if (src_u_bank !== map_bank(u_expected, sp, sr, sx) ||
                src_v_bank !== map_bank(u_expected + len, sp, sr, sx) ||
                src_u_addr !== remove_bit(u_expected, sr) ||
                src_v_addr !== remove_bit(u_expected + len, sr) ||
                dst_u_bank !== map_bank(u_expected, dp, dr, dx) ||
                dst_v_bank !== map_bank(u_expected + len, dp, dr, dx) ||
                dst_u_addr !== remove_bit(u_expected, dr) ||
                dst_v_addr !== remove_bit(u_expected + len, dr)) begin
                failures = failures + 1;
                $display("MAP_FAIL stage=%0d group=%0d offset=%0d u=%0d v=%0d",
                         expected_stage, group_expected, offset_expected, u_expected, u_expected + len);
            end
            if (src_u_bank === src_v_bank || dst_u_bank === dst_v_bank) begin
                failures = failures + 1;
                $display("COLLISION stage=%0d bfly=%0d", expected_stage, expected_bfly);
            end
            if (last_issue_in_stage !== (expected_bfly == 127) ||
                last_issue_in_transform !== ((expected_stage == 6) && (expected_bfly == 127)))
                failures = failures + 1;
        end
    endtask

    task reset_dut;
        begin
            rst_n = 0; start = 0; stage_advance = 0;
            repeat (3) @(negedge clk);
            rst_n = 1;
            repeat (2) @(negedge clk);
        end
    endtask

    task pulse_start;
        begin
            start = 1; @(negedge clk); start = 0;
        end
    endtask

    initial begin
        reset_dut();
        expected_stage = 0;
        expected_bfly = 0;
        pulse_start();
        for (expected_stage = 0; expected_stage < 7; expected_stage = expected_stage + 1) begin
            for (expected_bfly = 0; expected_bfly < 128; expected_bfly = expected_bfly + 1) begin
                if (!issue_valid) begin
                    failures = failures + 1;
                    $display("MISSING_ISSUE stage=%0d bfly=%0d", expected_stage, expected_bfly);
                end else begin
                    check_request();
                    requests = requests + 1;
                end
                @(negedge clk);
            end
            if (!stage_issue_done || issue_valid)
                failures = failures + 1;
            waits = waits + 1;
            repeat (3) begin
                @(negedge clk);
                if (issue_valid) failures = failures + 1;
            end
            stage_advance = 1;
            @(negedge clk);
            stage_advance = 0;
            advances = advances + 1;
        end
        if (!schedule_done)
            @(negedge clk);
        if (requests != 896 || waits != 7 || advances != 7 || busy)
            failures = failures + 1;

        // Illegal controls set sticky error.
        stage_advance = 1; @(negedge clk); stage_advance = 0;
        if (!error) failures = failures + 1;

        // Reset in issue and wait states flushes valid/state/error.
        reset_dut(); pulse_start(); repeat (10) @(negedge clk); reset_dut();
        if (busy || issue_valid || error) failures = failures + 1;
        pulse_start();
        while (!stage_issue_done) @(negedge clk);
        reset_dut();
        if (busy || issue_valid || error) failures = failures + 1;

        // Start while busy and stage advance while issuing are illegal.
        pulse_start();
        start = 1; stage_advance = 1; @(negedge clk); start = 0; stage_advance = 0;
        if (!error) failures = failures + 1;

        if (failures == 0) begin
            $display("PASS tb_intt_scheduler_pipe requests=896 waits=7 advances=7");
            $finish;
        end
        $fatal(1, "FAIL tb_intt_scheduler_pipe failures=%0d", failures);
    end

    initial begin
        repeat (3000) @(posedge clk);
        $fatal(1, "WATCHDOG tb_intt_scheduler_pipe stage=%0d bfly=%0d busy=%0b error=%0b",
               stage, bfly_idx, busy, error);
    end
endmodule
