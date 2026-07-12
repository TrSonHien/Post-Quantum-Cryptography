`timescale 1ns/1ps

module fixed_latency_delay #(
    parameter PAYLOAD_WIDTH = 12,
    parameter METADATA_WIDTH = 16,
    parameter LATENCY = 1
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      in_valid,
    input  wire [PAYLOAD_WIDTH-1:0]  in_payload,
    input  wire [METADATA_WIDTH-1:0] in_metadata,
    output wire                      out_valid,
    output wire [PAYLOAD_WIDTH-1:0]  out_payload,
    output wire [METADATA_WIDTH-1:0] out_metadata
);

    reg [LATENCY-1:0] valid_pipe;
    reg [PAYLOAD_WIDTH-1:0] payload_pipe [0:LATENCY-1];
    reg [METADATA_WIDTH-1:0] metadata_pipe [0:LATENCY-1];
    integer i;

    initial begin
        if (LATENCY < 1)
            $fatal(1, "fixed_latency_delay requires LATENCY >= 1");
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_pipe <= {LATENCY{1'b0}};
        end else begin
            valid_pipe[0] <= in_valid;
            if (in_valid) begin
                payload_pipe[0] <= in_payload;
                metadata_pipe[0] <= in_metadata;
            end
            for (i = 1; i < LATENCY; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                if (valid_pipe[i-1]) begin
                    payload_pipe[i] <= payload_pipe[i-1];
                    metadata_pipe[i] <= metadata_pipe[i-1];
                end
            end
        end
    end

    assign out_valid = valid_pipe[LATENCY-1];
    assign out_payload = payload_pipe[LATENCY-1];
    assign out_metadata = metadata_pipe[LATENCY-1];

endmodule
