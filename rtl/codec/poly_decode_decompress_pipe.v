`timescale 1ns/1ps
// Common ByteDecode_D followed by exact power-of-two decompression.
module poly_decode_decompress_pipe #(parameter integer D=10)(
 input wire clk,input wire rst_n,input wire start,output wire busy,output wire done,output wire error,
 input wire in_valid,output wire in_ready,input wire[31:0] in_data,input wire[3:0] in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[11:0] out_coeff,output wire[7:0] out_index,output wire[1:0] out_domain,
 input wire zeroize_req,output wire zeroize_busy,output wire zeroize_done);
 wire[11:0]raw;wire nc;
 byte_decode_poly_pipe #(.D(D))u(clk,rst_n,start,busy,done,error,in_valid,in_ready,in_data,in_keep,in_last,out_valid,out_ready,raw,out_index,nc,zeroize_req,zeroize_busy,zeroize_done);
 assign out_coeff=(raw*3329+(1<<(D-1)))>>D;
 assign out_domain=2'b01;
endmodule
