`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: butterfly_pipe
//
// Mathematical Contract:
//   Inputs:
//     - u, v: canonical unsigned coefficients in [0, q-1] (q = 3329)
//     - zeta_mont: canonical Montgomery representation scaled by R:
//                  zeta_mont = zeta * R mod q (R = 2^16)
//
//   Operation:
//     t = MontgomeryReduce(zeta_mont * v) = zeta * v mod q
//     out0 = (u + t) mod q
//     out1 = (u - t) mod q
//
//   Outputs:
//     - out0, out1: canonical unsigned coefficients in [0, q-1]
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
module butterfly_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [11:0] u,
    input  wire [11:0] v,
    input  wire [11:0] zeta_mont,
    output wire        out_valid,
    output wire [11:0] out0,
    output wire [11:0] out1
);

    // Simulation assertions
    // synopsys translate_off
    always @(posedge clk) begin
        if (in_valid) begin
            if (u >= 12'd3329) begin
                $display("ASSERTION FAILED in butterfly_pipe: input u=%0d >= 3329", u);
                $fatal(1);
            end
            if (v >= 12'd3329) begin
                $display("ASSERTION FAILED in butterfly_pipe: input v=%0d >= 3329", v);
                $fatal(1);
            end
            if (zeta_mont >= 12'd3329) begin
                $display("ASSERTION FAILED in butterfly_pipe: input zeta_mont=%0d >= 3329", zeta_mont);
                $fatal(1);
            end
        end
        if (out_valid) begin
            if (out0 >= 12'd3329) begin
                $display("ASSERTION FAILED in butterfly_pipe: output out0=%0d >= 3329", out0);
                $fatal(1);
            end
            if (out1 >= 12'd3329) begin
                $display("ASSERTION FAILED in butterfly_pipe: output out1=%0d >= 3329", out1);
                $fatal(1);
            end
        end
    end
    // synopsys translate_on

    // Stage 1-4: Montgomery multiply
    wire [11:0] t;
    wire        mul_valid;

    mod_mul_pipe u_mul (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .a(zeta_mont),
        .b(v),
        .out_valid(mul_valid),
        .r(t)
    );

    // Delay u by 4 stages to align with t
    wire [11:0] u_delayed;
    wire        val_delayed;
    wire        dummy_meta;

    fixed_latency_delay #(
        .PAYLOAD_WIDTH(12),
        .METADATA_WIDTH(1),
        .LATENCY(4)
    ) u_delay (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_payload(u),
        .in_metadata(1'b0),
        .out_valid(val_delayed),
        .out_payload(u_delayed),
        .out_metadata(dummy_meta)
    );

    // Stage 5: modular addition and subtraction
    // Inputs: u_delayed and t
    mod_add_pipe u_add (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(mul_valid),
        .a(u_delayed),
        .b(t),
        .out_valid(out_valid),
        .r(out0)
    );

    mod_sub_pipe u_sub (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(mul_valid),
        .a(u_delayed),
        .b(t),
        .out_valid(), // out_valid is shared with u_add
        .r(out1)
    );

endmodule
