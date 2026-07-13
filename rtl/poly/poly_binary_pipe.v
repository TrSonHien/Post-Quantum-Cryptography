`timescale 1ns/1ps

module poly_binary_pipe #(
    parameter OP_SUB = 0
)(
    input wire clk, input wire rst_n,
    input wire load_begin, input wire load_operand, input wire [1:0] load_domain,
    input wire a_load_we, input wire [7:0] a_load_idx, input wire [11:0] a_load_coeff,
    input wire b_load_we, input wire [7:0] b_load_idx, input wire [11:0] b_load_coeff,
    output wire load_ready,
    input wire start, output reg busy, output reg done, output reg error,
    input wire result_req, input wire [7:0] result_idx,
    output wire result_valid, output wire [11:0] result_coeff,
    output wire [1:0] result_domain, output wire result_complete,
    input wire result_release
);
    localparam [1:0] DOMAIN_INVALID=0, DOMAIN_NORMAL=1, DOMAIN_NTT=2;
    localparam [2:0] IDLE=0, ISSUE=1, DRAIN=2, PUBLISH=3, DONE=4;
    reg [2:0] state;
    reg [6:0] issue_pair;
    reg [6:0] pair_d0, pair_d1;
    reg result_available;

    wire a_complete, b_complete, r_complete;
    wire [1:0] a_domain, b_domain, r_domain;
    wire [1:0] a_owner, b_owner, r_owner;
    wire a_error, b_error, r_error;
    wire pair_req = (state == ISSUE);
    wire a_pair_valid, b_pair_valid;
    wire [11:0] a0,a1,b0,b1;
    wire arith_in_valid = a_pair_valid && b_pair_valid;
    wire out0_valid, out1_valid;
    wire [11:0] out0, out1;
    wire start_ok = !busy && !result_available && a_complete && b_complete &&
                    a_domain == b_domain &&
                    (a_domain == DOMAIN_NORMAL || a_domain == DOMAIN_NTT);
    wire accepted_start = start && start_ok;
    wire publish = (state == PUBLISH);
    wire release_sources = (state == PUBLISH);

    assign load_ready = !busy;
    assign result_domain = result_available ? r_domain : DOMAIN_INVALID;
    assign result_complete = result_available && r_complete;

    poly_workspace ws_a(
        .clk(clk),.rst_n(rst_n),.load_begin(load_begin && !load_operand),.load_domain(load_domain),
        .load_we(a_load_we),.load_idx(a_load_idx),.load_coeff(a_load_coeff),.load_ready(),
        .acquire_internal(accepted_start),.init_internal(1'b0),.init_domain(2'b0),
        .publish_result(1'b0),.release_internal(release_sources),
        .owner(a_owner),.complete(a_complete),.domain(a_domain),.error(a_error),
        .result_req(1'b0),.result_idx(8'b0),.result_valid(),.result_coeff(),
        .int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),
        .int_pair_rd_req(pair_req),.int_pair_rd_idx(issue_pair),
        .int_pair_rd_valid(a_pair_valid),.int_pair_rd0(a0),.int_pair_rd1(a1),
        .int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),
        .int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0));
    poly_workspace ws_b(
        .clk(clk),.rst_n(rst_n),.load_begin(load_begin && load_operand),.load_domain(load_domain),
        .load_we(b_load_we),.load_idx(b_load_idx),.load_coeff(b_load_coeff),.load_ready(),
        .acquire_internal(accepted_start),.init_internal(1'b0),.init_domain(2'b0),
        .publish_result(1'b0),.release_internal(release_sources),
        .owner(b_owner),.complete(b_complete),.domain(b_domain),.error(b_error),
        .result_req(1'b0),.result_idx(8'b0),.result_valid(),.result_coeff(),
        .int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),
        .int_pair_rd_req(pair_req),.int_pair_rd_idx(issue_pair),
        .int_pair_rd_valid(b_pair_valid),.int_pair_rd0(b0),.int_pair_rd1(b1),
        .int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),
        .int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0));
    poly_workspace ws_r(
        .clk(clk),.rst_n(rst_n),.load_begin(1'b0),.load_domain(2'b0),
        .load_we(1'b0),.load_idx(8'b0),.load_coeff(12'b0),.load_ready(),
        .acquire_internal(1'b0),.init_internal(accepted_start),.init_domain(a_domain),
        .publish_result(publish),.release_internal(1'b0),
        .owner(r_owner),.complete(r_complete),.domain(r_domain),.error(r_error),
        .result_req(result_req && result_available),.result_idx(result_idx),
        .result_valid(result_valid),.result_coeff(result_coeff),
        .int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),
        .int_pair_rd_req(1'b0),.int_pair_rd_idx(7'b0),.int_pair_rd_valid(),
        .int_pair_rd0(),.int_pair_rd1(),.int_wr_en(1'b0),.int_wr_idx(8'b0),
        .int_wr_coeff(12'b0),.int_pair_wr_en(out0_valid && out1_valid),
        .int_pair_wr_idx(pair_d1),.int_pair_wr0(out0),.int_pair_wr1(out1));

    generate if (OP_SUB) begin
        mod_sub_pipe lane0(.clk(clk),.rst_n(rst_n),.in_valid(arith_in_valid),.a(a0),.b(b0),.out_valid(out0_valid),.r(out0));
        mod_sub_pipe lane1(.clk(clk),.rst_n(rst_n),.in_valid(arith_in_valid),.a(a1),.b(b1),.out_valid(out1_valid),.r(out1));
    end else begin
        mod_add_pipe lane0(.clk(clk),.rst_n(rst_n),.in_valid(arith_in_valid),.a(a0),.b(b0),.out_valid(out0_valid),.r(out0));
        mod_add_pipe lane1(.clk(clk),.rst_n(rst_n),.in_valid(arith_in_valid),.a(a1),.b(b1),.out_valid(out1_valid),.r(out1));
    end endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            state<=IDLE; busy<=0; done<=0; error<=0; issue_pair<=0;
            pair_d0<=0; pair_d1<=0; result_available<=0;
        end else begin
            done<=0;
            pair_d0<=issue_pair; pair_d1<=pair_d0;
            if (a_error || b_error || r_error) error<=1;
            if (start && !start_ok) error<=1;
            if (busy && (load_begin || a_load_we || b_load_we || result_req || result_release)) error<=1;
            if (result_req && !result_available) error<=1;
            if (result_release && !busy) result_available<=0;
            case(state)
                IDLE: if (accepted_start) begin busy<=1; result_available<=0; issue_pair<=0; state<=ISSUE; end
                ISSUE: if (issue_pair==127) state<=DRAIN; else issue_pair<=issue_pair+1'b1;
                DRAIN: if (out0_valid && out1_valid && pair_d1==127) state<=PUBLISH;
                PUBLISH: state<=DONE;
                DONE: begin busy<=0; done<=1; result_available<=1; state<=IDLE; end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
