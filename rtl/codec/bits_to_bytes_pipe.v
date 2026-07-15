`timescale 1ns/1ps

// FIPS 203 Algorithm 3, one complete little-endian eight-bit group per beat.
module bits_to_bytes_pipe(
    input wire clk, input wire rst_n,
    input wire in_valid, output wire in_ready, input wire [7:0] in_bits,
    output reg out_valid, input wire out_ready, output reg [7:0] out_byte,
    input wire zeroize_req, output reg zeroize_busy, output reg zeroize_done
);
    wire zeroize_active = zeroize_busy || (zeroize_req === 1'b1);
    assign in_ready = !zeroize_active && (!out_valid || out_ready);
    always @(posedge clk) begin
        zeroize_done <= 1'b0;
        if (!rst_n) begin out_valid <= 1'b0; out_byte <= 8'd0; zeroize_busy<=0; zeroize_done<=0; end
        else if ((zeroize_req === 1'b1) && !zeroize_busy) begin out_valid<=0; out_byte<=0; zeroize_busy<=1; end
        else if (zeroize_busy) begin out_valid<=0; out_byte<=0; zeroize_busy<=0; zeroize_done<=1; end
        else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) out_byte <= in_bits;
        end
    end
endmodule
