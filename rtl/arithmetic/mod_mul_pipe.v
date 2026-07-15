`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: mod_mul_pipe
//
// Mathematical Contract:
//   r = a * b * R^-1 mod q
//   where q = 3329, R = 2^16, R^-1 mod q = 169
//
// Latency: 4 cycles
// Initiation Interval (II): 1
//
// Inputs:
//   - a, b: 12-bit unsigned canonical values in [0, 3328]
// Output:
//   - r: 12-bit unsigned canonical value in [0, 3328]
//
// Semantic Note:
//   This module does NOT compute ordinary modular multiplication (a * b mod q).
//   It computes a * b * R^-1 mod q, which becomes ordinary modular multiplication
//   only when operands are properly scaled in the Montgomery domain.
//
// Architecture:
//   Stage 1: Multiplies inputs and registers the 24-bit product and valid.
//   Stages 2-4: Passes product through montgomery_reduce_pipe.
// -----------------------------------------------------------------------------
module mod_mul_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire        out_valid,
    output wire [11:0] r,
    input  wire        zeroize_req,
    output reg         zeroize_busy,
    output reg         zeroize_done
);

    // Simulation assertions for input range check
    // synopsys translate_off
    always @(posedge clk) begin
        if (in_valid && !zeroize_busy) begin
            if (a >= 12'd3329) begin
                $display("ASSERTION FAILED in mod_mul_pipe: input a=%0d >= 3329", a);
                $fatal(1);
            end
            if (b >= 12'd3329) begin
                $display("ASSERTION FAILED in mod_mul_pipe: input b=%0d >= 3329", b);
                $fatal(1);
            end
        end
    end
    // synopsys translate_on

    // Stage 1 registers
    reg         val_s1;
    reg  [23:0] prod_s1; // Full 12x12 product fits in 24 bits
    reg child_zeroize_req;
    wire child_zeroize_busy,child_zeroize_done,child_out_valid;
    wire[11:0]child_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            val_s1 <= 1'b0;
            zeroize_busy <= 1'b0;zeroize_done <= 1'b0;child_zeroize_req <= 1'b0;
        end else begin
            zeroize_done <= 1'b0;child_zeroize_req <= 1'b0;
            if(zeroize_req===1'b1&&!zeroize_busy)begin
                val_s1<=1'b0;prod_s1<=24'd0;zeroize_busy<=1'b1;child_zeroize_req<=1'b1;
            end else if(zeroize_busy)begin
                val_s1<=1'b0;prod_s1<=24'd0;
                if(child_zeroize_done)begin zeroize_busy<=1'b0;zeroize_done<=1'b1;end
            end else begin
                val_s1 <= in_valid;
                if (in_valid) prod_s1 <= a * b;
            end
        end
    end

    // Instantiation of the verified Montgomery reduction pipeline
    // This handles Stages 2-4 (3 cycles of latency)
    montgomery_reduce_pipe u_reduce (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(val_s1&&!zeroize_busy),
        .a({{8{1'b0}}, prod_s1}), // zero-extended to 32 bits
        .out_valid(child_out_valid),
        .r(child_r),.zeroize_req(child_zeroize_req),
        .zeroize_busy(child_zeroize_busy),.zeroize_done(child_zeroize_done)
    );

    assign out_valid=!zeroize_busy&&child_out_valid;
    assign r=child_r;

endmodule
