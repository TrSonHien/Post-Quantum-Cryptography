`timescale 1ns/1ps

// FIPS 203 Algorithm 4. out_bits[j] is bit j of the accepted byte.
module bytes_to_bits_pipe(
    input wire clk, input wire rst_n,
    input wire in_valid, output wire in_ready, input wire [7:0] in_byte,
    output reg out_valid, input wire out_ready, output reg [7:0] out_bits
);
    assign in_ready = !out_valid || out_ready;
    always @(posedge clk) begin
        if (!rst_n) begin out_valid <= 1'b0; out_bits <= 8'd0; end
        else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) out_bits <= in_byte;
        end
    end
endmodule
