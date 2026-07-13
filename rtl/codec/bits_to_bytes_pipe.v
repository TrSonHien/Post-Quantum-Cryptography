`timescale 1ns/1ps

// FIPS 203 Algorithm 3, one complete little-endian eight-bit group per beat.
module bits_to_bytes_pipe(
    input wire clk, input wire rst_n,
    input wire in_valid, output wire in_ready, input wire [7:0] in_bits,
    output reg out_valid, input wire out_ready, output reg [7:0] out_byte
);
    assign in_ready = !out_valid || out_ready;
    always @(posedge clk) begin
        if (!rst_n) begin out_valid <= 1'b0; out_byte <= 8'd0; end
        else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) out_byte <= in_bits;
        end
    end
endmodule
