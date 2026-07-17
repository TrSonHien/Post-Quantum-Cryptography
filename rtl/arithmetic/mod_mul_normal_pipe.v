`timescale 1ns / 1ps

// Canonical ordinary modular multiplication: r = a*b mod 3329.
// Latency 4 cycles, II=1. Reset clears validity only.
/*
 * Module: mod_mul_normal_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Mod-q arithmetic leaf used by the polynomial datapath.
 * Standard role: FIPS 203 modular arithmetic support.
 * Input representation: canonical coefficient or stated arithmetic operand.
 * Output representation: canonical coefficient or registered arithmetic result.
 * Interface: valid-only pipeline as declared.
 * Latency / completion: fixed 4 cycles.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: barrett_reduce_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mod_mul_normal_pipe
    (input wire clk,
     input wire rst_n,
     input wire in_valid,
     input wire [11 : 0] a,
     input wire [11 : 0] b,
     output wire out_valid,
     output wire [11 : 0] r,
     input wire zeroize_req,
     output reg zeroize_busy,
     output reg zeroize_done);
    reg valid_s1;
    reg [23 : 0] product_s1;
    reg child_zeroize_req;
    wire child_zeroize_busy, child_zeroize_done, child_out_valid;
    wire [11 : 0] child_r;
    always @(posedge clk) begin
        child_zeroize_req <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            valid_s1 <= 0;
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            valid_s1 <= 0;
            product_s1 <= 0;
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
        end else if (zeroize_busy) begin
            valid_s1 <= 0;
            product_s1 <= 0;
            if (child_zeroize_done) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
            end
        end else begin
            valid_s1 <= in_valid;
            if (in_valid)
                product_s1 <= a * b;
        end
    end
    barrett_reduce_pipe reduce(.clk(clk),
                               .rst_n(rst_n),
                               .in_valid(valid_s1),
                               .a({8'd0, product_s1}),
                               .out_valid(child_out_valid),
                               .r(child_r),
                               .zeroize_req(child_zeroize_req),
                               .zeroize_busy(child_zeroize_busy),
                               .zeroize_done(child_zeroize_done));
    assign out_valid = !zeroize_busy && child_out_valid;
    assign r = child_r;
`ifndef SYNTHESIS
    always @(posedge clk)
        if (rst_n && in_valid && !zeroize_busy && (a >= 3329 || b >= 3329))
            $fatal(1, "MOD_MUL_NORMAL_RANGE a=%0d b=%0d", a, b);
`endif
endmodule
