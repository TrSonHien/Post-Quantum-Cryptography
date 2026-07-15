`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: barrett_reduce_pipe
//
// Mathematical Contract:
//   q = 3329
//   mu = floor(2^48 / q) = 84552411147
//
//   quotient   = floor((a * mu) / 2^48)
//   remainder0 = a - quotient * q
//   r          = (remainder0 >= q) ? remainder0 - q : remainder0
//
// Latency: 3 cycles
// Initiation Interval (II): 1
//
// Inputs:
//   - Input a: 32-bit unsigned (full range 0 <= a <= 32'hFFFF_FFFF)
// Output:
//   - Output r: 12-bit unsigned canonical value (0 <= r < 3329)
// -----------------------------------------------------------------------------
module barrett_reduce_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [31:0] a,
    output reg         out_valid,
    output reg  [11:0] r,
    input wire zeroize_req,output reg zeroize_busy,output reg zeroize_done
);

    // Stage 1 registers
    reg         val_d1;
    reg  [68:0] prod1; // 32-bit a * 37-bit mu fits in 69 bits
    reg  [31:0] a_d1;

    // Stage 2 registers
    reg         val_d2;
    reg  [32:0] prod2; // 21-bit quotient * 12-bit q (3329) fits in 33 bits
    reg  [31:0] a_d2;

    // Stage 3 wires
    wire [20:0] quotient;
    wire [33:0] remainder0_full;
    wire [12:0] remainder0;
    wire [12:0] remainder1;
    wire [11:0] r_next;

    // Stage 1 Logic
    always @(posedge clk) begin
        if (!rst_n) begin
            val_d1 <= 1'b0;zeroize_busy<=0;zeroize_done<=0;
        end else if((zeroize_req===1'b1)&&!zeroize_busy)begin
            val_d1<=0;zeroize_busy<=1;zeroize_done<=0;
        end else if(zeroize_busy)begin
            val_d1<=0;zeroize_busy<=0;zeroize_done<=1;
        end else begin
            val_d1 <= in_valid;zeroize_done<=0;
        end
    end

    always @(posedge clk) begin
        if ((zeroize_req===1'b1)||zeroize_busy)begin prod1<=0;a_d1<=0;end
        else if (in_valid) begin
            prod1 <= a * 37'd84552411147;
            a_d1  <= a;
        end
    end

    // Stage 2 Logic
    assign quotient = prod1[68:48]; // bits 68 down to 48 represents >> 48

    always @(posedge clk) begin
        if (!rst_n) begin
            val_d2 <= 1'b0;
        end else if((zeroize_req===1'b1)||zeroize_busy)begin
            val_d2<=0;
        end else begin
            val_d2 <= val_d1;
        end
    end

    always @(posedge clk) begin
        if ((zeroize_req===1'b1)||zeroize_busy)begin prod2<=0;a_d2<=0;end
        else if (val_d1) begin
            prod2 <= quotient * 33'd3329;
            a_d2  <= a_d1;
        end
    end

    // Stage 3 Logic
    assign remainder0_full = {2'b0, a_d2} - {1'b0, prod2};
    assign remainder0      = remainder0_full[12:0];
    assign remainder1      = remainder0 - 13'd3329;
    assign r_next          = (remainder0 >= 13'd3329) ? remainder1[11:0] : remainder0[11:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else if((zeroize_req===1'b1)||zeroize_busy)begin
            out_valid<=0;
        end else begin
            out_valid <= val_d2;
        end
    end

    always @(posedge clk) begin
        if ((zeroize_req===1'b1)||zeroize_busy)r<=0;
        else if (val_d2) begin
            r <= r_next;
        end
    end

    // Simulation assertions
    // synopsys translate_off
    always @(posedge clk) begin
        if (val_d2 && !zeroize_busy && zeroize_req!==1'b1) begin
            if (prod2 > a_d2) begin
                $display("ASSERTION FAILED in barrett_reduce_pipe: quotient*q (%0d) > a (%0d)", prod2, a_d2);
                $fatal(1);
            end
            if (remainder0 >= 13'd6658) begin
                $display("ASSERTION FAILED in barrett_reduce_pipe: remainder0 (%0d) >= 2*q (6658)", remainder0);
                $fatal(1);
            end
            if (r_next >= 12'd3329) begin
                $display("ASSERTION FAILED in barrett_reduce_pipe: final r (%0d) >= q (3329)", r_next);
                $fatal(1);
            end
        end
    end
    // synopsys translate_on

endmodule
