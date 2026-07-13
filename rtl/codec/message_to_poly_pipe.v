`timescale 1ns/1ps
module message_to_poly_pipe(
 input wire clk,input wire rst_n,input wire start,output wire busy,output wire done,output wire error,
 input wire in_valid,output wire in_ready,input wire[31:0] in_data,input wire[3:0] in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[11:0] out_coeff,output wire[7:0] out_index,output wire[1:0] out_domain);
 poly_decode_decompress_pipe #(.D(1))u(clk,rst_n,start,busy,done,error,in_valid,in_ready,in_data,in_keep,in_last,out_valid,out_ready,out_coeff,out_index,out_domain);
endmodule
