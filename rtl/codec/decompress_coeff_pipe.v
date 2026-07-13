`timescale 1ns/1ps

// Exact FIPS 203 Decompress_D for D=1,4,10. Latency 2, II=1.
module decompress_coeff_pipe #(
    parameter integer D = 10
)(
    input wire clk, input wire rst_n, input wire in_valid,
    input wire [11:0] in_value,
    output reg out_valid, output reg [11:0] out_coeff,
    output reg error
);
    reg valid_s1;
    reg [23:0] numer_s1;
    reg range_s1;
    wire [12:0] limit = (13'd1 << D);
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_s1<=1'b0; out_valid<=1'b0; out_coeff<=12'd0;
            numer_s1<=24'd0; range_s1<=1'b0; error<=1'b0;
        end else begin
            valid_s1 <= in_valid;
            out_valid <= valid_s1;
            if (in_valid) begin
                numer_s1 <= in_value * 13'd3329 + (13'd1 << (D-1));
                range_s1 <= (in_value >= limit);
                if (in_value >= limit || !((D==1)||(D==4)||(D==10))) error<=1'b1;
            end
            if (valid_s1) begin
                out_coeff <= numer_s1 >> D;
                if (range_s1) error<=1'b1;
            end
        end
    end
endmodule
