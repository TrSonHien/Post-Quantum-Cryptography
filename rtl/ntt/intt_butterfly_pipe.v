`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: intt_butterfly_pipe
//
// FIPS 203 Inverse NTT butterfly Gentleman-Sande (GS) layout:
//   Inputs:
//     - u, v: canonical unsigned coefficients in [0, q-1] (q = 3329)
//             (represent NTT-domain coefficients)
//     - zeta_mont: canonical Montgomery representation scaled by R:
//                  zeta_mont = zeta * R mod q (R = 2^16)
//
//   Operation:
//     sum  = (u + v) mod q
//     diff = (v - u) mod q
//     prod = MontgomeryReduce(zeta_mont * diff) = zeta * (v - u) mod q
//
//   Outputs:
//     - out0 = sum
//     - out1 = prod
//     (Both are canonical unsigned coefficients in [0, q-1])
//
// Latency: 5 cycles
// Initiation Interval (II): 1
//
// Interface:
//   - clk, synchronous active-low rst_n
//   - in_valid
//   - u[11:0], v[11:0], zeta_mont[11:0]
//   - out_valid
//   - out0[11:0], out1[11:0]
// -----------------------------------------------------------------------------
/*
 * Module: intt_butterfly_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: NTT/INTT arithmetic leaf, scheduler, ROM, or transform controller.
 * Standard role: FIPS 203 Algorithms 9--12 support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid-only pipeline as declared.
 * Latency / completion: fixed 5 pipeline stages.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: fixed_latency_delay, mod_add_pipe, mod_mul_pipe, mod_sub_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module intt_butterfly_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire in_valid,
        input wire [11 : 0] u,
        input wire [11 : 0] v,
        input wire [11 : 0] zeta_mont,
        output wire out_valid,
        output wire [11 : 0] out0,
        output wire [11 : 0] out1,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);

    // Simulation assertions
    // synopsys translate_off
    always @(posedge clk) begin
        if (in_valid) begin
            if (u >= 12'd3329) begin
                $display("ASSERTION FAILED in intt_butterfly_pipe: input u=%0d >= 3329", u);
                $fatal(1);
            end
            if (v >= 12'd3329) begin
                $display("ASSERTION FAILED in intt_butterfly_pipe: input v=%0d >= 3329", v);
                $fatal(1);
            end
            if (zeta_mont >= 12'd3329) begin
                $display("ASSERTION FAILED in intt_butterfly_pipe: input zeta_mont=%0d >= 3329", zeta_mont);
                $fatal(1);
            end
        end
        if (out_valid) begin
            if (out0 >= 12'd3329) begin
                $display("ASSERTION FAILED in intt_butterfly_pipe: output out0=%0d >= 3329", out0);
                $fatal(1);
            end
            if (out1 >= 12'd3329) begin
                $display("ASSERTION FAILED in intt_butterfly_pipe: output out1=%0d >= 3329", out1);
                $fatal(1);
            end
        end
    end
    // synopsys translate_on

    // Stage 1: modular add and subtract
    wire [11 : 0] sum;
    wire [11 : 0] diff;
    wire add_sub_valid;
    wire add_zeroize_done, sub_zeroize_done, mul_zeroize_done, delay_zeroize_done;
    wire add_zeroize_busy, sub_zeroize_busy, mul_zeroize_busy, delay_zeroize_busy;
    reg child_zeroize_req;
    reg [3 : 0] child_done_seen;

    mod_add_pipe u_add(
                         .clk(clk),
                         .rst_n(rst_n),
                         .in_valid(in_valid && !zeroize_busy),
                         .a(u),
                         .b(v),
                         .out_valid(add_sub_valid),
                         .r(sum),
                         .zeroize_req(child_zeroize_req),
                         .zeroize_busy(add_zeroize_busy),
                         .zeroize_done(add_zeroize_done));

    mod_sub_pipe u_sub(
                         .clk(clk),
                         .rst_n(rst_n),
                         .in_valid(in_valid),
                         .a(v),
                         // Note Gentleman-Sande subtraction: diff = v - u
                         .b(u),
                         .out_valid(),
                         .r(diff),
                         .zeroize_req(child_zeroize_req),
                         .zeroize_busy(sub_zeroize_busy),
                         .zeroize_done(sub_zeroize_done));

    // Delay zeta_mont by 1 cycle to align with diff at Cycle 1
    reg [11 : 0] zeta_mont_d1;
    always @(posedge clk) begin
        if (!rst_n)
            zeta_mont_d1 <= 12'd0;
        else if (zeroize_req === 1'b1 || zeroize_busy)
            zeta_mont_d1 <= 12'd0;
        else if (in_valid) begin
            zeta_mont_d1 <= zeta_mont;
        end
    end

    // Stages 2-5: Modular multiplier on diff and delayed zeta_mont
    // Latency is 4 cycles. So prod is valid at Cycle 5.
    wire [11 : 0] prod;
    wire mul_valid;

    mod_mul_pipe u_mul(
                         .clk(clk),
                         .rst_n(rst_n),
                         .in_valid(add_sub_valid),
                         .a(zeta_mont_d1),
                         .b(diff),
                         .out_valid(mul_valid),
                         .r(prod),
                         .zeroize_req(child_zeroize_req),
                         .zeroize_busy(mul_zeroize_busy),
                         .zeroize_done(mul_zeroize_done));

    // Delay sum (available at Cycle 1) by 4 cycles to align with prod at Cycle 5
    wire [11 : 0] sum_delayed;
    wire val_delayed;
    wire dummy_meta;

    fixed_latency_delay #(
            .PAYLOAD_WIDTH(12),
            .METADATA_WIDTH(1),
            .LATENCY(4))
        sum_delay(
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(add_sub_valid),
                .in_payload(sum),
                .in_metadata(1'b0),
                .out_valid(val_delayed),
                .out_payload(sum_delayed),
                .out_metadata(dummy_meta),
                .zeroize_req(child_zeroize_req),
                .zeroize_busy(delay_zeroize_busy),
                .zeroize_done(delay_zeroize_done));

    assign out0 = sum_delayed;
    assign out1 = prod;
    assign out_valid = !zeroize_busy && mul_valid;

    always @(posedge clk) begin
        zeroize_done <= 0;
        child_zeroize_req <= 0;
        if (!rst_n) begin
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
        end else if (zeroize_req === 1'b1 && !zeroize_busy) begin
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
            child_done_seen <= 0;
        end else if (zeroize_busy) begin
            child_done_seen <= child_done_seen | {delay_zeroize_done, mul_zeroize_done, sub_zeroize_done, add_zeroize_done};
            if (&(child_done_seen | {delay_zeroize_done, mul_zeroize_done, sub_zeroize_done, add_zeroize_done})) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end
        end
    end
endmodule
