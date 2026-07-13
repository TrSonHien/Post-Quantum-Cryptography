`timescale 1ns/1ps

// FIPS 203 ByteEncode_D. A bounded 64-bit LSB-first reservoir packs 256 values.
module byte_encode_poly_pipe #(
    parameter integer D = 12
)(
    input wire clk, input wire rst_n,
    input wire start, output reg busy, output reg done, output reg error,
    input wire in_valid, output wire in_ready, input wire [11:0] in_value,
    output reg out_valid, input wire out_ready, output reg [31:0] out_data,
    output reg [3:0] out_keep, output reg out_last
);
    localparam integer WORDS = 8*D;
    reg [63:0] reservoir;
    reg [6:0] bit_count;
    reg [8:0] accepted;
    reg [7:0] emitted;
    reg [63:0] rtmp;
    reg [6:0] ctmp;
    reg ovtmp;
    reg [31:0] odtmp;
    reg oltmp;
    wire value_range_ok = (D==12) ? (in_value < 12'd3329) :
                          (D==10) ? (in_value < 12'd1024) :
                          (D==4)  ? (in_value < 12'd16) :
                          (D==1)  ? (in_value < 12'd2) : 1'b0;
    assign in_ready = busy && accepted < 256 && bit_count <= (64-D) &&
                      (!out_valid || out_ready);
    always @(posedge clk) begin
        done <= 1'b0;
        if (!rst_n) begin
            busy<=1'b0; done<=1'b0; error<=1'b0; reservoir<=64'd0;
            bit_count<=0; accepted<=0; emitted<=0; out_valid<=1'b0;
            out_data<=0; out_keep<=0; out_last<=1'b0;
        end else if (start) begin
            if (busy) error<=1'b1;
            else if (!((D==1)||(D==4)||(D==10)||(D==12))) error<=1'b1;
            else begin
                busy<=1'b1; error<=1'b0; reservoir<=0; bit_count<=0;
                accepted<=0; emitted<=0; out_valid<=1'b0; out_keep<=4'b1111;
                out_last<=1'b0;
            end
        end else if (busy) begin
            rtmp = reservoir; ctmp = bit_count; ovtmp = out_valid;
            odtmp = out_data; oltmp = out_last;
            if (out_valid && out_ready) begin
                if (out_last) begin busy<=1'b0; done<=1'b1; end
                ovtmp = 1'b0;
            end
            if (in_valid && in_ready) begin
                if (!value_range_ok) begin error<=1'b1; busy<=1'b0; ovtmp=1'b0; end
                else begin
                    rtmp = rtmp | ({52'd0,in_value} << ctmp);
                    ctmp = ctmp + D;
                    accepted <= accepted + 1'b1;
                end
            end
            if (!ovtmp && ctmp >= 32) begin
                odtmp = rtmp[31:0]; rtmp = rtmp >> 32; ctmp = ctmp-32;
                ovtmp = 1'b1; oltmp = (emitted == WORDS-1);
                emitted <= emitted + 1'b1;
            end
            reservoir<=rtmp; bit_count<=ctmp; out_valid<=ovtmp;
            out_data<=odtmp; out_keep<=4'b1111; out_last<=oltmp;
        end
    end
endmodule
