`timescale 1ns/1ps

// Banked, out-of-place inverse NTT with a two-lane final normal-domain scaler.
module intt_core_pipe #(
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
    localparam RAM_READ_LATENCY = 1;
    localparam INTT_BFLY_LATENCY = 5;
    localparam INTT_ISSUE_TO_WRITE_SETUP = RAM_READ_LATENCY + INTT_BFLY_LATENCY;
    localparam INTT_ISSUE_TO_WRITE_COMMIT = INTT_ISSUE_TO_WRITE_SETUP + 1;
    localparam SCALE_MUL_LATENCY = 4;
    localparam SCALE_ISSUE_TO_WRITE_COMMIT = RAM_READ_LATENCY + SCALE_MUL_LATENCY + 1;
    localparam META_WIDTH = 72;

    localparam [3:0] ST_IDLE          = 4'd0;
    localparam [3:0] ST_PRESTART_SWAP = 4'd1;
    localparam [3:0] ST_START_SCHED   = 4'd2;
    localparam [3:0] ST_RUN           = 4'd3;
    localparam [3:0] ST_STAGE_ADVANCE = 4'd4;
    localparam [3:0] ST_SCALE_ISSUE   = 4'd5;
    localparam [3:0] ST_SCALE_DRAIN   = 4'd6;
    localparam [3:0] ST_SCALE_SWAP    = 4'd7;
    localparam [3:0] ST_DONE_PULSE    = 4'd8;

    reg [3:0] state;
    reg final_stage_latched;
    reg results_valid;

    reg [11:0] preload_first [0:127];
    reg preload_first_seen [0:127];
    reg preload_pair_written [0:127];
    reg [7:0] preload_pair_count;
    wire [6:0] preload_slot = {preload_idx[7:2], preload_idx[0]};
    wire preload_first_half = preload_en && !busy && !preload_idx[1];
    wire preload_pair_wr_en = preload_en && !busy && preload_idx[1];
    wire [7:0] preload_u_idx = {preload_idx[7:2], 1'b0, preload_idx[0]};
    wire [7:0] preload_v_idx = {preload_idx[7:2], 1'b1, preload_idx[0]};
    wire all_pairs_loaded = (preload_pair_count == 8'd128);
    assign preload_ready = !busy&&!zeroize_busy;
    reg child_zeroize_req;reg[5:0]child_done_seen;reg[6:0]scrub_addr;reg local_scrub_done;
    wire sched_zeroize_done,zeta_zeroize_done,meta_zeroize_done,bfly_zeroize_done,scale_zeroize_done,banks_zeroize_done;
    wire sched_zeroize_busy,zeta_zeroize_busy,meta_zeroize_busy,bfly_zeroize_busy,scale_zeroize_busy,banks_zeroize_busy;

    wire sched_start = (state == ST_START_SCHED);
    wire sched_stage_advance = (state == ST_STAGE_ADVANCE);
    wire swap_roles = (state == ST_PRESTART_SWAP) ||
                      (state == ST_STAGE_ADVANCE) ||
                      (state == ST_SCALE_SWAP);
    wire stage_role_swap = (state == ST_STAGE_ADVANCE);

    wire sched_busy, sched_error, sched_issue_valid;
    wire [7:0] sched_u_idx, sched_v_idx;
    wire sched_src_u_bank, sched_src_v_bank, sched_dst_u_bank, sched_dst_v_bank;
    wire [6:0] sched_src_u_addr, sched_src_v_addr, sched_dst_u_addr, sched_dst_v_addr;
    wire [6:0] sched_zeta_addr, sched_bfly_idx, sched_group_idx, sched_offset;
    wire [2:0] sched_stage;
    wire sched_last_stage, sched_last_transform, sched_stage_issue_done, sched_schedule_done;

    intt_scheduler_pipe u_scheduler (
        .clk(clk), .rst_n(rst_n), .start(sched_start),
        .stage_advance(sched_stage_advance), .busy(sched_busy), .error(sched_error),
        .issue_valid(sched_issue_valid), .src_u_idx(sched_u_idx), .src_v_idx(sched_v_idx),
        .src_u_bank(sched_src_u_bank), .src_u_addr(sched_src_u_addr),
        .src_v_bank(sched_src_v_bank), .src_v_addr(sched_src_v_addr),
        .dst_u_bank(sched_dst_u_bank), .dst_u_addr(sched_dst_u_addr),
        .dst_v_bank(sched_dst_v_bank), .dst_v_addr(sched_dst_v_addr),
        .zeta_addr(sched_zeta_addr), .stage(sched_stage), .bfly_idx(sched_bfly_idx),
        .group_idx(sched_group_idx), .offset(sched_offset),
        .last_issue_in_stage(sched_last_stage),
        .last_issue_in_transform(sched_last_transform),
        .stage_issue_done(sched_stage_issue_done), .schedule_done(sched_schedule_done),
        .zeroize_req(child_zeroize_req),.zeroize_busy(sched_zeroize_busy),.zeroize_done(sched_zeroize_done)
    );

    wire [2:0] issue_src_pair_bit = sched_stage + 3'd1;
    wire [2:0] issue_src_addr_bit = (sched_stage == 0) ? 3'd1 : sched_stage;
    wire issue_src_xor = (sched_stage != 0);
    wire [2:0] issue_dst_pair_bit = (sched_stage == 6) ? 3'd7 : sched_stage + 3'd2;
    wire [2:0] issue_dst_addr_bit = sched_stage + 3'd1;
    wire issue_dst_xor = (sched_stage != 6);

    wire intt_read_req = (state == ST_RUN) && sched_issue_valid;
    reg [7:0] scale_pair_count;
    wire scale_read_req = (state == ST_SCALE_ISSUE);
    wire legal_result_req = result_rd_req && !busy && results_valid;

    wire mem_src_rd_en = intt_read_req || scale_read_req || legal_result_req;
    wire [7:0] mem_src_index0 = intt_read_req ? sched_u_idx :
                                 scale_read_req ? {1'b0, scale_pair_count[6:0]} : result_rd_idx;
    wire [7:0] mem_src_index1 = intt_read_req ? sched_v_idx :
                                 scale_read_req ? {1'b1, scale_pair_count[6:0]} : (result_rd_idx ^ 8'h80);
    wire [2:0] mem_src_pair_bit = intt_read_req ? issue_src_pair_bit : 3'd7;
    wire [2:0] mem_src_addr_bit = intt_read_req ? issue_src_addr_bit : 3'd7;
    wire mem_src_xor_layout = intt_read_req ? issue_src_xor : 1'b0;
    wire mem_src_rd_valid;
    wire [DATA_WIDTH-1:0] mem_src_data0, mem_src_data1;

    wire [11:0] zeta_now;
    zetas_rom u_zetas_rom (.inverse(1'b0), .addr(sched_zeta_addr), .zeta(zeta_now));
    wire zeta_valid, zeta_meta_unused;
    wire [11:0] zeta_for_bfly;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12), .METADATA_WIDTH(1), .LATENCY(1))
    u_zeta_delay (
        .clk(clk), .rst_n(rst_n), .in_valid(intt_read_req), .in_payload(zeta_now),
        .in_metadata(1'b0), .out_valid(zeta_valid), .out_payload(zeta_for_bfly),
        .out_metadata(zeta_meta_unused),.zeroize_req(child_zeroize_req),
        .zeroize_busy(zeta_zeroize_busy),.zeroize_done(zeta_zeroize_done)
    );

    wire [META_WIDTH-1:0] issue_meta = {
        sched_u_idx, sched_v_idx, issue_dst_pair_bit, issue_dst_addr_bit,
        issue_dst_xor, sched_stage, sched_bfly_idx, sched_group_idx,
        sched_offset, sched_zeta_addr, sched_last_stage, sched_last_transform,
        sched_dst_u_bank, sched_dst_u_addr, sched_dst_v_bank, sched_dst_v_addr
    };
    wire [META_WIDTH-1:0] write_meta;
    wire write_meta_valid, write_meta_unused;
    fixed_latency_delay #(
        .PAYLOAD_WIDTH(META_WIDTH), .METADATA_WIDTH(1),
        .LATENCY(INTT_ISSUE_TO_WRITE_SETUP)
    ) u_write_meta_delay (
        .clk(clk), .rst_n(rst_n), .in_valid(intt_read_req), .in_payload(issue_meta),
        .in_metadata(1'b0), .out_valid(write_meta_valid), .out_payload(write_meta),
        .out_metadata(write_meta_unused),.zeroize_req(child_zeroize_req),
        .zeroize_busy(meta_zeroize_busy),.zeroize_done(meta_zeroize_done)
    );

    wire [7:0] write_u_idx = write_meta[71:64];
    wire [7:0] write_v_idx = write_meta[63:56];
    wire [2:0] write_pair_bit = write_meta[55:53];
    wire [2:0] write_addr_bit = write_meta[52:50];
    wire write_xor = write_meta[49];
    wire [2:0] write_stage = write_meta[48:46];
    wire [6:0] write_bfly_idx = write_meta[45:39];
    wire [6:0] write_group_idx = write_meta[38:32];
    wire [6:0] write_offset = write_meta[31:25];
    wire [6:0] write_zeta_addr = write_meta[24:18];
    wire write_last_stage = write_meta[17];
    wire write_last_transform = write_meta[16];
    wire write_dst_u_bank = write_meta[15];
    wire [6:0] write_dst_u_addr = write_meta[14:8];
    wire write_dst_v_bank = write_meta[7];
    wire [6:0] write_dst_v_addr = write_meta[6:0];

    wire intt_bfly_in_valid = mem_src_rd_valid && (state == ST_RUN);
    wire intt_bfly_out_valid;
    wire [11:0] intt_bfly_out0, intt_bfly_out1;
    intt_butterfly_pipe u_butterfly (
        .clk(clk), .rst_n(rst_n), .in_valid(intt_bfly_in_valid),
        .u(mem_src_data0), .v(mem_src_data1), .zeta_mont(zeta_for_bfly),
        .out_valid(intt_bfly_out_valid), .out0(intt_bfly_out0), .out1(intt_bfly_out1),
        .zeroize_req(child_zeroize_req),.zeroize_busy(bfly_zeroize_busy),.zeroize_done(bfly_zeroize_done)
    );
    wire intt_write_setup_valid = intt_bfly_out_valid && write_meta_valid && busy;

    reg intt_write_setup_valid_d;
    reg intt_write_last_stage_d;
    reg intt_write_last_transform_d;
    wire intt_write_commit_valid = intt_write_setup_valid_d;

    reg [7:0] scale_response_pair_d;
    reg scale_response_valid_d;
    wire scale_input_valid = mem_src_rd_valid &&
                             ((state == ST_SCALE_ISSUE) || (state == ST_SCALE_DRAIN));
    wire scale_out_valid;
    wire [11:0] scale_out0, scale_out1;
    wire [6:0] scale_out_pair;
    wire scale_out_last;
    intt_scaler_pipe u_scaler (
        .clk(clk), .rst_n(rst_n), .in_valid(scale_input_valid),
        .in0(mem_src_data0), .in1(mem_src_data1),
        .pair_idx(scale_response_pair_d[6:0]), .last_in(scale_response_pair_d == 8'd127),
        .out_valid(scale_out_valid), .out0(scale_out0), .out1(scale_out1),
        .pair_idx_out(scale_out_pair), .last_out(scale_out_last),
        .zeroize_req(child_zeroize_req),.zeroize_busy(scale_zeroize_busy),.zeroize_done(scale_zeroize_done)
    );
    reg scale_write_setup_valid_d;
    reg scale_write_last_d;
    wire scale_write_commit_valid = scale_write_setup_valid_d;

    wire mem_dst_wr_en = intt_write_setup_valid || scale_out_valid || preload_pair_wr_en;
    wire [7:0] mem_dst_index0 = intt_write_setup_valid ? write_u_idx :
                                 scale_out_valid ? {1'b0, scale_out_pair} : preload_u_idx;
    wire [7:0] mem_dst_index1 = intt_write_setup_valid ? write_v_idx :
                                 scale_out_valid ? {1'b1, scale_out_pair} : preload_v_idx;
    wire [2:0] mem_dst_pair_bit = intt_write_setup_valid ? write_pair_bit :
                                  scale_out_valid ? 3'd7 : 3'd1;
    wire [2:0] mem_dst_addr_bit = intt_write_setup_valid ? write_addr_bit :
                                  scale_out_valid ? 3'd7 : 3'd1;
    wire mem_dst_xor_layout = intt_write_setup_valid ? write_xor :
                               scale_out_valid ? 1'b0 : 1'b0;
    wire [DATA_WIDTH-1:0] mem_dst_data0 = intt_write_setup_valid ? intt_bfly_out0 :
                                                scale_out_valid ? scale_out0 : preload_first[preload_slot];
    wire [DATA_WIDTH-1:0] mem_dst_data1 = intt_write_setup_valid ? intt_bfly_out1 :
                                                scale_out_valid ? scale_out1 : preload_coeff;

    wire role_select;
    ntt_pingpong_banks #(.DATA_WIDTH(DATA_WIDTH)) u_banks (
        .clk(clk), .rst_n(rst_n), .swap_roles(swap_roles), .role_select(role_select),
        .src_rd_en(mem_src_rd_en), .src_index0(mem_src_index0), .src_index1(mem_src_index1),
        .src_pair_bit(mem_src_pair_bit), .src_addr_bit(mem_src_addr_bit),
        .src_xor_layout(mem_src_xor_layout), .src_rd_valid(mem_src_rd_valid),
        .src_data0(mem_src_data0), .src_data1(mem_src_data1),
        .dst_wr_en(mem_dst_wr_en), .dst_index0(mem_dst_index0), .dst_index1(mem_dst_index1),
        .dst_pair_bit(mem_dst_pair_bit), .dst_addr_bit(mem_dst_addr_bit),
        .dst_xor_layout(mem_dst_xor_layout), .dst_data0(mem_dst_data0), .dst_data1(mem_dst_data1),
        .zeroize_req(child_zeroize_req),.zeroize_busy(banks_zeroize_busy),.zeroize_done(banks_zeroize_done)
    );

    assign result_rd_valid = legal_result_req ? mem_src_rd_valid : 1'b0;
    assign result_rd_data = mem_src_data0;

    reg [10:0] accepted_read_count, ram_response_count, butterfly_input_count;
    reg [10:0] butterfly_output_count, committed_write_count;
    reg [3:0] stage_drain_count, stage_advance_count, stage_role_swap_count;
    reg [3:0] total_role_swap_count;
    reg [7:0] pending_reads, pending_butterflies, pending_writes;
    reg [15:0] inverse_cycle_count, transform_cycle_count;
    reg [15:0] scale_first_issue_cycle, scale_final_issue_cycle;
    reg [15:0] scale_final_commit_cycle, scale_swap_cycle, done_cycle;
    reg [7:0] scale_read_count, scale_response_count, scale_output_pair_count, scale_write_count;
    reg [8:0] scale_coefficient_input_count, scale_coefficient_output_count;
    reg [7:0] scale_pending_reads, scale_pending_mults, scale_pending_writes;

    wire stage_drain_ready = intt_write_commit_valid && intt_write_last_stage_d &&
        (pending_reads == 0) && (pending_butterflies == 0) &&
        (pending_writes == 1) && !intt_write_setup_valid;
    wire scale_drain_ready = scale_write_commit_valid && scale_write_last_d &&
        (scale_pending_reads == 0) && (scale_pending_mults == 0) &&
        (scale_pending_writes == 1) && !scale_out_valid;

    integer preload_i;
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE; busy <= 0; done <= 0; error <= 0;
            final_stage_latched <= 0; results_valid <= 0;
            preload_pair_count <= 0; scale_pair_count <= 0;
            intt_write_setup_valid_d <= 0; intt_write_last_stage_d <= 0;
            intt_write_last_transform_d <= 0;
            scale_response_pair_d <= 0; scale_response_valid_d <= 0;
            scale_write_setup_valid_d <= 0; scale_write_last_d <= 0;
            accepted_read_count <= 0; ram_response_count <= 0;
            butterfly_input_count <= 0; butterfly_output_count <= 0;
            committed_write_count <= 0; stage_drain_count <= 0;
            stage_advance_count <= 0; stage_role_swap_count <= 0;
            total_role_swap_count <= 0; pending_reads <= 0;
            pending_butterflies <= 0; pending_writes <= 0;
            inverse_cycle_count <= 0; transform_cycle_count <= 0;
            scale_first_issue_cycle <= 0; scale_final_issue_cycle <= 0;
            scale_final_commit_cycle <= 0; scale_swap_cycle <= 0; done_cycle <= 0;
            scale_read_count <= 0; scale_response_count <= 0;
            scale_output_pair_count <= 0; scale_write_count <= 0;
            scale_coefficient_input_count <= 0; scale_coefficient_output_count <= 0;
            scale_pending_reads <= 0; scale_pending_mults <= 0; scale_pending_writes <= 0;
            zeroize_busy<=0;zeroize_done<=0;child_zeroize_req<=0;child_done_seen<=0;
            scrub_addr<=0;local_scrub_done<=0;
            for (preload_i = 0; preload_i < 128; preload_i = preload_i + 1) begin
                preload_first_seen[preload_i] <= 0;
                preload_pair_written[preload_i] <= 0;
            end
        end else begin
            done <= 0;
            zeroize_done<=0;child_zeroize_req<=0;
            if(zeroize_req===1'b1&&!zeroize_busy)begin
                state<=ST_IDLE;busy<=1;error<=0;final_stage_latched<=0;results_valid<=0;
                preload_pair_count<=0;scale_pair_count<=0;intt_write_setup_valid_d<=0;
                intt_write_last_stage_d<=0;intt_write_last_transform_d<=0;
                scale_response_pair_d<=0;scale_response_valid_d<=0;scale_write_setup_valid_d<=0;scale_write_last_d<=0;
                accepted_read_count<=0;ram_response_count<=0;butterfly_input_count<=0;butterfly_output_count<=0;
                committed_write_count<=0;stage_drain_count<=0;stage_advance_count<=0;stage_role_swap_count<=0;total_role_swap_count<=0;
                pending_reads<=0;pending_butterflies<=0;pending_writes<=0;inverse_cycle_count<=0;transform_cycle_count<=0;
                scale_first_issue_cycle<=0;scale_final_issue_cycle<=0;scale_final_commit_cycle<=0;scale_swap_cycle<=0;done_cycle<=0;
                scale_read_count<=0;scale_response_count<=0;scale_output_pair_count<=0;scale_write_count<=0;
                scale_coefficient_input_count<=0;scale_coefficient_output_count<=0;scale_pending_reads<=0;scale_pending_mults<=0;scale_pending_writes<=0;
                zeroize_busy<=1;child_zeroize_req<=1;child_done_seen<=0;scrub_addr<=0;local_scrub_done<=0;
            end else if(zeroize_busy)begin
                child_done_seen<=child_done_seen|{banks_zeroize_done,scale_zeroize_done,bfly_zeroize_done,meta_zeroize_done,zeta_zeroize_done,sched_zeroize_done};
                if(!local_scrub_done)begin
                    preload_first[scrub_addr]<=0;preload_first_seen[scrub_addr]<=0;preload_pair_written[scrub_addr]<=0;
                    if(scrub_addr==7'd127)local_scrub_done<=1;else scrub_addr<=scrub_addr+1'b1;
                end
                if(local_scrub_done&&(&(child_done_seen|{banks_zeroize_done,scale_zeroize_done,bfly_zeroize_done,meta_zeroize_done,zeta_zeroize_done,sched_zeroize_done})))begin
                    zeroize_busy<=0;zeroize_done<=1;busy<=0;state<=ST_IDLE;
                end
            end else begin
            intt_write_setup_valid_d <= intt_write_setup_valid;
            intt_write_last_stage_d <= write_last_stage;
            intt_write_last_transform_d <= write_last_transform;
            scale_write_setup_valid_d <= scale_out_valid;
            scale_write_last_d <= scale_out_last;
            scale_response_valid_d <= scale_read_req;
            if (scale_read_req)
                scale_response_pair_d <= scale_pair_count;

            if (busy) transform_cycle_count <= transform_cycle_count + 1;
            if (busy && state <= ST_STAGE_ADVANCE) inverse_cycle_count <= inverse_cycle_count + 1;

            if (intt_read_req) begin accepted_read_count <= accepted_read_count + 1; pending_reads <= pending_reads + 1; end
            if (intt_bfly_in_valid) begin
                ram_response_count <= ram_response_count + 1;
                butterfly_input_count <= butterfly_input_count + 1;
                pending_reads <= pending_reads - 1; pending_butterflies <= pending_butterflies + 1;
            end
            if (intt_bfly_out_valid) begin
                butterfly_output_count <= butterfly_output_count + 1;
                pending_butterflies <= pending_butterflies - 1;
            end
            if (intt_write_setup_valid) pending_writes <= pending_writes + 1;
            if (intt_write_commit_valid) begin committed_write_count <= committed_write_count + 1; pending_writes <= pending_writes - 1; end
            if (intt_read_req && intt_bfly_in_valid) pending_reads <= pending_reads;
            if (intt_bfly_in_valid && intt_bfly_out_valid) pending_butterflies <= pending_butterflies;
            if (intt_write_setup_valid && intt_write_commit_valid) pending_writes <= pending_writes;

            if (scale_read_req) begin
                scale_read_count <= scale_read_count + 1; scale_pending_reads <= scale_pending_reads + 1;
                if (scale_pair_count == 0) scale_first_issue_cycle <= transform_cycle_count + 1;
                if (scale_pair_count == 127) scale_final_issue_cycle <= transform_cycle_count + 1;
            end
            if (scale_input_valid) begin
                scale_response_count <= scale_response_count + 1;
                scale_coefficient_input_count <= scale_coefficient_input_count + 2;
                scale_pending_reads <= scale_pending_reads - 1; scale_pending_mults <= scale_pending_mults + 1;
            end
            if (scale_out_valid) begin
                scale_output_pair_count <= scale_output_pair_count + 1;
                scale_coefficient_output_count <= scale_coefficient_output_count + 2;
                scale_pending_mults <= scale_pending_mults - 1; scale_pending_writes <= scale_pending_writes + 1;
            end
            if (scale_write_commit_valid) begin
                scale_write_count <= scale_write_count + 1; scale_pending_writes <= scale_pending_writes - 1;
                if (scale_write_last_d) scale_final_commit_cycle <= transform_cycle_count + 1;
            end
            if (scale_read_req && scale_input_valid) scale_pending_reads <= scale_pending_reads;
            if (scale_input_valid && scale_out_valid) scale_pending_mults <= scale_pending_mults;
            if (scale_out_valid && scale_write_commit_valid) scale_pending_writes <= scale_pending_writes;

            if (sched_error) error <= 1;
            if (busy && (start || preload_en || result_rd_req)) error <= 1;
            if (!busy && result_rd_req && !results_valid) error <= 1;

            if (preload_first_half) begin
                preload_first[preload_slot] <= preload_coeff;
                preload_first_seen[preload_slot] <= 1;
                results_valid <= 0;
            end
            if (preload_pair_wr_en) begin
                results_valid <= 0;
                if (!preload_first_seen[preload_slot]) error <= 1;
                else if (!preload_pair_written[preload_slot]) begin
                    preload_pair_written[preload_slot] <= 1;
                    preload_pair_count <= preload_pair_count + 1;
                end
            end

            case (state)
                ST_IDLE: if (start) begin
                    if (!all_pairs_loaded) error <= 1;
                    else begin
                        busy <= 1; results_valid <= 0; final_stage_latched <= 0;
                        accepted_read_count <= 0; ram_response_count <= 0;
                        butterfly_input_count <= 0; butterfly_output_count <= 0;
                        committed_write_count <= 0; stage_drain_count <= 0;
                        stage_advance_count <= 0; stage_role_swap_count <= 0;
                        total_role_swap_count <= 0; pending_reads <= 0;
                        pending_butterflies <= 0; pending_writes <= 0;
                        inverse_cycle_count <= 0; transform_cycle_count <= 0;
                        scale_first_issue_cycle <= 0; scale_final_issue_cycle <= 0;
                        scale_final_commit_cycle <= 0; scale_swap_cycle <= 0; done_cycle <= 0;
                        scale_read_count <= 0; scale_response_count <= 0;
                        scale_output_pair_count <= 0; scale_write_count <= 0;
                        scale_coefficient_input_count <= 0; scale_coefficient_output_count <= 0;
                        scale_pending_reads <= 0; scale_pending_mults <= 0; scale_pending_writes <= 0;
                        scale_pair_count <= 0; state <= ST_PRESTART_SWAP;
                    end
                end
                ST_PRESTART_SWAP: begin total_role_swap_count <= total_role_swap_count + 1; state <= ST_START_SCHED; end
                ST_START_SCHED: state <= ST_RUN;
                ST_RUN: if (stage_drain_ready) begin
                    stage_drain_count <= stage_drain_count + 1;
                    final_stage_latched <= intt_write_last_transform_d;
                    state <= ST_STAGE_ADVANCE;
                end
                ST_STAGE_ADVANCE: begin
                    stage_advance_count <= stage_advance_count + 1;
                    stage_role_swap_count <= stage_role_swap_count + 1;
                    total_role_swap_count <= total_role_swap_count + 1;
                    if (final_stage_latched) begin scale_pair_count <= 0; state <= ST_SCALE_ISSUE; end
                    else state <= ST_RUN;
                end
                ST_SCALE_ISSUE: begin
                    if (scale_pair_count == 8'd127) state <= ST_SCALE_DRAIN;
                    else scale_pair_count <= scale_pair_count + 1;
                end
                ST_SCALE_DRAIN: if (scale_drain_ready) state <= ST_SCALE_SWAP;
                ST_SCALE_SWAP: begin
                    total_role_swap_count <= total_role_swap_count + 1;
                    scale_swap_cycle <= transform_cycle_count + 1;
                    state <= ST_DONE_PULSE;
                end
                ST_DONE_PULSE: begin
                    done <= 1; busy <= 0; results_valid <= 1;
                    done_cycle <= transform_cycle_count + 1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
            end
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (rst_n && !zeroize_busy && intt_bfly_in_valid && !zeta_valid)
            $fatal(1, "INTT_ZETA_ALIGNMENT: RAM response without zeta");
        if (rst_n && !zeroize_busy && (intt_bfly_out_valid !== write_meta_valid))
            $fatal(1, "INTT_METADATA_ALIGNMENT: butterfly and metadata valid mismatch");
        if (rst_n && !zeroize_busy && intt_write_setup_valid &&
            ((write_dst_u_bank == write_dst_v_bank) ||
             (write_bfly_idx > 127) || (write_zeta_addr == 0)))
            $fatal(1, "INTT_WRITE_METADATA: invalid delayed transaction");
        if (rst_n && !zeroize_busy && scale_input_valid && !scale_response_valid_d)
            $fatal(1, "INTT_SCALE_ALIGNMENT: response without request metadata");
        if (rst_n && !zeroize_busy && swap_roles && (mem_src_rd_en || mem_dst_wr_en || mem_src_rd_valid))
            $fatal(1, "INTT_ROLE_SWAP: active or pending memory traffic");
    end
`endif
endmodule
