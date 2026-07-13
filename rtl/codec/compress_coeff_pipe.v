`timescale 1ns/1ps

// Exact FIPS 203 Compress_D for D=1,4,10. Latency 2, II=1.
// q0=floor(n*floor(2^24/3329)/2^24), followed by one exact correction.
module compress_coeff_pipe #(
    parameter integer D = 10
)(
    input wire clk, input wire rst_n, input wire in_valid,
    input wire [11:0] in_coeff,
    output reg out_valid, output reg [11:0] out_value,
    output reg error
);
    localparam [12:0] Q = 13'd3329;
    localparam [12:0] HALF_Q = 13'd1664;
    localparam [12:0] RECIP = 13'd5039;
    reg valid_s1;
    reg [22:0] numer_s1;
    reg [35:0] product_s1;
    reg range_s1;
    reg [22:0] q_est;
    reg [35:0] rem;
    reg [22:0] quotient;
    always @* begin
        q_est = product_s1 >> 24;
        rem = numer_s1 - q_est * Q;
        quotient = q_est + ((rem >= Q) ? 23'd1 : 23'd0);
    end
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_s1 <= 1'b0; out_valid <= 1'b0; error <= 1'b0;
            numer_s1 <= 23'd0; product_s1 <= 36'd0; range_s1 <= 1'b0;
            out_value <= 12'd0;
        end else begin
            valid_s1 <= in_valid;
            out_valid <= valid_s1;
            if (in_valid) begin
                numer_s1 <= ({11'd0,in_coeff} << D) + HALF_Q;
                product_s1 <= (({11'd0,in_coeff} << D) + HALF_Q) * RECIP;
                range_s1 <= in_coeff >= Q;
                if (in_coeff >= Q || !((D==1)||(D==4)||(D==10))) error <= 1'b1;
            end
            if (valid_s1) begin
                if (D == 1) out_value <= {11'd0, quotient[0]};
                else if (D == 4) out_value <= {8'd0, quotient[3:0]};
                else out_value <= {2'd0, quotient[9:0]};
                if (range_s1) error <= 1'b1;
            end
        end
    end
endmodule
