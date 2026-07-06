`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: basemul_unit
// Description:
//   High-throughput pipelined base multiplication unit for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c: basemul()
//
// C reference:
//
//   r[0]  = fqmul(a[1], b[1]);
//   r[0]  = fqmul(r[0], zeta);
//   r[0] += fqmul(a[0], b[0]);
//
//   r[1]  = fqmul(a[0], b[1]);
//   r[1] += fqmul(a[1], b[0]);
//
// RTL equation:
//
//   t0 = mod_mul(a1, b1)
//   t1 = mod_mul(t0, zeta)
//   t2 = mod_mul(a0, b0)
//   r0 = mod_add(t1, t2)
//
//   t3 = mod_mul(a0, b1)
//   t4 = mod_mul(a1, b0)
//   r1 = mod_add(t3, t4)
//
// Architecture priority:
//   This is the main high-frequency/high-throughput basemul implementation.
//   It intentionally spends area to reduce cycle count and improve throughput.
//
// Pipeline:
//   Stage 1:
//       t0 = mod_mul(a1, b1)
//       t2 = mod_mul(a0, b0)
//       t3 = mod_mul(a0, b1)
//       t4 = mod_mul(a1, b0)
//       register t0/t2/t3/t4/zeta and valid
//
//   Stage 2:
//       t1 = mod_mul(t0, zeta)
//       register t1/t2/t3/t4 and valid
//
//   Stage 3:
//       r0 = mod_add(t1, t2)
//       r1 = mod_add(t3, t4)
//       register r0/r1 and out_valid
//
// Expected timing:
//   - Latency: 3 cycles from in_valid input to out_valid output.
//   - Throughput: 1 basemul result per cycle after pipeline fill.
//   - Resources: 5 mod_mul and 2 mod_add.
//
// Interface:
//   - Coefficients are canonical unsigned values: 0 <= coeff < KYBER_Q.
//   - No in_ready/out_ready backpressure is implemented.
//   - This module has no backpressure support.
//   - The downstream block must accept r0/r1 whenever out_valid is high.
//
// Future note:
//   This module assumes the current mod_mul and mod_add blocks are
//   combinational. If future mod_mul/Montgomery reduction becomes pipelined,
//   this module will need latency realignment for t1/t2/t3/t4 and out_valid.
// -----------------------------------------------------------------------------

module basemul_unit #(
    parameter WIDTH = `KYBER_Q_WIDTH
)(
    input  wire clk,
    input  wire rst_n,

    input  wire             in_valid,
    input  wire [WIDTH-1:0] a0,
    input  wire [WIDTH-1:0] a1,
    input  wire [WIDTH-1:0] b0,
    input  wire [WIDTH-1:0] b1,
    input  wire [WIDTH-1:0] zeta,

    output reg              out_valid,
    output reg  [WIDTH-1:0] r0,
    output reg  [WIDTH-1:0] r1
);

    // -------------------------------------------------------------------------
    // Stage 1: four independent fqmul operations.
    // -------------------------------------------------------------------------
    wire [WIDTH-1:0] s1_t0_next;
    wire [WIDTH-1:0] s1_t2_next;
    wire [WIDTH-1:0] s1_t3_next;
    wire [WIDTH-1:0] s1_t4_next;

    reg              s1_valid;
    reg  [WIDTH-1:0] s1_t0;
    reg  [WIDTH-1:0] s1_t2;
    reg  [WIDTH-1:0] s1_t3;
    reg  [WIDTH-1:0] s1_t4;
    reg  [WIDTH-1:0] s1_zeta;

    mod_mul u_mul_a1_b1 (
        .a (a1),
        .b (b1),
        .c (s1_t0_next)
    );

    mod_mul u_mul_a0_b0 (
        .a (a0),
        .b (b0),
        .c (s1_t2_next)
    );

    mod_mul u_mul_a0_b1 (
        .a (a0),
        .b (b1),
        .c (s1_t3_next)
    );

    mod_mul u_mul_a1_b0 (
        .a (a1),
        .b (b0),
        .c (s1_t4_next)
    );

    // -------------------------------------------------------------------------
    // Stage 2: multiply t0 by zeta and align the remaining terms.
    // -------------------------------------------------------------------------
    wire [WIDTH-1:0] s2_t1_next;

    reg              s2_valid;
    reg  [WIDTH-1:0] s2_t1;
    reg  [WIDTH-1:0] s2_t2;
    reg  [WIDTH-1:0] s2_t3;
    reg  [WIDTH-1:0] s2_t4;

    mod_mul u_mul_t0_zeta (
        .a (s1_t0),
        .b (s1_zeta),
        .c (s2_t1_next)
    );

    // -------------------------------------------------------------------------
    // Stage 3: final modular additions.
    // -------------------------------------------------------------------------
    wire [WIDTH-1:0] r0_next;
    wire [WIDTH-1:0] r1_next;

    mod_add u_add_r0 (
        .a (s2_t1),
        .b (s2_t2),
        .c (r0_next)
    );

    mod_add u_add_r1 (
        .a (s2_t3),
        .b (s2_t4),
        .c (r1_next)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            s1_t0    <= {WIDTH{1'b0}};
            s1_t2    <= {WIDTH{1'b0}};
            s1_t3    <= {WIDTH{1'b0}};
            s1_t4    <= {WIDTH{1'b0}};
            s1_zeta  <= {WIDTH{1'b0}};

            s2_valid <= 1'b0;
            s2_t1    <= {WIDTH{1'b0}};
            s2_t2    <= {WIDTH{1'b0}};
            s2_t3    <= {WIDTH{1'b0}};
            s2_t4    <= {WIDTH{1'b0}};

            out_valid <= 1'b0;
            r0        <= {WIDTH{1'b0}};
            r1        <= {WIDTH{1'b0}};
        end else begin
            s1_valid <= in_valid;
            s1_t0    <= s1_t0_next;
            s1_t2    <= s1_t2_next;
            s1_t3    <= s1_t3_next;
            s1_t4    <= s1_t4_next;
            s1_zeta  <= zeta;

            s2_valid <= s1_valid;
            s2_t1    <= s2_t1_next;
            s2_t2    <= s1_t2;
            s2_t3    <= s1_t3;
            s2_t4    <= s1_t4;

            out_valid <= s2_valid;
            r0        <= r0_next;
            r1        <= r1_next;
        end
    end

endmodule
