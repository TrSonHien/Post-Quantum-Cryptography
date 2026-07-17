`timescale 1ns / 1ps

// Serialized ML-KEM-768 matrix-row generator.
// A[row,col] = SampleNTT(rho || col || row).
/*
 * Module: kpke_matrix_row_sampler
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: K-PKE controller or deterministic matrix/noise orchestration.
 * Standard role: FIPS 203 Algorithms 13--15 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mlkem_sample_ntt.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module kpke_matrix_row_sampler
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [255 : 0] rho,
        input wire [1 : 0] row,
        input wire transpose,
        output reg busy,
        output reg done,
        output reg error,
        output wire out_valid,
        input wire out_ready,
        output wire [11 : 0] out_coeff,
        output wire [7 : 0] out_index,
        output wire [1 : 0] out_poly_index,
        output wire [1 : 0] out_domain,
        output wire [7 : 0] sample_index0,
        output wire [7 : 0] sample_index1,
        output reg [2 : 0] samples_started,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam [1 : 0] ST_IDLE = 0, ST_START = 1, ST_WAIT = 2;
    reg [1 : 0] state;
    reg [255 : 0] rho_q;
    reg [1 : 0] row_q;
    reg transpose_q;
    reg [1 : 0] element;
    reg child_zeroize_req;
    wire child_zeroize_busy, child_zeroize_done;

    wire child_start = (state == ST_START);
    wire child_busy;
    wire child_done;
    wire child_error;
    wire [31 : 0] groups_requested;
    wire [31 : 0] candidates_accepted;
    wire [31 : 0] candidates_rejected;

    assign sample_index0 = transpose_q ? {6'd0, row_q} : {6'd0, element};
    assign sample_index1 = transpose_q ? {6'd0, element} : {6'd0, row_q};
    assign out_poly_index = element;

    mlkem_sample_ntt sample_ntt(
                             .clk(clk),
                             .rst_n(rst_n),
                             .start(child_start),
                             .seed(rho_q),
                             .index0(sample_index0),
                             .index1(sample_index1),
                             .use_generic_input(1'b0),
                             .generic_input(272'd0),
                             .busy(child_busy),
                             .done(child_done),
                             .error(child_error),
                             .out_valid(out_valid),
                             .out_ready(out_ready),
                             .out_coeff(out_coeff),
                             .out_index(out_index),
                             .out_domain(out_domain),
                             .groups_requested(groups_requested),
                             .candidates_accepted(candidates_accepted),
                             .candidates_rejected(candidates_rejected),
                             .zeroize_req(child_zeroize_req),
                             .zeroize_busy(child_zeroize_busy),
                             .zeroize_done(child_zeroize_done));

    always @(posedge clk) begin
        child_zeroize_req <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= ST_IDLE;
            rho_q <= 0;
            row_q <= 0;
            transpose_q <= 0;
            element <= 0;
            samples_started <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            state <= ST_IDLE;
            rho_q <= 0;
            row_q <= 0;
            transpose_q <= 0;
            element <= 0;
            samples_started <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
        end else if (zeroize_busy) begin
            state <= ST_IDLE;
            rho_q <= 0;
            row_q <= 0;
            transpose_q <= 0;
            element <= 0;
            samples_started <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            child_zeroize_req <= 1;
            if (child_zeroize_done) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
                child_zeroize_req <= 0;
            end
        end else begin
            done <= 0;
            if (child_error)
                error <= 1;
            if (start && busy)
                error <= 1;
            case (state)
                ST_IDLE:
                    if (start) begin
                        if (row > 2) begin
                            error <= 1;
                        end else begin
                            rho_q <= rho;
                            row_q <= row;
                            transpose_q <= transpose;
                            element <= 0;
                            samples_started <= 0;
                            busy <= 1;
                            error <= 0;
                            state <= ST_START;
                        end
                    end
                ST_START: begin
                    samples_started <= samples_started + 1'b1;
                    state <= ST_WAIT;
                end
                ST_WAIT:
                    if (child_done) begin
                        if (element == 2) begin
                            busy <= 0;
                            done <= 1;
                            state <= ST_IDLE;
                        end else begin
                            element <= element + 1'b1;
                            state <= ST_START;
                        end
                    end
                default:
                    state <= ST_IDLE;
            endcase
        end
    end
endmodule
