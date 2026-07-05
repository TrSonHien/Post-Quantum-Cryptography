`timescale 1ns/1ps
`include "kyber_params.vh"

module mod_sub (
    input  wire [`KYBER_Q_WIDTH-1:0] a,
    input  wire [`KYBER_Q_WIDTH-1:0] b,
    output wire [`KYBER_Q_WIDTH-1:0] c
);

    wire [`KYBER_SUM_WIDTH-1:0] diff;
    wire [`KYBER_SUM_WIDTH-1:0] adjusted_diff;

    assign diff = {1'b0, a} - {1'b0, b};
    assign adjusted_diff = diff[`KYBER_SUM_WIDTH-1] ? (diff + `KYBER_Q) : diff; 

    assign c = adjusted_diff[`KYBER_Q_WIDTH-1:0];

endmodule 
