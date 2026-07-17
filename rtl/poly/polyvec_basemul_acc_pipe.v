`timescale 1ns / 1ps
/*
 * Module: polyvec_basemul_acc_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mod_add_pipe, poly_basemul_pipe, poly_workspace, polyvec_workspace.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module polyvec_basemul_acc_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire load_begin,
        input wire load_operand,
        input wire [1 : 0] load_poly_idx,
        input wire [1 : 0] load_domain,
        input wire load_we,
        input wire [7 : 0] load_idx,
        input wire [11 : 0] load_coeff,
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
    localparam [1 : 0] NTT = 2;
    localparam [4 : 0] IDLE = 0, BEGIN_A = 1, READ_A = 2, DRAIN_A = 3, BEGIN_B = 4, READ_B = 5, DRAIN_B = 6, START_CHILD = 7, WAIT_CHILD = 8, READ_PRODUCT = 9, DRAIN_PRODUCT = 10, RELEASE_CHILD = 11, NEXT = 12, PUBLISH = 13, DONE = 14;
    reg [4 : 0] state;
    reg [1 : 0] elem;
    reg [7 : 0] idx, idx_d, product_idx_d, add_idx_d;
    reg result_available;
    reg child_zeroize_req;
    reg [4 : 0] child_done_seen;
    wire [4 : 0] child_zeroize_busy, child_zeroize_done;
    wire [2 : 0] ac, bc;
    wire avc, bvc, adc, bdc;
    wire [1 : 0] ad, bd;
    wire ae, be;
    wire accepted = start && !busy && !result_available && avc && bvc && adc && bdc && ad == NTT && bd == NTT;
    wire ar, br, aird, bird;
    wire [11 : 0] acoeff, bcoeff;
    assign ar = (state == READ_A);
    assign br = (state == READ_B);
    wire child_begin = (state == BEGIN_A) || (state == BEGIN_B);
    wire child_operand = (state == BEGIN_B);
    wire child_start = (state == START_CHILD);
    wire child_busy, child_done, child_error, child_lr;
    wire child_rr = (state == READ_PRODUCT);
    wire child_rv;
    wire [11 : 0] child_rc;
    wire [1 : 0] child_rd;
    wire child_complete;
    wire child_release = (state == RELEASE_CHILD);
    wire acc_complete;
    wire [1 : 0] acc_domain, acc_owner;
    wire acc_error, acc_rv;
    wire [11 : 0] acc_rc;
    wire acc_int_rv;
    wire [11 : 0] acc_int_rc;
    wire acc_read = child_rr && (elem != 0);
    wire add_valid;
    wire [11 : 0] add_result;
    wire direct_write = child_rv && (elem == 0);
    wire add_write = add_valid && (elem != 0);
    wire publish = (state == PUBLISH), source_release = (state == PUBLISH);
    assign load_ready = !busy && !zeroize_busy;
    assign result_domain = result_available ? acc_domain : 0;
    assign result_complete = result_available && acc_complete;
    polyvec_workspace va(.clk(clk),
                         .rst_n(rst_n),
                         .load_begin(load_begin && !load_operand),
                         .load_poly_idx(load_poly_idx),
                         .load_domain(load_domain),
                         .load_we(load_we && !load_operand),
                         .load_poly_idx_we(load_poly_idx),
                         .load_idx(load_idx),
                         .load_coeff(load_coeff),
                         .load_ready(),
                         .acquire_internal(accepted),
                         .init_internal(1'b0),
                         .init_domain(0),
                         .publish_result(1'b0),
                         .release_internal(source_release),
                         .poly_complete(ac),
                         .vector_complete(avc),
                         .domain_consistent(adc),
                         .vector_domain(ad),
                         .error(ae),
                         .result_req(1'b0),
                         .result_poly_idx(0),
                         .result_idx(0),
                         .result_valid(),
                         .result_coeff(),
                         .int_rd_req(ar),
                         .int_rd_poly_idx(elem),
                         .int_rd_idx(idx),
                         .int_rd_valid(aird),
                         .int_rd_coeff(acoeff),
                         .int_wr_en(1'b0),
                         .int_wr_poly_idx(0),
                         .int_wr_idx(0),
                         .int_wr_coeff(0),
                         .zeroize_req(child_zeroize_req),
                         .zeroize_busy(child_zeroize_busy[0]),
                         .zeroize_done(child_zeroize_done[0]));
    polyvec_workspace vb(.clk(clk),
                         .rst_n(rst_n),
                         .load_begin(load_begin && load_operand),
                         .load_poly_idx(load_poly_idx),
                         .load_domain(load_domain),
                         .load_we(load_we && load_operand),
                         .load_poly_idx_we(load_poly_idx),
                         .load_idx(load_idx),
                         .load_coeff(load_coeff),
                         .load_ready(),
                         .acquire_internal(accepted),
                         .init_internal(1'b0),
                         .init_domain(0),
                         .publish_result(1'b0),
                         .release_internal(source_release),
                         .poly_complete(bc),
                         .vector_complete(bvc),
                         .domain_consistent(bdc),
                         .vector_domain(bd),
                         .error(be),
                         .result_req(1'b0),
                         .result_poly_idx(0),
                         .result_idx(0),
                         .result_valid(),
                         .result_coeff(),
                         .int_rd_req(br),
                         .int_rd_poly_idx(elem),
                         .int_rd_idx(idx),
                         .int_rd_valid(bird),
                         .int_rd_coeff(bcoeff),
                         .int_wr_en(1'b0),
                         .int_wr_poly_idx(0),
                         .int_wr_idx(0),
                         .int_wr_coeff(0),
                         .zeroize_req(child_zeroize_req),
                         .zeroize_busy(child_zeroize_busy[1]),
                         .zeroize_done(child_zeroize_done[1]));
    poly_workspace acc(.clk(clk),
                       .rst_n(rst_n),
                       .load_begin(1'b0),
                       .load_domain(0),
                       .load_we(1'b0),
                       .load_idx(0),
                       .load_coeff(0),
                       .load_ready(),
                       .acquire_internal(1'b0),
                       .init_internal(accepted),
                       .init_domain(NTT),
                       .publish_result(publish),
                       .release_internal(1'b0),
                       .owner(acc_owner),
                       .complete(acc_complete),
                       .domain(acc_domain),
                       .error(acc_error),
                       .result_req(result_req && result_available),
                       .result_idx(result_idx),
                       .result_valid(result_valid),
                       .result_coeff(result_coeff),
                       .int_rd_req(acc_read),
                       .int_rd_idx(idx),
                       .int_rd_valid(acc_int_rv),
                       .int_rd_coeff(acc_int_rc),
                       .int_pair_rd_req(1'b0),
                       .int_pair_rd_idx(0),
                       .int_pair_rd_valid(),
                       .int_pair_rd0(),
                       .int_pair_rd1(),
                       .int_wr_en(direct_write || add_write),
                       .int_wr_idx(direct_write ? product_idx_d : add_idx_d),
                       .int_wr_coeff(direct_write ? child_rc : add_result),
                       .int_pair_wr_en(1'b0),
                       .int_pair_wr_idx(0),
                       .int_pair_wr0(0),
                       .int_pair_wr1(0),
                       .zeroize_req(child_zeroize_req),
                       .zeroize_busy(child_zeroize_busy[2]),
                       .zeroize_done(child_zeroize_done[2]));
    poly_basemul_pipe child(.clk(clk),
                            .rst_n(rst_n),
                            .load_begin(child_begin),
                            .load_operand(child_operand),
                            .load_domain(NTT),
                            .a_load_we(aird),
                            .a_load_idx(idx_d),
                            .a_load_coeff(acoeff),
                            .b_load_we(bird),
                            .b_load_idx(idx_d),
                            .b_load_coeff(bcoeff),
                            .load_ready(child_lr),
                            .start(child_start),
                            .busy(child_busy),
                            .done(child_done),
                            .error(child_error),
                            .result_req(child_rr),
                            .result_idx(idx),
                            .result_valid(child_rv),
                            .result_coeff(child_rc),
                            .result_domain(child_rd),
                            .result_complete(child_complete),
                            .result_release(child_release),
                            .zeroize_req(child_zeroize_req),
                            .zeroize_busy(child_zeroize_busy[3]),
                            .zeroize_done(child_zeroize_done[3]));
    mod_add_pipe add(.clk(clk),
                     .rst_n(rst_n),
                     .in_valid(child_rv && acc_int_rv && elem != 0 && !zeroize_busy),
                     .a(acc_int_rc),
                     .b(child_rc),
                     .out_valid(add_valid),
                     .r(add_result),
                     .zeroize_req(child_zeroize_req),
                     .zeroize_busy(child_zeroize_busy[4]),
                     .zeroize_done(child_zeroize_done[4]));
    always @(posedge clk) begin
        child_zeroize_req <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            elem <= 0;
            idx <= 0;
            idx_d <= 0;
            product_idx_d <= 0;
            add_idx_d <= 0;
            result_available <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            elem <= 0;
            idx <= 0;
            idx_d <= 0;
            product_idx_d <= 0;
            add_idx_d <= 0;
            result_available <= 0;
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
            child_done_seen <= 0;
        end else if (zeroize_busy) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            elem <= 0;
            idx <= 0;
            idx_d <= 0;
            product_idx_d <= 0;
            add_idx_d <= 0;
            result_available <= 0;
            child_zeroize_req <= 1;
            child_done_seen <= child_done_seen | child_zeroize_done;
            if (&(child_done_seen | child_zeroize_done)) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
                child_zeroize_req <= 0;
                child_done_seen <= 0;
            end
        end else begin
            done <= 0;
            if (ar || br)
                idx_d <= idx;
            if (child_rr)
                product_idx_d <= idx;
            if (child_rv && elem != 0)
                add_idx_d <= product_idx_d;
            if (ae || be || acc_error || child_error)
                error <= 1;
            if (start && !accepted)
                error <= 1;
            if (busy && (load_begin || load_we || result_req || result_release))
                error <= 1;
            if (result_req && !result_available)
                error <= 1;
            if (result_release && !busy)
                result_available <= 0;
            case (state)
                IDLE:
                    if (accepted) begin
                        busy <= 1;
                        result_available <= 0;
                        elem <= 0;
                        state <= BEGIN_A;
                    end
                BEGIN_A: begin
                    idx <= 0;
                    state <= READ_A;
                end
                READ_A:
                    if (idx == 255)
                        state <= DRAIN_A;
                    else
                        idx <= idx + 1'b1;
                DRAIN_A:
                    if (aird && idx_d == 255)
                        state <= BEGIN_B;
                BEGIN_B: begin
                    idx <= 0;
                    state <= READ_B;
                end
                READ_B:
                    if (idx == 255)
                        state <= DRAIN_B;
                    else
                        idx <= idx + 1'b1;
                DRAIN_B:
                    if (bird && idx_d == 255)
                        state <= START_CHILD;
                START_CHILD:
                    state <= WAIT_CHILD;
                WAIT_CHILD:
                    if (child_done) begin
                        idx <= 0;
                        state <= READ_PRODUCT;
                    end
                READ_PRODUCT:
                    if (idx == 255)
                        state <= DRAIN_PRODUCT;
                    else
                        idx <= idx + 1'b1;
                DRAIN_PRODUCT:
                    if ((elem == 0 && child_rv && product_idx_d == 255) || (elem != 0 && add_valid && add_idx_d == 255))
                        state <= RELEASE_CHILD;
                RELEASE_CHILD:
                    state <= NEXT;
                NEXT:
                    if (elem == 2)
                        state <= PUBLISH;
                    else begin
                        elem <= elem + 1'b1;
                        state <= BEGIN_A;
                    end
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
