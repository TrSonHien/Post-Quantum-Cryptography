`timescale 1ns/1ps

module rv_register_slice #(
    parameter PAYLOAD_WIDTH = 32,
    parameter METADATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      in_valid,
    output wire                      in_ready,
    input  wire [PAYLOAD_WIDTH-1:0]  in_payload,
    input  wire [METADATA_WIDTH-1:0] in_metadata,
    output reg                       out_valid,
    input  wire                      out_ready,
    output reg  [PAYLOAD_WIDTH-1:0]  out_payload,
    output reg  [METADATA_WIDTH-1:0] out_metadata
);

    assign in_ready = !out_valid || out_ready;

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) begin
                out_payload <= in_payload;
                out_metadata <= in_metadata;
            end
        end
    end

endmodule
