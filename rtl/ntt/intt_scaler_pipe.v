`timescale 1ns/1ps

// Two-lane final INTT scaler. Each lane computes x * 512 * R^-1 mod 3329,
// which is x * 3303 mod 3329 in the normal domain.
module intt_scaler_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [11:0] in0,
    input  wire [11:0] in1,
    input  wire [6:0]  pair_idx,
    input  wire        last_in,
    output wire        out_valid,
    output wire [11:0] out0,
    output wire [11:0] out1,
    output wire [6:0]  pair_idx_out,
    output wire        last_out
);
    localparam MOD_MUL_LATENCY = 4;
    wire lane0_valid;
    wire lane1_valid;
    wire metadata_valid;
    wire [7:0] metadata_out;
    wire metadata_unused;

    mod_mul_pipe u_lane0 (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid),
        .a(in0), .b(12'd512), .out_valid(lane0_valid), .r(out0)
    );
    mod_mul_pipe u_lane1 (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid),
        .a(in1), .b(12'd512), .out_valid(lane1_valid), .r(out1)
    );
    fixed_latency_delay #(
        .PAYLOAD_WIDTH(8), .METADATA_WIDTH(1), .LATENCY(MOD_MUL_LATENCY)
    ) u_metadata_delay (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid),
        .in_payload({pair_idx, last_in}), .in_metadata(1'b0),
        .out_valid(metadata_valid), .out_payload(metadata_out),
        .out_metadata(metadata_unused)
    );

    assign out_valid = lane0_valid && lane1_valid && metadata_valid;
    assign pair_idx_out = metadata_out[7:1];
    assign last_out = metadata_out[0];

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (rst_n && ((lane0_valid !== lane1_valid) ||
                      (lane0_valid !== metadata_valid)))
            $fatal(1, "INTT_SCALER_ALIGNMENT: lane and metadata valid mismatch");
        if (out_valid && (out0 >= 12'd3329 || out1 >= 12'd3329))
            $fatal(1, "INTT_SCALER_RANGE: non-canonical output");
    end
`endif
endmodule
