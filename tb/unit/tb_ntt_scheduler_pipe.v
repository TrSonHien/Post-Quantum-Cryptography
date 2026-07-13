`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_ntt_scheduler_pipe;

    reg         clk;
    reg         rst_n;
    reg         start;
    reg         stage_advance;
    wire        busy;
    wire        error;
    wire        issue_valid;
    wire [7:0]  src_u_idx;
    wire [7:0]  src_v_idx;
    wire        src_u_bank;
    wire [6:0]  src_u_addr;
    wire        src_v_bank;
    wire [6:0]  src_v_addr;
    wire        dst_u_bank;
    wire [6:0]  dst_u_addr;
    wire        dst_v_bank;
    wire [6:0]  dst_v_addr;
    wire [6:0]  zeta_addr;
    wire [2:0]  stage;
    wire [6:0]  bfly_idx;
    wire [6:0]  group_idx;
    wire        last_issue_in_stage;
    wire        last_issue_in_transform;
    wire        stage_issue_done;
    wire        schedule_done;

    ntt_scheduler_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .stage_advance(stage_advance),
        .busy(busy),
        .error(error),
        .issue_valid(issue_valid),
        .src_u_idx(src_u_idx),
        .src_v_idx(src_v_idx),
        .src_u_bank(src_u_bank),
        .src_u_addr(src_u_addr),
        .src_v_bank(src_v_bank),
        .src_v_addr(src_v_addr),
        .dst_u_bank(dst_u_bank),
        .dst_u_addr(dst_u_addr),
        .dst_v_bank(dst_v_bank),
        .dst_v_addr(dst_v_addr),
        .zeta_addr(zeta_addr),
        .stage(stage),
        .bfly_idx(bfly_idx),
        .group_idx(group_idx),
        .last_issue_in_stage(last_issue_in_stage),
        .last_issue_in_transform(last_issue_in_transform),
        .stage_issue_done(stage_issue_done),
        .schedule_done(schedule_done)
    );

    // Clock generator
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer current_stage;
    integer current_bfly;
    integer group_size;
    integer expected_zeta;
    integer zeta_seen [1:127];
    integer s;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        stage_advance = 0;
        pass_count = 0;
        fail_count = 0;

        #20;
        @(posedge clk);
        rst_n = 1;
        #1;

        $display("INFO tb_ntt_scheduler_pipe: starting exhaustive execution check");

        // Start schedule
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        if (!busy) begin
            fail_count = fail_count + 1;
            $display("ERROR: scheduler not busy after start");
        end

        // Check stages
        for (current_stage = 0; current_stage < 7; current_stage = current_stage + 1) begin
            group_size = 128 >> current_stage;
            
            // Clear zeta seen list for verification of uniqueness
            for (s = 1; s <= 127; s = s + 1) begin
                zeta_seen[s] = 0;
            end

            for (current_bfly = 0; current_bfly < 128; current_bfly = current_bfly + 1) begin
                if (!issue_valid) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: issue_valid is low during active issue at stage=%0d bfly=%0d",
                             current_stage, current_bfly);
                end
                if (stage !== current_stage[2:0]) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: stage mismatch got=%0d expected=%0d", stage, current_stage);
                end
                if (bfly_idx !== current_bfly[6:0]) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: bfly_idx mismatch got=%0d expected=%0d", bfly_idx, current_bfly);
                end

                // Logical pair validation: u_idx and v_idx must differ exactly by len
                if ((src_v_idx - src_u_idx) !== group_size) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: logical indices diff got=%0d expected=%0d (u=%0d, v=%0d)",
                             src_v_idx - src_u_idx, group_size, src_u_idx, src_v_idx);
                end

                // Bank Mapping validations:
                // 1. Source read port must never collide: src_u_bank != src_v_bank
                if (src_u_bank === src_v_bank) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: bank collision src_u_bank=%b src_v_bank=%b at stage=%0d bfly=%0d",
                             src_u_bank, src_v_bank, current_stage, current_bfly);
                end
                if (dst_u_bank === dst_v_bank) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: bank collision dst_u_bank=%b dst_v_bank=%b at stage=%0d bfly=%0d u=%0d v=%0d",
                             dst_u_bank, dst_v_bank, current_stage, current_bfly,
                             src_u_idx, src_v_idx);
                end

                // Zeta address tracking:
                expected_zeta = (1 << current_stage) + (current_bfly / group_size);
                if (zeta_addr !== expected_zeta[6:0]) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: zeta_addr mismatch got=%0d expected=%0d at stage=%0d bfly=%0d",
                             zeta_addr, expected_zeta, current_stage, current_bfly);
                end
                zeta_seen[zeta_addr] = zeta_seen[zeta_addr] + 1;

                // Last issue flag validation
                if (current_bfly == 127) begin
                    if (!last_issue_in_stage) begin
                        fail_count = fail_count + 1;
                        $display("ERROR: last_issue_in_stage not asserted at stage=%0d bfly=127", current_stage);
                    end
                    if (current_stage == 6) begin
                        if (!last_issue_in_transform) begin
                            fail_count = fail_count + 1;
                            $display("ERROR: last_issue_in_transform not asserted at stage=6 bfly=127");
                        end
                    end
                end else begin
                    if (last_issue_in_stage) begin
                        fail_count = fail_count + 1;
                        $display("ERROR: last_issue_in_stage asserted early at stage=%0d bfly=%0d",
                                 current_stage, current_bfly);
                    end
                end

                @(posedge clk);
                #1;
            end

            // Check stage_issue_done pulse
            if (!stage_issue_done) begin
                fail_count = fail_count + 1;
                $display("ERROR: stage_issue_done not pulsed at end of stage %0d", current_stage);
            end
            if (issue_valid) begin
                fail_count = fail_count + 1;
                $display("ERROR: issue_valid not low during wait at stage %0d", current_stage);
            end

            // Verify zeta changes group size times, and has exactly group_size butterflies per zeta
            for (s = (1 << current_stage); s < (2 << current_stage); s = s + 1) begin
                if (zeta_seen[s] !== group_size) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: zeta %0d seen %0d times, expected %0d at stage %0d",
                             s, zeta_seen[s], group_size, current_stage);
                end
            end

            // Verify issue remains low until stage_advance is pulsed
            repeat (3) begin
                if (issue_valid) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: issue issued while waiting for advance");
                end
                @(posedge clk);
                #1;
            end

            // Advance stage
            stage_advance = 1;
            @(posedge clk);
            #1;
            stage_advance = 0;

            if (current_stage == 6) begin
                if (!schedule_done) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: schedule_done not asserted after final stage advance");
                end
                if (busy) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: scheduler busy after completion");
                end
            end else begin
                if (busy == 0) begin
                    fail_count = fail_count + 1;
                    $display("ERROR: scheduler idle before final stage");
                end
            end
        end

        // Wait to return to idle
        @(posedge clk);
        #1;

        // 2. Start-while-busy Error Check
        $display("INFO tb_ntt_scheduler_pipe: testing start-while-busy error");
        start = 1;
        @(posedge clk);
        #1;
        start = 0;
        // Trigger start while busy
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        if (!error) begin
            fail_count = fail_count + 1;
            $display("ERROR: error flag not set on start-while-busy");
        end

        // Reset to clear error
        rst_n = 0;
        @(posedge clk);
        #1;
        rst_n = 1;
        if (error) begin
            fail_count = fail_count + 1;
            $display("ERROR: error flag not cleared by reset");
        end

        // 3. Illegal Stage Advance Error Check
        $display("INFO tb_ntt_scheduler_pipe: testing illegal stage-advance error");
        stage_advance = 1;
        @(posedge clk);
        #1;
        stage_advance = 0;

        if (!error) begin
            fail_count = fail_count + 1;
            $display("ERROR: error flag not set on illegal stage_advance");
        end

        // 4. Reset from active issue check
        $display("INFO tb_ntt_scheduler_pipe: testing reset from active issue");
        rst_n = 0;
        @(posedge clk);
        #1;
        rst_n = 1;
        start = 1;
        @(posedge clk);
        #1;
        start = 0;
        repeat(5) @(posedge clk);
        // Reset while issuing
        rst_n = 0;
        @(posedge clk);
        #1;
        rst_n = 1;

        if (busy || issue_valid || error) begin
            fail_count = fail_count + 1;
            $display("ERROR: reset failed to clear FSM state");
        end

        // Count success
        if (fail_count == 0) begin
            pass_count = 896; // Represents the 896 checks
            $display("PASS tb_ntt_scheduler_pipe");
            $finish;
        end else begin
            $display("FAIL tb_ntt_scheduler_pipe");
            $fatal(1, "Mismatches observed in scheduler address-generation testbench");
        end
    end

endmodule
