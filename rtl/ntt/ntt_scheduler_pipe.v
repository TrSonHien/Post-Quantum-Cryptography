`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: ntt_scheduler_pipe
// Description:
//   Fmax-oriented forward NTT address scheduler candidate v0.
//   Generates conflict-free bank mapping schedules for Cooley-Tukey Radix-2 NTT.
//
// Operation:
//   - 7 stages (0..6)
//   - 128 butterfly requests per stage (896 total)
//   - II = 1 during ST_ISSUE
//   - Pauses at end of each stage, pulsing stage_issue_done
//   - Awaits stage_advance from core to transition state
//
// Layout transitions:
//   Stage 0: b=i7        a=rm7 -> b=i7^i6 a=rm6
//   Stage 1: b=i7^i6     a=rm6 -> b=i6^i5 a=rm5
//   Stage 2: b=i6^i5     a=rm5 -> b=i5^i4 a=rm4
//   Stage 3: b=i5^i4     a=rm4 -> b=i4^i3 a=rm3
//   Stage 4: b=i4^i3     a=rm3 -> b=i3^i2 a=rm2
//   Stage 5: b=i3^i2     a=rm2 -> b=i2^i1 a=rm1
//   Stage 6: b=i2^i1     a=rm1 -> b=i1    a=rm1
// -----------------------------------------------------------------------------
module ntt_scheduler_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        stage_advance,
    output reg         busy,
    output reg         error,
    output reg         issue_valid,
    output wire [7:0]  src_u_idx,
    output wire [7:0]  src_v_idx,
    output wire        src_u_bank,
    output wire [6:0]  src_u_addr,
    output wire        src_v_bank,
    output wire [6:0]  src_v_addr,
    output wire        dst_u_bank,
    output wire [6:0]  dst_u_addr,
    output wire        dst_v_bank,
    output wire [6:0]  dst_v_addr,
    output wire [6:0]  zeta_addr,
    output reg  [2:0]  stage,
    output wire [6:0]  bfly_idx,
    output wire [6:0]  group_idx,
    output wire        last_issue_in_stage,
    output wire        last_issue_in_transform,
    output reg         stage_issue_done,
    output reg         schedule_done
);

    // States
    localparam [1:0] ST_IDLE  = 2'b00;
    localparam [1:0] ST_ISSUE = 2'b01;
    localparam [1:0] ST_WAIT  = 2'b10;

    reg [1:0] state;
    reg [6:0] bfly_cnt;

    // Derived loop parameters
    wire [7:0] len;
    wire [7:0] j;
    wire [7:0] offset;

    assign len       = 8'd128 >> stage;
    assign bfly_idx   = bfly_cnt;
    assign group_idx  = bfly_cnt >> (3'd7 - stage);
    assign offset     = bfly_cnt & (len - 8'd1);

    assign j          = (group_idx * (len << 1)) + offset;
    assign src_u_idx  = j;
    assign src_v_idx  = j + len;

    assign zeta_addr  = (7'd1 << stage) + group_idx;

    assign last_issue_in_stage     = (bfly_cnt == 7'd127);
    assign last_issue_in_transform = (stage == 3'd6) && last_issue_in_stage;

    // Mapping SDC layout transition parameters
    wire [2:0] src_p = (stage == 3'd0) ? 3'd7 :
                       (stage == 3'd1) ? 3'd7 :
                       (stage == 3'd2) ? 3'd6 :
                       (stage == 3'd3) ? 3'd5 :
                       (stage == 3'd4) ? 3'd4 :
                       (stage == 3'd5) ? 3'd3 : 3'd2;

    wire [2:0] src_r = (stage == 3'd0) ? 3'd7 :
                       (stage == 3'd1) ? 3'd6 :
                       (stage == 3'd2) ? 3'd5 :
                       (stage == 3'd3) ? 3'd4 :
                       (stage == 3'd4) ? 3'd3 :
                       (stage == 3'd5) ? 3'd2 : 3'd1;
    wire       src_xor = (stage != 3'd0);

    wire [2:0] dst_p = (stage == 3'd0) ? 3'd7 :
                       (stage == 3'd1) ? 3'd6 :
                       (stage == 3'd2) ? 3'd5 :
                       (stage == 3'd3) ? 3'd4 :
                       (stage == 3'd4) ? 3'd3 :
                       (stage == 3'd5) ? 3'd2 : 3'd1;

    wire [2:0] dst_r = (stage == 3'd0) ? 3'd6 :
                       (stage == 3'd1) ? 3'd5 :
                       (stage == 3'd2) ? 3'd4 :
                       (stage == 3'd3) ? 3'd3 :
                       (stage == 3'd4) ? 3'd2 : 3'd1;
    wire       dst_xor = (stage != 3'd6);

    // Bank Mapping Instantiations
    ntt_bank_map u_src_map (
        .logical_index(src_u_idx),
        .pair_bit(src_p),
        .addr_bit(src_r),
        .xor_layout(src_xor),
        .bank(src_u_bank),
        .bank_addr(src_u_addr)
    );

    ntt_bank_map v_src_map (
        .logical_index(src_v_idx),
        .pair_bit(src_p),
        .addr_bit(src_r),
        .xor_layout(src_xor),
        .bank(src_v_bank),
        .bank_addr(src_v_addr)
    );

    ntt_bank_map u_dst_map (
        .logical_index(src_u_idx),
        .pair_bit(dst_p),
        .addr_bit(dst_r),
        .xor_layout(dst_xor),
        .bank(dst_u_bank),
        .bank_addr(dst_u_addr)
    );

    ntt_bank_map v_dst_map (
        .logical_index(src_v_idx),
        .pair_bit(dst_p),
        .addr_bit(dst_r),
        .xor_layout(dst_xor),
        .bank(dst_v_bank),
        .bank_addr(dst_v_addr)
    );

    // Controller FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            busy             <= 1'b0;
            error            <= 1'b0;
            issue_valid      <= 1'b0;
            stage            <= 3'd0;
            bfly_cnt         <= 7'd0;
            stage_issue_done <= 1'b0;
            schedule_done    <= 1'b0;
        end else begin
            stage_issue_done <= 1'b0;
            schedule_done    <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        busy        <= 1'b1;
                        state       <= ST_ISSUE;
                        stage       <= 3'd0;
                        bfly_cnt    <= 7'd0;
                        issue_valid <= 1'b1;
                    end
                    if (stage_advance) begin
                        error <= 1'b1;
                    end
                end

                ST_ISSUE: begin
                    if (start) begin
                        error <= 1'b1;
                    end
                    if (stage_advance) begin
                        error <= 1'b1;
                    end

                    if (bfly_cnt == 7'd127) begin
                        state            <= ST_WAIT;
                        issue_valid      <= 1'b0;
                        stage_issue_done <= 1'b1;
                    end else begin
                        bfly_cnt <= bfly_cnt + 7'd1;
                    end
                end

                ST_WAIT: begin
                    if (start) begin
                        error <= 1'b1;
                    end

                    if (stage_advance) begin
                        if (stage == 3'd6) begin
                            state         <= ST_IDLE;
                            schedule_done <= 1'b1;
                            busy          <= 1'b0;
                        end else begin
                            stage       <= stage + 3'd1;
                            bfly_cnt    <= 7'd0;
                            state       <= ST_ISSUE;
                            issue_valid <= 1'b1;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
