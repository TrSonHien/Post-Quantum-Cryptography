`timescale 1ns / 1ps
/*
 * Module: fixed_latency_delay
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Shared parameter or control primitive.
 * Standard role: control/pipeline primitive.
 * Input representation: declared payload and control metadata.
 * Output representation: declared payload and control metadata.
 * Interface: valid-only pipeline as declared.
 * Latency / completion: parameterized fixed `LATENCY` cycles.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module fixed_latency_delay
    #(parameter PAYLOAD_WIDTH = 12,
      parameter METADATA_WIDTH = 16,
      parameter LATENCY = 1)
    (input wire clk,
     input wire rst_n,
     input wire in_valid,
     input wire [PAYLOAD_WIDTH - 1 : 0] in_payload,
     input wire [METADATA_WIDTH - 1 : 0] in_metadata,
     output wire out_valid,
     output wire [PAYLOAD_WIDTH - 1 : 0] out_payload,
     output wire [METADATA_WIDTH - 1 : 0] out_metadata,
     input wire zeroize_req,
     output reg zeroize_busy,
     output reg zeroize_done);

    reg [LATENCY - 1 : 0] valid_pipe;
    reg [PAYLOAD_WIDTH - 1 : 0] payload_pipe[0 : LATENCY - 1];
    reg [METADATA_WIDTH - 1 : 0] metadata_pipe[0 : LATENCY - 1];
    integer i;
    integer zero_count;
    reg zero_commit_pending;
    wire accept_zeroize = (zeroize_req === 1'b1);

    initial begin
        if (LATENCY < 1)
            $fatal(1, "fixed_latency_delay requires LATENCY >= 1");
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_pipe <= {LATENCY{1'b0}};
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b0;
            zero_count <= 0;
            zero_commit_pending <= 1'b0;
        end else begin
            zeroize_done <= 1'b0;
            if (accept_zeroize && !zeroize_busy) begin
                zeroize_busy <= 1'b1;
                zero_count <= 0;
                zero_commit_pending <= 1'b0;
            end else if (zeroize_busy) begin
                if (zero_commit_pending) begin
                    valid_pipe <= {LATENCY{1'b0}};
                    zeroize_busy <= 1'b0;
                    zeroize_done <= 1'b1;
                    zero_commit_pending <= 1'b0;
                end else begin
                    valid_pipe[0] <= 1'b1;
                    payload_pipe[0] <= {PAYLOAD_WIDTH{1'b0}};
                    metadata_pipe[0] <= {METADATA_WIDTH{1'b0}};
                    for (i = 1; i < LATENCY; i = i + 1) begin
                        valid_pipe[i] <= 1'b1;
                        payload_pipe[i] <= payload_pipe[i - 1];
                        metadata_pipe[i] <= metadata_pipe[i - 1];
                    end
                    if (zero_count == LATENCY - 1)
                        zero_commit_pending <= 1'b1;
                    else
                        zero_count <= zero_count + 1;
                end
            end else begin
                valid_pipe[0] <= in_valid;
                if (in_valid) begin
                    payload_pipe[0] <= in_payload;
                    metadata_pipe[0] <= in_metadata;
                end
                for (i = 1; i < LATENCY; i = i + 1) begin
                    valid_pipe[i] <= valid_pipe[i - 1];
                    if (valid_pipe[i - 1]) begin
                        payload_pipe[i] <= payload_pipe[i - 1];
                        metadata_pipe[i] <= metadata_pipe[i - 1];
                    end
                end
            end
        end
    end

    assign out_valid = !zeroize_busy && valid_pipe[LATENCY - 1];
    assign out_payload = payload_pipe[LATENCY - 1];
    assign out_metadata = metadata_pipe[LATENCY - 1];
endmodule
