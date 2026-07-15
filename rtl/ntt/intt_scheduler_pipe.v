`timescale 1ns/1ps

// Seven-stage, II=1 Gentleman-Sande inverse NTT scheduler.
module intt_scheduler_pipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       stage_advance,
    output reg        busy,
    output reg        error,
    output reg        issue_valid,
    output wire [7:0] src_u_idx,
    output wire [7:0] src_v_idx,
    output wire       src_u_bank,
    output wire [6:0] src_u_addr,
    output wire       src_v_bank,
    output wire [6:0] src_v_addr,
    output wire       dst_u_bank,
    output wire [6:0] dst_u_addr,
    output wire       dst_v_bank,
    output wire [6:0] dst_v_addr,
    output wire [6:0] zeta_addr,
    output reg  [2:0] stage,
    output wire [6:0] bfly_idx,
    output wire [6:0] group_idx,
    output wire [6:0] offset,
    output wire       last_issue_in_stage,
    output wire       last_issue_in_transform,
    output reg        stage_issue_done,
    output reg        schedule_done,
    input  wire       zeroize_req,
    output reg        zeroize_busy,
    output reg        zeroize_done
);

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_ISSUE = 2'd1;
    localparam [1:0] ST_WAIT  = 2'd2;

    reg [1:0] state;
    reg [6:0] bfly_cnt;

    wire [7:0] len = 8'd2 << stage;
    assign bfly_idx = bfly_cnt;
    assign group_idx = bfly_cnt >> (stage + 3'd1);
    assign offset = bfly_cnt & (len - 8'd1);
    assign src_u_idx = (group_idx * (len << 1)) + offset;
    assign src_v_idx = src_u_idx + len;
    assign zeta_addr = (7'd127 >> stage) - group_idx;
    assign last_issue_in_stage = (bfly_cnt == 7'd127);
    assign last_issue_in_transform = (stage == 3'd6) && last_issue_in_stage;

    wire [2:0] src_pair_bit = stage + 3'd1;
    wire [2:0] src_addr_bit = (stage == 3'd0) ? 3'd1 : stage;
    wire       src_xor_layout = (stage != 3'd0);
    wire [2:0] dst_pair_bit = (stage == 3'd6) ? 3'd7 : stage + 3'd2;
    wire [2:0] dst_addr_bit = stage + 3'd1;
    wire       dst_xor_layout = (stage != 3'd6);

    ntt_bank_map u_src_map (
        src_u_idx, src_pair_bit, src_addr_bit, src_xor_layout,
        src_u_bank, src_u_addr
    );
    ntt_bank_map v_src_map (
        src_v_idx, src_pair_bit, src_addr_bit, src_xor_layout,
        src_v_bank, src_v_addr
    );
    ntt_bank_map u_dst_map (
        src_u_idx, dst_pair_bit, dst_addr_bit, dst_xor_layout,
        dst_u_bank, dst_u_addr
    );
    ntt_bank_map v_dst_map (
        src_v_idx, dst_pair_bit, dst_addr_bit, dst_xor_layout,
        dst_v_bank, dst_v_addr
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            error <= 1'b0;
            issue_valid <= 1'b0;
            stage <= 3'd0;
            bfly_cnt <= 7'd0;
            stage_issue_done <= 1'b0;
            schedule_done <= 1'b0;
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b0;
        end else begin
            stage_issue_done <= 1'b0;
            schedule_done <= 1'b0;
            zeroize_done <= 1'b0;
            if(zeroize_req===1'b1&&!zeroize_busy)begin
                state<=ST_IDLE;busy<=0;error<=0;issue_valid<=0;stage<=0;bfly_cnt<=0;zeroize_busy<=1;
            end else if(zeroize_busy)begin
                state<=ST_IDLE;busy<=0;error<=0;issue_valid<=0;stage<=0;bfly_cnt<=0;zeroize_busy<=0;zeroize_done<=1;
            end else case (state)
                ST_IDLE: begin
                    issue_valid <= 1'b0;
                    if (stage_advance)
                        error <= 1'b1;
                    if (start) begin
                        state <= ST_ISSUE;
                        busy <= 1'b1;
                        stage <= 3'd0;
                        bfly_cnt <= 7'd0;
                        issue_valid <= 1'b1;
                    end
                end
                ST_ISSUE: begin
                    if (start || stage_advance)
                        error <= 1'b1;
                    if (bfly_cnt == 7'd127) begin
                        state <= ST_WAIT;
                        issue_valid <= 1'b0;
                        stage_issue_done <= 1'b1;
                    end else begin
                        bfly_cnt <= bfly_cnt + 7'd1;
                    end
                end
                ST_WAIT: begin
                    issue_valid <= 1'b0;
                    if (start)
                        error <= 1'b1;
                    if (stage_advance) begin
                        if (stage == 3'd6) begin
                            state <= ST_IDLE;
                            busy <= 1'b0;
                            schedule_done <= 1'b1;
                        end else begin
                            state <= ST_ISSUE;
                            stage <= stage + 3'd1;
                            bfly_cnt <= 7'd0;
                            issue_valid <= 1'b1;
                        end
                    end
                end
                default: begin
                    state <= ST_IDLE;
                    busy <= 1'b0;
                    issue_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule
