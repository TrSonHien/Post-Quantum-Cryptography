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
    output wire        last_out,
    input  wire        zeroize_req,
    output reg         zeroize_busy,
    output reg         zeroize_done
);
    localparam MOD_MUL_LATENCY = 4;
    wire lane0_valid;
    wire lane1_valid;
    wire metadata_valid;
    wire [7:0] metadata_out;
    wire metadata_unused;
    wire lane0_zeroize_done,lane1_zeroize_done,meta_zeroize_done;
    wire lane0_zeroize_busy,lane1_zeroize_busy,meta_zeroize_busy;
    wire[11:0]lane0_out,lane1_out;reg child_zeroize_req;reg[2:0]child_done_seen;

    mod_mul_pipe u_lane0 (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid&&!zeroize_busy),
        .a(in0), .b(12'd512), .out_valid(lane0_valid), .r(lane0_out),
        .zeroize_req(child_zeroize_req),.zeroize_busy(lane0_zeroize_busy),.zeroize_done(lane0_zeroize_done)
    );
    mod_mul_pipe u_lane1 (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid&&!zeroize_busy),
        .a(in1), .b(12'd512), .out_valid(lane1_valid), .r(lane1_out),
        .zeroize_req(child_zeroize_req),.zeroize_busy(lane1_zeroize_busy),.zeroize_done(lane1_zeroize_done)
    );
    fixed_latency_delay #(
        .PAYLOAD_WIDTH(8), .METADATA_WIDTH(1), .LATENCY(MOD_MUL_LATENCY)
    ) u_metadata_delay (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid&&!zeroize_busy),
        .in_payload({pair_idx, last_in}), .in_metadata(1'b0),
        .out_valid(metadata_valid), .out_payload(metadata_out),
        .out_metadata(metadata_unused),.zeroize_req(child_zeroize_req),
        .zeroize_busy(meta_zeroize_busy),.zeroize_done(meta_zeroize_done)
    );

    assign out_valid = !zeroize_busy&&lane0_valid && lane1_valid && metadata_valid;
    assign out0=lane0_out;assign out1=lane1_out;
    assign pair_idx_out = metadata_out[7:1];
    assign last_out = metadata_out[0];

    always@(posedge clk)begin
        zeroize_done<=0;child_zeroize_req<=0;
        if(!rst_n)begin zeroize_busy<=0;zeroize_done<=0;child_zeroize_req<=0;child_done_seen<=0;end
        else if(zeroize_req===1'b1&&!zeroize_busy)begin zeroize_busy<=1;child_zeroize_req<=1;child_done_seen<=0;end
        else if(zeroize_busy)begin
            child_done_seen<=child_done_seen|{meta_zeroize_done,lane1_zeroize_done,lane0_zeroize_done};
            if(&(child_done_seen|{meta_zeroize_done,lane1_zeroize_done,lane0_zeroize_done}))begin zeroize_busy<=0;zeroize_done<=1;end
        end
    end

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
