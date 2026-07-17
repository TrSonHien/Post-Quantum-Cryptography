`timescale 1ns / 1ps
/*
 * Module: polyvec_workspace
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: poly_workspace.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module polyvec_workspace
    (
        input wire clk,
        input wire rst_n,
        input wire load_begin,
        input wire [1 : 0] load_poly_idx,
        input wire [1 : 0] load_domain,
        input wire load_we,
        input wire [1 : 0] load_poly_idx_we,
        input wire [7 : 0] load_idx,
        input wire [11 : 0] load_coeff,
        output wire load_ready,
        input wire acquire_internal,
        input wire init_internal,
        input wire [1 : 0] init_domain,
        input wire publish_result,
        input wire release_internal,
        output wire [2 : 0] poly_complete,
        output wire vector_complete,
        output wire domain_consistent,
        output wire [1 : 0] vector_domain,
        output reg error,
        input wire result_req,
        input wire [1 : 0] result_poly_idx,
        input wire [7 : 0] result_idx,
        output wire result_valid,
        output wire [11 : 0] result_coeff,
        input wire int_rd_req,
        input wire [1 : 0] int_rd_poly_idx,
        input wire [7 : 0] int_rd_idx,
        output wire int_rd_valid,
        output wire [11 : 0] int_rd_coeff,
        input wire int_wr_en,
        input wire [1 : 0] int_wr_poly_idx,
        input wire [7 : 0] int_wr_idx,
        input wire [11 : 0] int_wr_coeff,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    wire [2 : 0] lr;
    wire [2 : 0] c;
    wire [1 : 0] d0, d1, d2;
    wire [1 : 0] o0, o1, o2;
    wire [2 : 0] e;
    wire [2 : 0] rv;
    wire [11 : 0] rc0, rc1, rc2;
    wire [2 : 0] iv;
    wire [11 : 0] ic0, ic1, ic2;
    wire [2 : 0] child_zeroize_busy, child_zeroize_done;
    reg child_zeroize_req;
    reg [2 : 0] child_done_seen;
    wire accept_zeroize = (zeroize_req === 1'b1);
    assign poly_complete = c;
    assign vector_complete = &c;
    assign domain_consistent = vector_complete && (d0 == d1) && (d1 == d2) && (d0 != 0);
    assign vector_domain = domain_consistent ? d0 : 2'b00;
    assign load_ready = !zeroize_busy && (&lr);
    assign result_valid = !zeroize_busy && ((result_poly_idx == 0) ? rv[0] : (result_poly_idx == 1) ? rv[1]
                                                                         : (result_poly_idx == 2)   ? rv[2]
                                                                                                    : 1'b0);
    assign result_coeff = (result_poly_idx == 0) ? rc0 : (result_poly_idx == 1) ? rc1
                                                                                : rc2;
    assign int_rd_valid = !zeroize_busy && ((int_rd_poly_idx == 0) ? iv[0] : (int_rd_poly_idx == 1) ? iv[1]
                                                                         : (int_rd_poly_idx == 2)   ? iv[2]
                                                                                                    : 1'b0);
    assign int_rd_coeff = (int_rd_poly_idx == 0) ? ic0 : (int_rd_poly_idx == 1) ? ic1
                                                                                : ic2;
    poly_workspace w0(.clk(clk),
                      .rst_n(rst_n),
                      .load_begin(load_begin && !zeroize_busy && load_poly_idx == 0),
                      .load_domain(load_domain),
                      .load_we(load_we && !zeroize_busy && load_poly_idx_we == 0),
                      .load_idx(load_idx),
                      .load_coeff(load_coeff),
                      .load_ready(lr[0]),
                      .acquire_internal(acquire_internal && !zeroize_busy),
                      .init_internal(init_internal && !zeroize_busy),
                      .init_domain(init_domain),
                      .publish_result(publish_result && !zeroize_busy),
                      .release_internal(release_internal && !zeroize_busy),
                      .owner(o0),
                      .complete(c[0]),
                      .domain(d0),
                      .error(e[0]),
                      .result_req(result_req && !zeroize_busy && result_poly_idx == 0),
                      .result_idx(result_idx),
                      .result_valid(rv[0]),
                      .result_coeff(rc0),
                      .int_rd_req(int_rd_req && !zeroize_busy && int_rd_poly_idx == 0),
                      .int_rd_idx(int_rd_idx),
                      .int_rd_valid(iv[0]),
                      .int_rd_coeff(ic0),
                      .int_pair_rd_req(1'b0),
                      .int_pair_rd_idx(7'b0),
                      .int_pair_rd_valid(),
                      .int_pair_rd0(),
                      .int_pair_rd1(),
                      .int_wr_en(int_wr_en && !zeroize_busy && int_wr_poly_idx == 0),
                      .int_wr_idx(int_wr_idx),
                      .int_wr_coeff(int_wr_coeff),
                      .int_pair_wr_en(1'b0),
                      .int_pair_wr_idx(7'b0),
                      .int_pair_wr0(12'b0),
                      .int_pair_wr1(12'b0),
                      .zeroize_req(child_zeroize_req),
                      .zeroize_busy(child_zeroize_busy[0]),
                      .zeroize_done(child_zeroize_done[0]));
    poly_workspace w1(.clk(clk),
                      .rst_n(rst_n),
                      .load_begin(load_begin && !zeroize_busy && load_poly_idx == 1),
                      .load_domain(load_domain),
                      .load_we(load_we && !zeroize_busy && load_poly_idx_we == 1),
                      .load_idx(load_idx),
                      .load_coeff(load_coeff),
                      .load_ready(lr[1]),
                      .acquire_internal(acquire_internal && !zeroize_busy),
                      .init_internal(init_internal && !zeroize_busy),
                      .init_domain(init_domain),
                      .publish_result(publish_result && !zeroize_busy),
                      .release_internal(release_internal && !zeroize_busy),
                      .owner(o1),
                      .complete(c[1]),
                      .domain(d1),
                      .error(e[1]),
                      .result_req(result_req && !zeroize_busy && result_poly_idx == 1),
                      .result_idx(result_idx),
                      .result_valid(rv[1]),
                      .result_coeff(rc1),
                      .int_rd_req(int_rd_req && !zeroize_busy && int_rd_poly_idx == 1),
                      .int_rd_idx(int_rd_idx),
                      .int_rd_valid(iv[1]),
                      .int_rd_coeff(ic1),
                      .int_pair_rd_req(1'b0),
                      .int_pair_rd_idx(7'b0),
                      .int_pair_rd_valid(),
                      .int_pair_rd0(),
                      .int_pair_rd1(),
                      .int_wr_en(int_wr_en && !zeroize_busy && int_wr_poly_idx == 1),
                      .int_wr_idx(int_wr_idx),
                      .int_wr_coeff(int_wr_coeff),
                      .int_pair_wr_en(1'b0),
                      .int_pair_wr_idx(7'b0),
                      .int_pair_wr0(12'b0),
                      .int_pair_wr1(12'b0),
                      .zeroize_req(child_zeroize_req),
                      .zeroize_busy(child_zeroize_busy[1]),
                      .zeroize_done(child_zeroize_done[1]));
    poly_workspace w2(.clk(clk),
                      .rst_n(rst_n),
                      .load_begin(load_begin && !zeroize_busy && load_poly_idx == 2),
                      .load_domain(load_domain),
                      .load_we(load_we && !zeroize_busy && load_poly_idx_we == 2),
                      .load_idx(load_idx),
                      .load_coeff(load_coeff),
                      .load_ready(lr[2]),
                      .acquire_internal(acquire_internal && !zeroize_busy),
                      .init_internal(init_internal && !zeroize_busy),
                      .init_domain(init_domain),
                      .publish_result(publish_result && !zeroize_busy),
                      .release_internal(release_internal && !zeroize_busy),
                      .owner(o2),
                      .complete(c[2]),
                      .domain(d2),
                      .error(e[2]),
                      .result_req(result_req && !zeroize_busy && result_poly_idx == 2),
                      .result_idx(result_idx),
                      .result_valid(rv[2]),
                      .result_coeff(rc2),
                      .int_rd_req(int_rd_req && !zeroize_busy && int_rd_poly_idx == 2),
                      .int_rd_idx(int_rd_idx),
                      .int_rd_valid(iv[2]),
                      .int_rd_coeff(ic2),
                      .int_pair_rd_req(1'b0),
                      .int_pair_rd_idx(7'b0),
                      .int_pair_rd_valid(),
                      .int_pair_rd0(),
                      .int_pair_rd1(),
                      .int_wr_en(int_wr_en && !zeroize_busy && int_wr_poly_idx == 2),
                      .int_wr_idx(int_wr_idx),
                      .int_wr_coeff(int_wr_coeff),
                      .int_pair_wr_en(1'b0),
                      .int_pair_wr_idx(7'b0),
                      .int_pair_wr0(12'b0),
                      .int_pair_wr1(12'b0),
                      .zeroize_req(child_zeroize_req),
                      .zeroize_busy(child_zeroize_busy[2]),
                      .zeroize_done(child_zeroize_done[2]));
    always @(posedge clk) begin
        zeroize_done <= 0;
        child_zeroize_req <= 0;
        if (!rst_n) begin
            error <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
        end else if (accept_zeroize && !zeroize_busy) begin
            error <= 0;
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
            child_done_seen <= 0;
        end else if (zeroize_busy) begin
            child_done_seen <= child_done_seen | child_zeroize_done;
            if (&(child_done_seen | child_zeroize_done)) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end
        end else begin
            if (|e)
                error <= 1;
            if ((load_begin && load_poly_idx == 3) || (load_we && load_poly_idx_we == 3) || (result_req && result_poly_idx == 3) || (int_rd_req && int_rd_poly_idx == 3) || (int_wr_en && int_wr_poly_idx == 3))
                error <= 1;
        end
    end
endmodule
