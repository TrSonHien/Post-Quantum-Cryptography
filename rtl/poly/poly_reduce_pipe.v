`timescale 1ns / 1ps
/*
 * Module: poly_reduce_pipe
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: barrett_reduce_pipe, poly_workspace.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module poly_reduce_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire load_begin,
        input wire [1 : 0] load_domain,
        input wire load_we,
        input wire [7 : 0] load_idx,
        input wire [31 : 0] load_coeff,
        output wire load_ready,
        input wire start,
        output reg busy,
        output reg done,
        output reg error,
        input wire result_req,
        input wire [7 : 0] result_idx,
        output wire result_valid,
        output wire [11 : 0] result_coeff,
        output wire [1 : 0] result_domain,
        output wire result_complete,
        input wire result_release,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam [1 : 0] INVALID = 0, NORMAL = 1, NTT = 2;
    localparam [2 : 0] IDLE = 0, ISSUE = 1, DRAIN = 2, PUBLISH = 3, DONE = 4;
    reg [2 : 0] state;
    reg [31 : 0] even_mem[0 : 127], odd_mem[0 : 127];
    reg [255 : 0] seen;
    reg [8 : 0] count;
    reg [1 : 0] input_domain;
    reg result_available;
    reg [6 : 0] issue_pair;
    reg rd_valid;
    reg [31 : 0] rd0, rd1;
    reg [6 : 0] p0, p1, p2, p3;
    reg [6 : 0] scrub_addr;
    reg scrub_commit_pending;
    reg child_zeroize_req;
    reg [2 : 0] child_done_seen;
    wire [2 : 0] child_zeroize_busy, child_zeroize_done;
    wire v0, v1;
    wire [11 : 0] r0, r1;
    wire r_complete;
    wire [1 : 0] r_dom, r_owner;
    wire r_error;
    wire start_ok = !busy && !zeroize_busy && !result_available && count == 256 &&
                    (input_domain == NORMAL || input_domain == NTT);
    wire accepted = start && start_ok;
    wire publish = (state == PUBLISH);
    assign load_ready = !busy && !zeroize_busy;
    assign result_domain = result_available ? r_dom : INVALID;
    assign result_complete = result_available && r_complete;

    barrett_reduce_pipe lane0(.clk(clk),
                              .rst_n(rst_n),
                              .in_valid(rd_valid && !zeroize_busy),
                              .a(rd0),
                              .out_valid(v0),
                              .r(r0),
                              .zeroize_req(child_zeroize_req),
                              .zeroize_busy(child_zeroize_busy[0]),
                              .zeroize_done(child_zeroize_done[0]));
    barrett_reduce_pipe lane1(.clk(clk),
                              .rst_n(rst_n),
                              .in_valid(rd_valid && !zeroize_busy),
                              .a(rd1),
                              .out_valid(v1),
                              .r(r1),
                              .zeroize_req(child_zeroize_req),
                              .zeroize_busy(child_zeroize_busy[1]),
                              .zeroize_done(child_zeroize_done[1]));
    poly_workspace ws_r(.clk(clk),
                        .rst_n(rst_n),
                        .load_begin(1'b0),
                        .load_domain(2'b0),
                        .load_we(1'b0),
                        .load_idx(8'b0),
                        .load_coeff(12'b0),
                        .load_ready(),
                        .acquire_internal(1'b0),
                        .init_internal(accepted),
                        .init_domain(input_domain),
                        .publish_result(publish),
                        .release_internal(1'b0),
                        .owner(r_owner),
                        .complete(r_complete),
                        .domain(r_dom),
                        .error(r_error),
                        .result_req(result_req && result_available),
                        .result_idx(result_idx),
                        .result_valid(result_valid),
                        .result_coeff(result_coeff),
                        .int_rd_req(1'b0),
                        .int_rd_idx(8'b0),
                        .int_rd_valid(),
                        .int_rd_coeff(),
                        .int_pair_rd_req(1'b0),
                        .int_pair_rd_idx(7'b0),
                        .int_pair_rd_valid(),
                        .int_pair_rd0(),
                        .int_pair_rd1(),
                        .int_wr_en(1'b0),
                        .int_wr_idx(8'b0),
                        .int_wr_coeff(12'b0),
                        .int_pair_wr_en(v0 && v1 && !zeroize_busy),
                        .int_pair_wr_idx(p3),
                        .int_pair_wr0(r0),
                        .int_pair_wr1(r1),
                        .zeroize_req(child_zeroize_req),
                        .zeroize_busy(child_zeroize_busy[2]),
                        .zeroize_done(child_zeroize_done[2]));

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            seen <= 0;
            count <= 0;
            input_domain <= INVALID;
            result_available <= 0;
            issue_pair <= 0;
            rd_valid <= 0;
            rd0 <= 0;
            rd1 <= 0;
            p0 <= 0;
            p1 <= 0;
            p2 <= 0;
            p3 <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            scrub_addr <= 0;
            scrub_commit_pending <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            seen <= 0;
            count <= 0;
            input_domain <= INVALID;
            result_available <= 0;
            issue_pair <= 0;
            rd_valid <= 0;
            rd0 <= 0;
            rd1 <= 0;
            p0 <= 0;
            p1 <= 0;
            p2 <= 0;
            p3 <= 0;
            zeroize_busy <= 1;
            zeroize_done <= 0;
            scrub_addr <= 0;
            scrub_commit_pending <= 0;
            child_zeroize_req <= 1;
            child_done_seen <= 0;
        end else if (zeroize_busy) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            seen <= 0;
            count <= 0;
            input_domain <= INVALID;
            result_available <= 0;
            issue_pair <= 0;
            rd_valid <= 0;
            rd0 <= 0;
            rd1 <= 0;
            p0 <= 0;
            p1 <= 0;
            p2 <= 0;
            p3 <= 0;
            zeroize_done <= 0;
            child_done_seen <= child_done_seen | child_zeroize_done;
            child_zeroize_req <= child_zeroize_req && !(|child_zeroize_done);
            if (!scrub_commit_pending) begin
                even_mem[scrub_addr] <= 0;
                odd_mem[scrub_addr] <= 0;
                if (scrub_addr == 127)
                    scrub_commit_pending <= 1;
                else
                    scrub_addr <= scrub_addr + 1'b1;
            end else if (&(child_done_seen | child_zeroize_done)) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
                scrub_addr <= 0;
                scrub_commit_pending <= 0;
                child_zeroize_req <= 0;
                child_done_seen <= 0;
            end
        end else begin
            zeroize_done <= 0;
            done <= 0;
            rd_valid <= 0;
            p0 <= issue_pair;
            p1 <= p0;
            p2 <= p1;
            p3 <= p2;
            if (r_error)
                error <= 1;
            if (load_begin) begin
                if (busy || load_domain == INVALID)
                    error <= 1;
                else begin
                    seen <= 0;
                    count <= 0;
                    input_domain <= load_domain;
                end
            end
            if (load_we) begin
                if (busy)
                    error <= 1;
                else begin
                    if (load_idx[0])
                        odd_mem[load_idx[7 : 1]] <= load_coeff;
                    else
                        even_mem[load_idx[7 : 1]] <= load_coeff;
                    if (!seen[load_idx]) begin
                        seen[load_idx] <= 1;
                        count <= count + 1'b1;
                    end
                end
            end
            if (start && !start_ok)
                error <= 1;
            if (result_req && !result_available)
                error <= 1;
            if (busy && (load_we || result_req || result_release))
                error <= 1;
            if (result_release && !busy)
                result_available <= 0;
            if (state == ISSUE) begin
                rd_valid <= 1;
                rd0 <= even_mem[issue_pair];
                rd1 <= odd_mem[issue_pair];
            end
            case (state)
                IDLE:
                    if (accepted) begin
                        busy <= 1;
                        result_available <= 0;
                        issue_pair <= 0;
                        state <= ISSUE;
                    end
                ISSUE:
                    if (issue_pair == 127)
                        state <= DRAIN;
                    else
                        issue_pair <= issue_pair + 1'b1;
                DRAIN:
                    if (v0 && v1 && p3 == 127)
                        state <= PUBLISH;
                PUBLISH:
                    state <= DONE;
                DONE: begin
                    busy <= 0;
                    done <= 1;
                    result_available <= 1;
                    state <= IDLE;
                end
                default:
                    state <= IDLE;
            endcase
        end
    end
endmodule
