`timescale 1ns/1ps
module polyvec_decode_decompress10_pipe(input wire clk,input wire rst_n,input wire start,output wire busy,output wire done,output wire error,input wire in_valid,output wire in_ready,input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain,output wire[1:0]poly_index);
 wire x1,x2,x3;wire[31:0]x4;wire[3:0]x5;wire nc;
 polyvec_codec_pipe #(.D(10),.ENCODE(0),.COMPRESS(1))u(clk,rst_n,start,2'b01,busy,done,error,1'b0,x1,12'd0,in_valid,in_ready,in_data,in_keep,in_last,x2,1'b0,x4,x5,x3,out_valid,out_ready,out_coeff,out_index,out_domain,poly_index,nc);
endmodule
