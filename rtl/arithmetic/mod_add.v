`timescale 1ns/1ps
`include "kyber_params.vh"

module mod_add (
    input  wire [`KYBER_Q_WIDTH-1:0] a,
    input  wire [`KYBER_Q_WIDTH-1:0] b,
    output wire [`KYBER_Q_WIDTH-1:0] c
);

    wire [`KYBER_SUM_WIDTH-1:0] sum;
    wire [`KYBER_SUM_WIDTH-1:0] reduced_sum;

    assign sum = {1'b0, a} + {1'b0, b};
    assign reduced_sum = (sum >= `KYBER_Q) ? (sum - `KYBER_Q) : sum;
    assign c = reduced_sum[`KYBER_Q_WIDTH-1:0];

endmodule
