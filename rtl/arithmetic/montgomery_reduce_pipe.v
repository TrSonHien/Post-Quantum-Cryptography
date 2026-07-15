`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: montgomery_reduce_pipe
//
// Operation:
//   r = a * R^-1 mod q
//
// Latency: 3 cycles
// Initiation Interval (II): 1
//
// Constraints:
//   - Input a: 32-bit unsigned
//   - Valid range: 0 <= a < q*R (q = 3329, R = 2^16, q*R = 218,169,344)
//   - Output r: 12-bit unsigned canonical coefficient (0 <= r < 3329)
//   - Reset clears valid registers only; payload registers need not reset.
//   - Unsigned arithmetic only. No division, modulo, or arithmetic right shifts.
// -----------------------------------------------------------------------------
module montgomery_reduce_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [31:0] a,
    output reg         out_valid,
    output reg  [11:0] r,
    input  wire        zeroize_req,
    output reg         zeroize_busy,
    output reg         zeroize_done
);

    // Simulation assertion for input range check
    // synopsys translate_off
    always @(posedge clk) begin
        if (in_valid && !zeroize_busy && a >= 32'd218169344) begin
            $display("ASSERTION FAILED in montgomery_reduce_pipe: input a=%0d >= q*R (218169344)", a);
            $fatal(1);
        end
    end
    // synopsys translate_on

    // Stage 1 registers
    reg         val_d1;
    reg  [15:0] m_reg;
    reg  [31:0] a_d1;

    // Stage 2 registers
    reg         val_d2;
    reg  [27:0] mq_reg; // 16-bit m * 12-bit q (3329) fits in 28 bits
    reg  [31:0] a_d2;

    // Intermediate wires for Stage 3
    wire [32:0] sum;
    wire [16:0] t;
    wire [16:0] t_sub;
    wire [11:0] r_next;

    // Stage 3 logic
    assign sum      = {1'b0, a_d2} + {5'b0, mq_reg};
    assign t        = sum[32:16];
    assign t_sub    = t - 17'd3329;
    assign r_next   = (t >= 17'd3329) ? t_sub[11:0] : t[11:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            val_d1 <= 1'b0;val_d2 <= 1'b0;out_valid <= 1'b0;
            zeroize_busy <= 1'b0;zeroize_done <= 1'b0;
        end else begin
            zeroize_done <= 1'b0;
            if (zeroize_req === 1'b1 && !zeroize_busy) begin
                val_d1 <= 1'b0;val_d2 <= 1'b0;out_valid <= 1'b0;
                m_reg <= 16'd0;a_d1 <= 32'd0;mq_reg <= 28'd0;a_d2 <= 32'd0;r <= 12'd0;
                zeroize_busy <= 1'b1;
            end else if (zeroize_busy) begin
                val_d1 <= 1'b0;val_d2 <= 1'b0;out_valid <= 1'b0;
                m_reg <= 16'd0;a_d1 <= 32'd0;mq_reg <= 28'd0;a_d2 <= 32'd0;r <= 12'd0;
                zeroize_busy <= 1'b0;zeroize_done <= 1'b1;
            end else begin
                val_d1 <= in_valid;val_d2 <= val_d1;out_valid <= val_d2;
                if (in_valid) begin
                    m_reg <= a[15:0] * 16'd3327;
                    a_d1 <= a;
                end
                if (val_d1) begin
                    mq_reg <= m_reg * 28'd3329;
                    a_d2 <= a_d1;
                end
                if (val_d2)
                    r <= r_next;
            end
        end
    end

endmodule
