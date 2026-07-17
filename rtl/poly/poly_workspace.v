`timescale 1ns / 1ps
/*
 * Module: poly_workspace
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module poly_workspace
    (
        input wire clk,
        input wire rst_n,
        input wire load_begin,
        input wire [1 : 0] load_domain,
        input wire load_we,
        input wire [7 : 0] load_idx,
        input wire [11 : 0] load_coeff,
        output wire load_ready,
        input wire acquire_internal,
        input wire init_internal,
        input wire [1 : 0] init_domain,
        input wire publish_result,
        input wire release_internal,
        output reg [1 : 0] owner,
        output wire complete,
        output reg [1 : 0] domain,
        output reg error,
        input wire result_req,
        input wire [7 : 0] result_idx,
        output reg result_valid,
        output reg [11 : 0] result_coeff,
        input wire int_rd_req,
        input wire [7 : 0] int_rd_idx,
        output reg int_rd_valid,
        output reg [11 : 0] int_rd_coeff,
        input wire int_pair_rd_req,
        input wire [6 : 0] int_pair_rd_idx,
        output reg int_pair_rd_valid,
        output reg [11 : 0] int_pair_rd0,
        output reg [11 : 0] int_pair_rd1,
        input wire int_wr_en,
        input wire [7 : 0] int_wr_idx,
        input wire [11 : 0] int_wr_coeff,
        input wire int_pair_wr_en,
        input wire [6 : 0] int_pair_wr_idx,
        input wire [11 : 0] int_pair_wr0,
        input wire [11 : 0] int_pair_wr1,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam [1 : 0] EXTERNAL_LOAD = 2'd0;
    localparam [1 : 0] INTERNAL_OPERATION = 2'd1;
    localparam [1 : 0] EXTERNAL_RESULT = 2'd2;
    localparam [1 : 0] DOMAIN_INVALID = 2'd0;

    reg [11 : 0] bank_even[0 : 127];
    reg [11 : 0] bank_odd[0 : 127];
    reg [255 : 0] valid_bitmap;
    reg [8 : 0] valid_count;
    reg [6 : 0] scrub_addr;
    reg scrub_commit_pending;
    wire accept_zeroize = (zeroize_req === 1'b1);

    assign complete = (valid_count == 9'd256);
    assign load_ready = (owner == EXTERNAL_LOAD) && !zeroize_busy;

    integer i;
    reg [1 : 0] pair_new_count;
    always @(posedge clk) begin
        if (!rst_n) begin
            owner <= EXTERNAL_LOAD;
            domain <= DOMAIN_INVALID;
            error <= 1'b0;
            valid_bitmap <= 256'd0;
            valid_count <= 9'd0;
            result_valid <= 1'b0;
            int_rd_valid <= 1'b0;
            int_pair_rd_valid <= 1'b0;
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b0;
            scrub_addr <= 7'd0;
            scrub_commit_pending <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            int_rd_valid <= 1'b0;
            int_pair_rd_valid <= 1'b0;
            zeroize_done <= 1'b0;

            if (accept_zeroize && !zeroize_busy) begin
                owner <= EXTERNAL_LOAD;
                domain <= DOMAIN_INVALID;
                error <= 1'b0;
                valid_bitmap <= 256'd0;
                valid_count <= 9'd0;
                result_coeff <= 12'd0;
                int_rd_coeff <= 12'd0;
                int_pair_rd0 <= 12'd0;
                int_pair_rd1 <= 12'd0;
                scrub_addr <= 7'd0;
                scrub_commit_pending <= 1'b0;
                zeroize_busy <= 1'b1;
            end else if (zeroize_busy) begin
                result_coeff <= 12'd0;
                int_rd_coeff <= 12'd0;
                int_pair_rd0 <= 12'd0;
                int_pair_rd1 <= 12'd0;
                if (scrub_commit_pending) begin
                    scrub_commit_pending <= 1'b0;
                    zeroize_busy <= 1'b0;
                    zeroize_done <= 1'b1;
                end else begin
                    bank_even[scrub_addr] <= 12'd0;
                    bank_odd[scrub_addr] <= 12'd0;
                    if (scrub_addr == 7'd127)
                        scrub_commit_pending <= 1'b1;
                    else
                        scrub_addr <= scrub_addr + 1'b1;
                end
            end else begin

                if (load_begin) begin
                    if (owner == INTERNAL_OPERATION) begin
                        error <= 1'b1;
                    end else if (load_domain == DOMAIN_INVALID) begin
                        error <= 1'b1;
                    end else begin
                        owner <= EXTERNAL_LOAD;
                        domain <= load_domain;
                        valid_bitmap <= 256'd0;
                        valid_count <= 9'd0;
                    end
                end

                if (load_we) begin
                    if (owner != EXTERNAL_LOAD || load_coeff >= 12'd3329) begin
                        error <= 1'b1;
                    end else begin
                        if (load_idx[0])
                            bank_odd[load_idx[7 : 1]] <= load_coeff;
                        else
                            bank_even[load_idx[7 : 1]] <= load_coeff;
                        if (!valid_bitmap[load_idx]) begin
                            valid_bitmap[load_idx] <= 1'b1;
                            valid_count <= valid_count + 9'd1;
                        end
                    end
                end

                if (acquire_internal) begin
                    if (owner != EXTERNAL_LOAD || !complete || domain == DOMAIN_INVALID)
                        error <= 1'b1;
                    else
                        owner <= INTERNAL_OPERATION;
                end

                if (init_internal) begin
                    if (owner == INTERNAL_OPERATION || init_domain == DOMAIN_INVALID) begin
                        error <= 1'b1;
                    end else begin
                        owner <= INTERNAL_OPERATION;
                        domain <= init_domain;
                        valid_bitmap <= 256'd0;
                        valid_count <= 9'd0;
                    end
                end

                if (release_internal) begin
                    if (owner != INTERNAL_OPERATION)
                        error <= 1'b1;
                    else
                        owner <= EXTERNAL_RESULT;
                end

                if (publish_result) begin
                    if (owner != INTERNAL_OPERATION || !complete)
                        error <= 1'b1;
                    else
                        owner <= EXTERNAL_RESULT;
                end

                if (result_req) begin
                    if (owner != EXTERNAL_RESULT || !complete) begin
                        error <= 1'b1;
                    end else begin
                        result_valid <= 1'b1;
                        result_coeff <= result_idx[0] ? bank_odd[result_idx[7 : 1]] : bank_even[result_idx[7 : 1]];
                    end
                end

                if (int_rd_req) begin
                    if (owner != INTERNAL_OPERATION) begin
                        error <= 1'b1;
                    end else begin
                        int_rd_valid <= 1'b1;
                        int_rd_coeff <= int_rd_idx[0] ? bank_odd[int_rd_idx[7 : 1]] : bank_even[int_rd_idx[7 : 1]];
                    end
                end

                if (int_pair_rd_req) begin
                    if (owner != INTERNAL_OPERATION) begin
                        error <= 1'b1;
                    end else begin
                        int_pair_rd_valid <= 1'b1;
                        int_pair_rd0 <= bank_even[int_pair_rd_idx];
                        int_pair_rd1 <= bank_odd[int_pair_rd_idx];
                    end
                end

                if ((int_rd_req && int_pair_rd_req) ||
                    (int_wr_en && int_pair_wr_en))
                    error <= 1'b1;

                if (int_wr_en) begin
                    if (owner != INTERNAL_OPERATION || int_wr_coeff >= 12'd3329) begin
                        error <= 1'b1;
                    end else begin
                        if (int_wr_idx[0])
                            bank_odd[int_wr_idx[7 : 1]] <= int_wr_coeff;
                        else
                            bank_even[int_wr_idx[7 : 1]] <= int_wr_coeff;
                        if (!valid_bitmap[int_wr_idx]) begin
                            valid_bitmap[int_wr_idx] <= 1'b1;
                            valid_count <= valid_count + 9'd1;
                        end
                    end
                end

                if (int_pair_wr_en) begin
                    if (owner != INTERNAL_OPERATION || int_pair_wr0 >= 12'd3329 ||
                        int_pair_wr1 >= 12'd3329) begin
                        error <= 1'b1;
                    end else begin
                        bank_even[int_pair_wr_idx] <= int_pair_wr0;
                        bank_odd[int_pair_wr_idx] <= int_pair_wr1;
                        pair_new_count = {1'b0, !valid_bitmap[{int_pair_wr_idx, 1'b0}]} +
                                         {1'b0, !valid_bitmap[{int_pair_wr_idx, 1'b1}]};
                        valid_bitmap[{int_pair_wr_idx, 1'b0}] <= 1'b1;
                        valid_bitmap[{int_pair_wr_idx, 1'b1}] <= 1'b1;
                        valid_count <= valid_count + pair_new_count;
                    end
                end
            end
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (rst_n && complete && valid_bitmap != {256{1'b1}})
            $fatal(1, "POLY_WORKSPACE_COMPLETENESS: count/bitmap mismatch");
    end
`endif
endmodule
