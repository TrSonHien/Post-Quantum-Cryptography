`timescale 1ns/1ps
`include "kyber_params.vh"

module mod_mul #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire [`KYBER_Q_WIDTH:0] a,
    input  wire [`KYBER_Q_WIDTH:0] b,
    output wire [`KYBER_Q_WIDTH:0] c
);

    wire signed [31:0] product;
    wire signed [15:0] mont_result;

    wire signed [16:0] mont_ext;
    wire signed [16:0] canoninal;

    // a and b are unsigned canonical coefficients.
    // Product is positive and fits easily in 32 bits.

    assign product = $signed({20'd0, a}) * $signed({20'd0, b});
    
    montgomery_reduce #(.Q(Q)) u_montgomery_reduce ( .a(product), .r(mont_result) );
    
    // montgomery_reduce returns a signed value roughly in:
    //     {-q+1, ..., q-1}
    //
    // Convert it to canonical unsigned:
    //     if negative, add q
    assign mont_ext  = {mont_result[15], mont_result};
    assign canoninal = (mont_ext < 0) ? (mont_ext + Q) : mont_ext;
    assign c         = canoninal[`KYBER_Q_WIDTH:0]; 

endmodule
