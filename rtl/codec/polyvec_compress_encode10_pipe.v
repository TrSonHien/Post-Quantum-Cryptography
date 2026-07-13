`timescale 1ns/1ps
module polyvec_compress_encode10_pipe(input wire clk,input wire rst_n,input wire start,input wire[1:0]input_domain,output wire busy,output wire done,output wire error,input wire in_valid,output wire in_ready,input wire[11:0]in_coeff,output wire out_valid,input wire out_ready,output wire[31:0]out_data,output wire[3:0]out_keep,output wire out_last,output wire[1:0]poly_index);
 wire x1,x2,x3,x4;wire[11:0]x5;wire[7:0]x6;wire[1:0]x7;wire nc;
 polyvec_codec_pipe #(.D(10),.ENCODE(1),.COMPRESS(1))u(clk,rst_n,start,input_domain,busy,done,error,in_valid,in_ready,in_coeff,1'b0,x1,32'd0,4'd0,1'b0,out_valid,out_ready,out_data,out_keep,out_last,x2,1'b0,x5,x6,x7,poly_index,nc);
endmodule
