`timescale 1ns/1ps
`include "kyber_params.vh"

// --------------------------------
// Rederence
// kyber768/reduce.c
// --------------------------------

module montgomery_reduce #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire signed [31:0] a,
    output wire signed [15:0] r
);

    localparam signed [31:0] QINV = -32'sd3327;

    wire signed [63:0] a_qinv_full;
    wire signed [15:0] u;
    wire signed [32:0] uq;
    wire signed [32:0] t;
    
    // Therefore only the low 16 bits are kept and interpreted as signed
    assign a_qinv_full = $signed(a) * $signed(QINV);
    assign u           = a_qinv_full[15:0];

    // t = a - (int32_t)u * q
    assign uq = $signed(u) * $signed(Q);
    assign t  = $signed(a) - $signed(uq);

    // arithmetic right shift by 16
    assign r = t >>> 16;

endmodule


module barrett_reduce #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire signed [31:0] a,
    output wire signed [15:0] r
);

    localparam signed [31:0] V = 32'sd20159;

    wire signed [31:0] a_ext;
    wire signed [31:0] prod;
    wire signed [31:0] t;
    wire signed [31:0] tq;
    wire signed [31:0] r_full;

    assign a_ext = {{16{a[15]}}, a};

    // t = (v * a) >> 26
    assign prod =  $signed(V) * $signed(a_ext);
    assign t    =  prod >>> 26;

    // r = a - t * q
    assign tq     = $signed(t) * $signed(Q);
    assign r_full = $signed(a_ext) - $signed(tq);

    assign r = r_full[15:0];

endmodule


module conditional_sub_q #(
    parameter signed [31:0] Q = `KYBER_Q
)(
    input  wire [15:0] a,
    output wire [15:0] r
);

    assign r = (a >= Q) ? (a - Q) : a;

endmodule

