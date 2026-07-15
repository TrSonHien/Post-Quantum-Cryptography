`timescale 1ns/1ps
`include "kyber_params.vh"

// Banked, out-of-place, pipelined forward NTT core candidate v0.
//
// External coefficients are canonical unsigned values in [0,3328]. The core
// preloads one lower/upper pair into the destination role, performs one idle
// role swap before scheduling, then drains and swaps once per NTT stage.
module ntt_core_pipe #(
    parameter DATA_WIDTH = 12
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    output reg                   busy,
    output reg                   done,
    output reg                   error,

    input  wire                  preload_en,
    input  wire [7:0]            preload_idx,
    input  wire [11:0]           preload_coeff,
    output wire                  preload_ready,

    input  wire                  result_rd_req,
    input  wire [7:0]            result_rd_idx,
    output wire                  result_rd_valid,
    output wire [11:0]           result_rd_data,
    input  wire                  zeroize_req,
    output reg                   zeroize_busy,
    output reg                   zeroize_done
);

    localparam RAM_READ_LATENCY        = 1;
    localparam BUTTERFLY_LATENCY       = 5;
    localparam ISSUE_TO_WRITE_SETUP    = RAM_READ_LATENCY + BUTTERFLY_LATENCY;
    localparam ISSUE_TO_WRITE_COMMIT   = ISSUE_TO_WRITE_SETUP + 1;

    localparam [2:0] ST_IDLE           = 3'd0;
    localparam [2:0] ST_PRESTART_SWAP  = 3'd1;
    localparam [2:0] ST_START_SCHED    = 3'd2;
    localparam [2:0] ST_RUN            = 3'd3;
    localparam [2:0] ST_STAGE_ADVANCE  = 3'd4;
    localparam [2:0] ST_DONE_PULSE     = 3'd5;

    localparam META_WIDTH = 81;

    reg [2:0] state;
    reg       final_stage_latched;
    reg       results_valid;

    reg [11:0] preload_lo [0:127];
    reg        preload_lo_seen [0:127];
    reg        preload_pair_written [0:127];
    reg [7:0]  preload_pair_count;

    wire all_pairs_loaded = (preload_pair_count == 8'd128);
    assign preload_ready = !busy && !zeroize_busy;
    reg child_zeroize_req;reg[4:0]child_done_seen;reg[6:0]scrub_addr;reg local_scrub_done;
    wire sched_zeroize_done,zeta_zeroize_done,meta_zeroize_done,bfly_zeroize_done,banks_zeroize_done;
    wire sched_zeroize_busy,zeta_zeroize_busy,meta_zeroize_busy,bfly_zeroize_busy,banks_zeroize_busy;

    function [2:0] fwd_src_pair_bit;
        input [2:0] stage;
        begin
            case (stage)
                3'd0: fwd_src_pair_bit = 3'd7;
                3'd1: fwd_src_pair_bit = 3'd7;
                3'd2: fwd_src_pair_bit = 3'd6;
                3'd3: fwd_src_pair_bit = 3'd5;
                3'd4: fwd_src_pair_bit = 3'd4;
                3'd5: fwd_src_pair_bit = 3'd3;
                default: fwd_src_pair_bit = 3'd2;
            endcase
        end
    endfunction

    function [2:0] fwd_src_addr_bit;
        input [2:0] stage;
        begin
            case (stage)
                3'd0: fwd_src_addr_bit = 3'd7;
                3'd1: fwd_src_addr_bit = 3'd6;
                3'd2: fwd_src_addr_bit = 3'd5;
                3'd3: fwd_src_addr_bit = 3'd4;
                3'd4: fwd_src_addr_bit = 3'd3;
                3'd5: fwd_src_addr_bit = 3'd2;
                default: fwd_src_addr_bit = 3'd1;
            endcase
        end
    endfunction

    function [2:0] fwd_dst_pair_bit;
        input [2:0] stage;
        begin
            case (stage)
                3'd0: fwd_dst_pair_bit = 3'd7;
                3'd1: fwd_dst_pair_bit = 3'd6;
                3'd2: fwd_dst_pair_bit = 3'd5;
                3'd3: fwd_dst_pair_bit = 3'd4;
                3'd4: fwd_dst_pair_bit = 3'd3;
                3'd5: fwd_dst_pair_bit = 3'd2;
                default: fwd_dst_pair_bit = 3'd1;
            endcase
        end
    endfunction

    function [2:0] fwd_dst_addr_bit;
        input [2:0] stage;
        begin
            case (stage)
                3'd0: fwd_dst_addr_bit = 3'd6;
                3'd1: fwd_dst_addr_bit = 3'd5;
                3'd2: fwd_dst_addr_bit = 3'd4;
                3'd3: fwd_dst_addr_bit = 3'd3;
                3'd4: fwd_dst_addr_bit = 3'd2;
                default: fwd_dst_addr_bit = 3'd1;
            endcase
        end
    endfunction

    wire sched_start = (state == ST_START_SCHED);
    wire sched_stage_advance = (state == ST_STAGE_ADVANCE);
    wire swap_roles = (state == ST_PRESTART_SWAP) || (state == ST_STAGE_ADVANCE);
    wire stage_role_swap = (state == ST_STAGE_ADVANCE);

    wire       sched_busy;
    wire       sched_error;
    wire       sched_issue_valid;
    wire [7:0] sched_src_u_idx;
    wire [7:0] sched_src_v_idx;
    wire       sched_src_u_bank;
    wire [6:0] sched_src_u_addr;
    wire       sched_src_v_bank;
    wire [6:0] sched_src_v_addr;
    wire       sched_dst_u_bank;
    wire [6:0] sched_dst_u_addr;
    wire       sched_dst_v_bank;
    wire [6:0] sched_dst_v_addr;
    wire [6:0] sched_zeta_addr;
    wire [2:0] sched_stage;
    wire [6:0] sched_bfly_idx;
    wire [6:0] sched_group_idx;
    wire       sched_last_issue_in_stage;
    wire       sched_last_issue_in_transform;
    wire       sched_stage_issue_done;
    wire       sched_schedule_done;

    ntt_scheduler_pipe u_scheduler (
        .clk(clk),
        .rst_n(rst_n),
        .start(sched_start),
        .stage_advance(sched_stage_advance),
        .busy(sched_busy),
        .error(sched_error),
        .issue_valid(sched_issue_valid),
        .src_u_idx(sched_src_u_idx),
        .src_v_idx(sched_src_v_idx),
        .src_u_bank(sched_src_u_bank),
        .src_u_addr(sched_src_u_addr),
        .src_v_bank(sched_src_v_bank),
        .src_v_addr(sched_src_v_addr),
        .dst_u_bank(sched_dst_u_bank),
        .dst_u_addr(sched_dst_u_addr),
        .dst_v_bank(sched_dst_v_bank),
        .dst_v_addr(sched_dst_v_addr),
        .zeta_addr(sched_zeta_addr),
        .stage(sched_stage),
        .bfly_idx(sched_bfly_idx),
        .group_idx(sched_group_idx),
        .last_issue_in_stage(sched_last_issue_in_stage),
        .last_issue_in_transform(sched_last_issue_in_transform),
        .stage_issue_done(sched_stage_issue_done),
        .schedule_done(sched_schedule_done),.zeroize_req(child_zeroize_req),
        .zeroize_busy(sched_zeroize_busy),.zeroize_done(sched_zeroize_done)
    );

    wire [2:0] issue_src_pair_bit = fwd_src_pair_bit(sched_stage);
    wire [2:0] issue_src_addr_bit = fwd_src_addr_bit(sched_stage);
    wire       issue_src_xor = (sched_stage != 3'd0);
    wire [2:0] issue_dst_pair_bit = fwd_dst_pair_bit(sched_stage);
    wire [2:0] issue_dst_addr_bit = fwd_dst_addr_bit(sched_stage);
    wire       issue_dst_xor = (sched_stage != 3'd6);

    wire core_read_req = (state == ST_RUN) && sched_issue_valid;
    wire legal_result_req = result_rd_req && !busy && results_valid;
    wire preload_lower = preload_en && !busy && !preload_idx[7];
    wire preload_pair_wr_en = preload_en && !busy && preload_idx[7];

    wire mem_src_rd_en = core_read_req || legal_result_req;
    wire [7:0] mem_src_index0 = core_read_req ? sched_src_u_idx : result_rd_idx;
    wire [7:0] mem_src_index1 = core_read_req ? sched_src_v_idx : (result_rd_idx ^ 8'd2);
    wire [2:0] mem_src_pair_bit = core_read_req ? issue_src_pair_bit : 3'd1;
    wire [2:0] mem_src_addr_bit = core_read_req ? issue_src_addr_bit : 3'd1;
    wire       mem_src_xor_layout = core_read_req ? issue_src_xor : 1'b0;
    wire       mem_src_rd_valid;
    wire [DATA_WIDTH-1:0] mem_src_data0;
    wire [DATA_WIDTH-1:0] mem_src_data1;

    wire [11:0] zeta_now;
    zetas_rom u_zetas_rom (
        .inverse(1'b0),
        .addr(sched_zeta_addr),
        .zeta(zeta_now)
    );

    wire        zeta_valid;
    wire [11:0] zeta_for_bfly;
    wire        zeta_meta_unused;
    fixed_latency_delay #(
        .PAYLOAD_WIDTH(12),
        .METADATA_WIDTH(1),
        .LATENCY(RAM_READ_LATENCY)
    ) u_zeta_delay (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(core_read_req),
        .in_payload(zeta_now),
        .in_metadata(1'b0),
        .out_valid(zeta_valid),
        .out_payload(zeta_for_bfly),
        .out_metadata(zeta_meta_unused),.zeroize_req(child_zeroize_req),
        .zeroize_busy(zeta_zeroize_busy),.zeroize_done(zeta_zeroize_done)
    );

    wire [META_WIDTH-1:0] issue_meta_payload = {
        sched_src_u_idx,
        sched_src_v_idx,
        issue_dst_pair_bit,
        issue_dst_addr_bit,
        issue_dst_xor,
        sched_stage,
        sched_bfly_idx,
        sched_group_idx,
        sched_zeta_addr,
        sched_last_issue_in_stage,
        sched_last_issue_in_transform,
        sched_dst_u_bank,
        sched_dst_u_addr,
        sched_dst_v_bank,
        sched_dst_v_addr,
        sched_src_u_bank,
        sched_src_u_addr,
        sched_src_v_bank,
        sched_src_v_addr
    };

    wire [META_WIDTH-1:0] write_meta_payload;
    wire                  write_meta_valid;
    wire                  write_meta_unused;
    fixed_latency_delay #(
        .PAYLOAD_WIDTH(META_WIDTH),
        .METADATA_WIDTH(1),
        .LATENCY(ISSUE_TO_WRITE_SETUP)
    ) u_write_metadata_delay (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(core_read_req),
        .in_payload(issue_meta_payload),
        .in_metadata(1'b0),
        .out_valid(write_meta_valid),
        .out_payload(write_meta_payload),
        .out_metadata(write_meta_unused),.zeroize_req(child_zeroize_req),
        .zeroize_busy(meta_zeroize_busy),.zeroize_done(meta_zeroize_done)
    );

    wire [7:0] write_u_idx = write_meta_payload[80:73];
    wire [7:0] write_v_idx = write_meta_payload[72:65];
    wire [2:0] write_pair_bit = write_meta_payload[64:62];
    wire [2:0] write_addr_bit = write_meta_payload[61:59];
    wire       write_xor_layout = write_meta_payload[58];
    wire [2:0] write_stage = write_meta_payload[57:55];
    wire [6:0] write_bfly_idx = write_meta_payload[54:48];
    wire [6:0] write_group_idx = write_meta_payload[47:41];
    wire [6:0] write_zeta_addr = write_meta_payload[40:34];
    wire       write_last_issue_in_stage = write_meta_payload[33];
    wire       write_last_issue_in_transform = write_meta_payload[32];
    wire       write_dst_u_bank = write_meta_payload[31];
    wire [6:0] write_dst_u_addr = write_meta_payload[30:24];
    wire       write_dst_v_bank = write_meta_payload[23];
    wire [6:0] write_dst_v_addr = write_meta_payload[22:16];

    wire bfly_in_valid = mem_src_rd_valid && busy;
    wire bfly_out_valid;
    wire [11:0] bfly_out0;
    wire [11:0] bfly_out1;

    butterfly_pipe u_butterfly (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(bfly_in_valid),
        .u(mem_src_data0),
        .v(mem_src_data1),
        .zeta_mont(zeta_for_bfly),
        .out_valid(bfly_out_valid),
        .out0(bfly_out0),
        .out1(bfly_out1),.zeroize_req(child_zeroize_req),
        .zeroize_busy(bfly_zeroize_busy),.zeroize_done(bfly_zeroize_done)
    );

    wire run_write_setup_valid = bfly_out_valid && write_meta_valid && busy;
    reg  write_setup_valid_d;
    reg  write_setup_last_stage_d;
    reg  write_setup_last_transform_d;
    reg  [2:0] write_setup_stage_d;

    wire write_commit_valid = write_setup_valid_d;
    wire write_commit_last_stage = write_setup_last_stage_d;
    wire write_commit_last_transform = write_setup_last_transform_d;

    wire mem_dst_wr_en = run_write_setup_valid || preload_pair_wr_en;
    wire [7:0] preload_u_idx = {1'b0, preload_idx[6:0]};
    wire [7:0] preload_v_idx = {1'b1, preload_idx[6:0]};
    wire [7:0] mem_dst_index0 = run_write_setup_valid ? write_u_idx : preload_u_idx;
    wire [7:0] mem_dst_index1 = run_write_setup_valid ? write_v_idx : preload_v_idx;
    wire [2:0] mem_dst_pair_bit = run_write_setup_valid ? write_pair_bit : 3'd7;
    wire [2:0] mem_dst_addr_bit = run_write_setup_valid ? write_addr_bit : 3'd7;
    wire       mem_dst_xor_layout = run_write_setup_valid ? write_xor_layout : 1'b0;
    wire [DATA_WIDTH-1:0] mem_dst_data0 =
        run_write_setup_valid ? bfly_out0 : preload_lo[preload_idx[6:0]];
    wire [DATA_WIDTH-1:0] mem_dst_data1 =
        run_write_setup_valid ? bfly_out1 : preload_coeff;

    wire role_select;
    ntt_pingpong_banks #(.DATA_WIDTH(DATA_WIDTH)) u_banks (
        .clk(clk),
        .rst_n(rst_n),
        .swap_roles(swap_roles),
        .role_select(role_select),
        .src_rd_en(mem_src_rd_en),
        .src_index0(mem_src_index0),
        .src_index1(mem_src_index1),
        .src_pair_bit(mem_src_pair_bit),
        .src_addr_bit(mem_src_addr_bit),
        .src_xor_layout(mem_src_xor_layout),
        .src_rd_valid(mem_src_rd_valid),
        .src_data0(mem_src_data0),
        .src_data1(mem_src_data1),
        .dst_wr_en(mem_dst_wr_en),
        .dst_index0(mem_dst_index0),
        .dst_index1(mem_dst_index1),
        .dst_pair_bit(mem_dst_pair_bit),
        .dst_addr_bit(mem_dst_addr_bit),
        .dst_xor_layout(mem_dst_xor_layout),
        .dst_data0(mem_dst_data0),
        .dst_data1(mem_dst_data1),.zeroize_req(child_zeroize_req),
        .zeroize_busy(banks_zeroize_busy),.zeroize_done(banks_zeroize_done)
    );

    assign result_rd_valid = legal_result_req ? mem_src_rd_valid : 1'b0;
    assign result_rd_data = mem_src_data0;

    reg [10:0] accepted_read_count;
    reg [10:0] ram_response_count;
    reg [10:0] butterfly_input_count;
    reg [10:0] butterfly_output_count;
    reg [10:0] committed_write_count;
    reg [3:0]  stage_drain_count;
    reg [3:0]  stage_advance_count;
    reg [3:0]  stage_role_swap_count;
    reg [3:0]  total_role_swap_count;
    reg [7:0]  pending_reads;
    reg [7:0]  pending_butterflies;
    reg [7:0]  pending_writes;
    reg [15:0] transform_cycle_count;

    wire stage_drain_ready =
        write_commit_valid &&
        write_commit_last_stage &&
        (pending_reads == 8'd0) &&
        (pending_butterflies == 8'd0) &&
        (pending_writes == 8'd1) &&
        !run_write_setup_valid;

    integer preload_i;
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            final_stage_latched <= 1'b0;
            results_valid <= 1'b0;
            preload_pair_count <= 8'd0;
            write_setup_valid_d <= 1'b0;
            write_setup_last_stage_d <= 1'b0;
            write_setup_last_transform_d <= 1'b0;
            write_setup_stage_d <= 3'd0;
            accepted_read_count <= 11'd0;
            ram_response_count <= 11'd0;
            butterfly_input_count <= 11'd0;
            butterfly_output_count <= 11'd0;
            committed_write_count <= 11'd0;
            stage_drain_count <= 4'd0;
            stage_advance_count <= 4'd0;
            stage_role_swap_count <= 4'd0;
            total_role_swap_count <= 4'd0;
            pending_reads <= 8'd0;
            pending_butterflies <= 8'd0;
            pending_writes <= 8'd0;
            transform_cycle_count <= 16'd0;
            zeroize_busy <= 1'b0;zeroize_done <= 1'b0;child_zeroize_req <= 1'b0;
            child_done_seen <= 5'd0;scrub_addr <= 7'd0;local_scrub_done <= 1'b0;
            for (preload_i = 0; preload_i < 128; preload_i = preload_i + 1) begin
                preload_lo_seen[preload_i] <= 1'b0;
                preload_pair_written[preload_i] <= 1'b0;
            end
        end else begin
            done <= 1'b0;
            zeroize_done <= 1'b0;child_zeroize_req <= 1'b0;
            if(zeroize_req===1'b1&&!zeroize_busy)begin
                state<=ST_IDLE;busy<=1;error<=0;results_valid<=0;final_stage_latched<=0;
                preload_pair_count<=0;write_setup_valid_d<=0;write_setup_last_stage_d<=0;
                write_setup_last_transform_d<=0;write_setup_stage_d<=0;
                accepted_read_count<=0;ram_response_count<=0;butterfly_input_count<=0;
                butterfly_output_count<=0;committed_write_count<=0;stage_drain_count<=0;
                stage_advance_count<=0;stage_role_swap_count<=0;total_role_swap_count<=0;
                pending_reads<=0;pending_butterflies<=0;pending_writes<=0;transform_cycle_count<=0;
                zeroize_busy<=1;child_zeroize_req<=1;child_done_seen<=0;scrub_addr<=0;local_scrub_done<=0;
            end else if(zeroize_busy)begin
                child_done_seen<=child_done_seen|{banks_zeroize_done,bfly_zeroize_done,meta_zeroize_done,zeta_zeroize_done,sched_zeroize_done};
                if(!local_scrub_done)begin
                    preload_lo[scrub_addr]<=0;preload_lo_seen[scrub_addr]<=0;preload_pair_written[scrub_addr]<=0;
                    if(scrub_addr==7'd127)local_scrub_done<=1;else scrub_addr<=scrub_addr+1'b1;
                end
                if(local_scrub_done && (&(child_done_seen|{banks_zeroize_done,bfly_zeroize_done,meta_zeroize_done,zeta_zeroize_done,sched_zeroize_done})))begin
                    zeroize_busy<=0;zeroize_done<=1;busy<=0;state<=ST_IDLE;
                end
            end else begin
            write_setup_valid_d <= run_write_setup_valid;
            write_setup_last_stage_d <= write_last_issue_in_stage;
            write_setup_last_transform_d <= write_last_issue_in_transform;
            write_setup_stage_d <= write_stage;

            if (busy)
                transform_cycle_count <= transform_cycle_count + 16'd1;

            if (core_read_req) begin
                accepted_read_count <= accepted_read_count + 11'd1;
                pending_reads <= pending_reads + 8'd1;
            end
            if (bfly_in_valid) begin
                ram_response_count <= ram_response_count + 11'd1;
                butterfly_input_count <= butterfly_input_count + 11'd1;
                pending_reads <= pending_reads - 8'd1;
                pending_butterflies <= pending_butterflies + 8'd1;
            end
            if (bfly_out_valid) begin
                butterfly_output_count <= butterfly_output_count + 11'd1;
                pending_butterflies <= pending_butterflies - 8'd1;
            end
            if (run_write_setup_valid) begin
                pending_writes <= pending_writes + 8'd1;
            end
            if (write_commit_valid) begin
                committed_write_count <= committed_write_count + 11'd1;
                pending_writes <= pending_writes - 8'd1;
            end
            if (core_read_req && bfly_in_valid)
                pending_reads <= pending_reads;
            if (bfly_in_valid && bfly_out_valid)
                pending_butterflies <= pending_butterflies;
            if (run_write_setup_valid && write_commit_valid)
                pending_writes <= pending_writes;

            if (sched_error)
                error <= 1'b1;

            if (preload_lower) begin
                preload_lo[preload_idx[6:0]] <= preload_coeff;
                preload_lo_seen[preload_idx[6:0]] <= 1'b1;
                results_valid <= 1'b0;
            end

            if (preload_pair_wr_en) begin
                results_valid <= 1'b0;
                if (!preload_lo_seen[preload_idx[6:0]]) begin
                    error <= 1'b1;
                end else if (!preload_pair_written[preload_idx[6:0]]) begin
                    preload_pair_written[preload_idx[6:0]] <= 1'b1;
                    preload_pair_count <= preload_pair_count + 8'd1;
                end
            end

            if (busy && (start || preload_en || result_rd_req))
                error <= 1'b1;
            if (!busy && result_rd_req && !results_valid)
                error <= 1'b1;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        if (!all_pairs_loaded) begin
                            error <= 1'b1;
                        end else begin
                            busy <= 1'b1;
                            results_valid <= 1'b0;
                            final_stage_latched <= 1'b0;
                            accepted_read_count <= 11'd0;
                            ram_response_count <= 11'd0;
                            butterfly_input_count <= 11'd0;
                            butterfly_output_count <= 11'd0;
                            committed_write_count <= 11'd0;
                            stage_drain_count <= 4'd0;
                            stage_advance_count <= 4'd0;
                            stage_role_swap_count <= 4'd0;
                            total_role_swap_count <= 4'd0;
                            pending_reads <= 8'd0;
                            pending_butterflies <= 8'd0;
                            pending_writes <= 8'd0;
                            transform_cycle_count <= 16'd0;
                            state <= ST_PRESTART_SWAP;
                        end
                    end
                end

                ST_PRESTART_SWAP: begin
                    total_role_swap_count <= total_role_swap_count + 4'd1;
                    state <= ST_START_SCHED;
                end

                ST_START_SCHED: begin
                    state <= ST_RUN;
                end

                ST_RUN: begin
                    if (stage_drain_ready) begin
                        stage_drain_count <= stage_drain_count + 4'd1;
                        final_stage_latched <= write_commit_last_transform;
                        state <= ST_STAGE_ADVANCE;
                    end
                end

                ST_STAGE_ADVANCE: begin
                    stage_advance_count <= stage_advance_count + 4'd1;
                    stage_role_swap_count <= stage_role_swap_count + 4'd1;
                    total_role_swap_count <= total_role_swap_count + 4'd1;
                    if (final_stage_latched) begin
                        state <= ST_DONE_PULSE;
                    end else begin
                        state <= ST_RUN;
                    end
                end

                ST_DONE_PULSE: begin
                    done <= 1'b1;
                    busy <= 1'b0;
                    results_valid <= 1'b1;
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
            end
        end
    end

`ifndef SYNTHESIS
    wire dbg_dst_u_bank;
    wire [6:0] dbg_dst_u_addr;
    wire dbg_dst_v_bank;
    wire [6:0] dbg_dst_v_addr;
    wire dbg_mem_dst_bank0;
    wire [6:0] dbg_mem_dst_addr0;
    wire dbg_mem_dst_bank1;
    wire [6:0] dbg_mem_dst_addr1;

    ntt_bank_map u_dbg_dst_u_map (
        .logical_index(write_u_idx),
        .pair_bit(write_pair_bit),
        .addr_bit(write_addr_bit),
        .xor_layout(write_xor_layout),
        .bank(dbg_dst_u_bank),
        .bank_addr(dbg_dst_u_addr)
    );

    ntt_bank_map u_dbg_dst_v_map (
        .logical_index(write_v_idx),
        .pair_bit(write_pair_bit),
        .addr_bit(write_addr_bit),
        .xor_layout(write_xor_layout),
        .bank(dbg_dst_v_bank),
        .bank_addr(dbg_dst_v_addr)
    );

    ntt_bank_map u_dbg_mem_dst0_map (
        .logical_index(mem_dst_index0),
        .pair_bit(mem_dst_pair_bit),
        .addr_bit(mem_dst_addr_bit),
        .xor_layout(mem_dst_xor_layout),
        .bank(dbg_mem_dst_bank0),
        .bank_addr(dbg_mem_dst_addr0)
    );

    ntt_bank_map u_dbg_mem_dst1_map (
        .logical_index(mem_dst_index1),
        .pair_bit(mem_dst_pair_bit),
        .addr_bit(mem_dst_addr_bit),
        .xor_layout(mem_dst_xor_layout),
        .bank(dbg_mem_dst_bank1),
        .bank_addr(dbg_mem_dst_addr1)
    );

    always @(posedge clk) begin
        if (rst_n && !zeroize_busy) begin
            if (zeta_valid !== bfly_in_valid) begin
                $display("NTT_CORE_PIPE_ALIGN: zeta_valid=%b bfly_in_valid=%b", zeta_valid, bfly_in_valid);
                $fatal(1);
            end
            if (write_meta_valid !== bfly_out_valid) begin
                $display("NTT_CORE_PIPE_ALIGN: write_meta_valid=%b bfly_out_valid=%b", write_meta_valid, bfly_out_valid);
                $fatal(1);
            end
            if (run_write_setup_valid) begin
                if ((dbg_dst_u_bank !== write_dst_u_bank) ||
                    (dbg_dst_u_addr !== write_dst_u_addr) ||
                    (dbg_dst_v_bank !== write_dst_v_bank) ||
                    (dbg_dst_v_addr !== write_dst_v_addr)) begin
                    $display("NTT_CORE_PIPE_META: stage=%0d bfly=%0d zeta=%0d",
                             write_stage, write_bfly_idx, write_zeta_addr);
                    $display(" expected dst u=%0d/%0d v=%0d/%0d got u=%0d/%0d v=%0d/%0d",
                             write_dst_u_bank, write_dst_u_addr, write_dst_v_bank, write_dst_v_addr,
                             dbg_dst_u_bank, dbg_dst_u_addr, dbg_dst_v_bank, dbg_dst_v_addr);
                    $fatal(1);
                end
            end
            if (mem_dst_wr_en && (dbg_mem_dst_bank0 === dbg_mem_dst_bank1)) begin
                $display("NTT_CORE_PIPE_DST_COLLISION: preload=%b run=%b idx0=%0d idx1=%0d p=%0d r=%0d xor=%0d bank=%0d addr0=%0d addr1=%0d",
                         preload_pair_wr_en, run_write_setup_valid,
                         mem_dst_index0, mem_dst_index1,
                         mem_dst_pair_bit, mem_dst_addr_bit, mem_dst_xor_layout,
                         dbg_mem_dst_bank0, dbg_mem_dst_addr0, dbg_mem_dst_addr1);
                $display("NTT_CORE_PIPE_DST_COLLISION_META: state=%0d stage=%0d group=%0d bfly=%0d zeta=%0d last_stage=%b last_transform=%b",
                         state, write_stage, write_group_idx, write_bfly_idx,
                         write_zeta_addr, write_last_issue_in_stage,
                         write_last_issue_in_transform);
            end
            if (bfly_in_valid && pending_reads == 8'd0 && !core_read_req) begin
                $display("NTT_CORE_PIPE_UNDERFLOW: pending_reads");
                $fatal(1);
            end
            if (bfly_out_valid && pending_butterflies == 8'd0 && !bfly_in_valid) begin
                $display("NTT_CORE_PIPE_UNDERFLOW: pending_butterflies");
                $fatal(1);
            end
            if (write_commit_valid && pending_writes == 8'd0 && !run_write_setup_valid) begin
                $display("NTT_CORE_PIPE_UNDERFLOW: pending_writes");
                $fatal(1);
            end
        end
    end
`endif

endmodule
