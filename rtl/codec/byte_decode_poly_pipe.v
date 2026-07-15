`timescale 1ns/1ps

// FIPS 203 ByteDecode_D with informational d12 noncanonical evidence.
module byte_decode_poly_pipe #(
    parameter integer D = 12
)(
    input wire clk, input wire rst_n,
    input wire start, output reg busy, output reg done, output reg error,
    input wire in_valid, output wire in_ready, input wire [31:0] in_data,
    input wire [3:0] in_keep, input wire in_last,
    output reg out_valid, input wire out_ready, output reg [11:0] out_value,
    output reg [7:0] out_index, output reg noncanonical_seen,
    input wire zeroize_req, output reg zeroize_busy, output reg zeroize_done
);
    localparam integer WORDS = 8*D;
    reg [63:0] reservoir;
    reg [6:0] bit_count;
    reg [7:0] words_in;
    reg [8:0] values_out;
    reg [63:0] rtmp;
    reg [6:0] ctmp;
    reg ovtmp;
    reg [11:0] rawtmp;
    wire expected_last = (words_in == WORDS-1);
    assign in_ready = !zeroize_busy && !(zeroize_req === 1'b1) && busy && words_in < WORDS && bit_count <= 32 &&
                      (!out_valid || out_ready);
    always @(posedge clk) begin
        done<=1'b0; zeroize_done<=1'b0;
        if (!rst_n) begin
            busy<=0; done<=0; error<=0; reservoir<=0; bit_count<=0;
            words_in<=0; values_out<=0; out_valid<=0; out_value<=0;
            out_index<=0; noncanonical_seen<=0; zeroize_busy<=0; zeroize_done<=0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            busy<=0; error<=0; reservoir<=0; bit_count<=0; words_in<=0; values_out<=0;
            out_valid<=0; out_value<=0; out_index<=0; noncanonical_seen<=0;
            rtmp<=0; ctmp<=0; ovtmp<=0; rawtmp<=0; zeroize_busy<=1;
        end else if (zeroize_busy) begin
            busy<=0; error<=0; reservoir<=0; bit_count<=0; words_in<=0; values_out<=0;
            out_valid<=0; out_value<=0; out_index<=0; noncanonical_seen<=0;
            rtmp<=0; ctmp<=0; ovtmp<=0; rawtmp<=0; zeroize_busy<=0; zeroize_done<=1;
        end else if (start) begin
            if (busy) error<=1'b1;
            else if (!((D==1)||(D==4)||(D==10)||(D==12))) error<=1'b1;
            else begin busy<=1; error<=0; reservoir<=0; bit_count<=0;
                words_in<=0; values_out<=0; out_valid<=0; noncanonical_seen<=0; end
        end else if (busy) begin
            rtmp=reservoir; ctmp=bit_count; ovtmp=out_valid;
            if (out_valid && out_ready) begin
                if (values_out == 256) begin busy<=0; done<=1; end
                ovtmp=0;
            end
            if (in_valid && in_ready) begin
                if (in_keep != 4'b1111 || in_last != expected_last) begin
                    error<=1; busy<=0; ovtmp=0;
                end else begin
                    rtmp = rtmp | ({32'd0,in_data} << ctmp);
                    ctmp = ctmp + 32; words_in <= words_in + 1'b1;
                end
            end
            if (!ovtmp && ctmp >= D && values_out < 256) begin
                if (D==1) rawtmp={11'd0,rtmp[0]};
                else if (D==4) rawtmp={8'd0,rtmp[3:0]};
                else if (D==10) rawtmp={2'd0,rtmp[9:0]};
                else rawtmp=rtmp[11:0];
                if (D==12 && rawtmp >= 3329) begin
                    out_value <= rawtmp-3329; noncanonical_seen<=1'b1;
                end else out_value<=rawtmp;
                out_index<=values_out[7:0]; values_out<=values_out+1'b1;
                rtmp=rtmp>>D; ctmp=ctmp-D; ovtmp=1;
            end
            reservoir<=rtmp; bit_count<=ctmp; out_valid<=ovtmp;
        end
    end
endmodule
