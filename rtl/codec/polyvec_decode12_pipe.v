`timescale 1ns/1ps
module polyvec_decode12_pipe(input wire clk,input wire rst_n,input wire start,input wire[1:0]expected_domain,output wire busy,output wire done,output wire error,input wire in_valid,output wire in_ready,input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain,output wire[1:0]poly_index,output wire noncanonical_seen);
 wire x1,x2,x3;wire[31:0]x4;wire[3:0]x5;
 polyvec_codec_pipe #(.D(12),.ENCODE(0),.COMPRESS(0))u(clk,rst_n,start,expected_domain,busy,done,error,1'b0,x1,12'd0,in_valid,in_ready,in_data,in_keep,in_last,x2,1'b0,x4,x5,x3,out_valid,out_ready,out_coeff,out_index,out_domain,poly_index,noncanonical_seen);
endmodule
