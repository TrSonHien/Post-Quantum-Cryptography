`timescale 1ns / 1ps

// Samples one K=3 NORMAL-domain noise vector using consecutive PRF nonces.
/*
 * Module: kpke_noise_vector_sampler
 * Status: ACTIVE_RELEASE_PATH
 * Purpose: K-PKE controller or deterministic matrix/noise orchestration.
 * Standard role: FIPS 203 Algorithms 13--15 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: valid/ready handshake as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mlkem_noise_sampler.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module kpke_noise_vector_sampler
    (
        input wire clk,
        input wire rst_n,
        input wire start,
        input wire [255 : 0] seed,
        input wire [7 : 0] start_nonce,
        input wire [1 : 0] eta,
        output reg busy,
        output reg done,
        output reg error,
        output wire out_valid,
        input wire out_ready,
        output wire [11 : 0] out_coeff,
        output wire [7 : 0] out_index,
        output wire [1 : 0] out_poly_index,
        output wire [1 : 0] out_domain,
        output wire [7 : 0] active_nonce,
        output reg [7 : 0] next_nonce,
        output reg [2 : 0] samples_started,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    localparam [1 : 0] ST_IDLE = 0, ST_START = 1, ST_WAIT = 2;
    reg [1 : 0] state;
    reg [255 : 0] seed_q;
    reg [7 : 0] nonce_q;
    reg [1 : 0] eta_q;
    reg [1 : 0] element;
    reg child_zeroize_req;
    wire child_zeroize_busy, child_zeroize_done;

    wire child_start = (state == ST_START);
    wire child_busy;
    wire child_done;
    wire child_error;
    assign active_nonce = nonce_q + element;
    assign out_poly_index = element;

    mlkem_noise_sampler noise_sampler(
                                .clk(clk),
                                .rst_n(rst_n),
                                .start(child_start),
                                .seed(seed_q),
                                .nonce(active_nonce),
                                .eta(eta_q),
                                .busy(child_busy),
                                .done(child_done),
                                .error(child_error),
                                .out_valid(out_valid),
                                .out_ready(out_ready),
                                .out_coeff(out_coeff),
                                .out_index(out_index),
                                .out_domain(out_domain),
                                .zeroize_req(child_zeroize_req),
                                .zeroize_busy(child_zeroize_busy),
                                .zeroize_done(child_zeroize_done));

    always @(posedge clk) begin
        child_zeroize_req <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            state <= ST_IDLE;
            seed_q <= 0;
            nonce_q <= 0;
            eta_q <= 0;
            element <= 0;
            next_nonce <= 0;
            samples_started <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            state <= ST_IDLE;
            seed_q <= 0;
            nonce_q <= 0;
            eta_q <= 0;
            element <= 0;
            next_nonce <= 0;
            samples_started <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
        end else if (zeroize_busy) begin
            state <= ST_IDLE;
            seed_q <= 0;
            nonce_q <= 0;
            eta_q <= 0;
            element <= 0;
            next_nonce <= 0;
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
                        if (eta != 2 && eta != 3) begin
                            error <= 1;
                        end else begin
                            seed_q <= seed;
                            nonce_q <= start_nonce;
                            eta_q <= eta;
                            element <= 0;
                            next_nonce <= start_nonce + 8'd3;
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
