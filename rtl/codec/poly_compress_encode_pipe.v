`timescale 1ns/1ps
// NORMAL-domain Compress_D followed by the common ByteEncode_D reservoir.
module poly_compress_encode_pipe #(parameter integer D=10)(
 input wire clk,input wire rst_n,input wire start,input wire[1:0] input_domain,
 output wire busy,output wire done,output wire error,
 input wire in_valid,output wire in_ready,input wire[11:0] in_coeff,
 output wire out_valid,input wire out_ready,output wire[31:0] out_data,output wire[3:0] out_keep,output wire out_last,
 input wire zeroize_req,output wire zeroize_busy,output wire zeroize_done);
 function automatic [11:0] exact_compress(input [11:0] x);
  reg[22:0]n,qe;reg[35:0]p,r;begin n=({11'd0,x}<<D)+1664;p=n*5039;qe=p>>24;r=n-qe*3329;if(r>=3329)qe=qe+1;exact_compress=qe&((1<<D)-1);end
 endfunction
 wire child_error;
 byte_encode_poly_pipe #(.D(D))u(clk,rst_n,start,busy,done,child_error,in_valid,in_ready,exact_compress(in_coeff),out_valid,out_ready,out_data,out_keep,out_last,zeroize_req,zeroize_busy,zeroize_done);
 assign error=!zeroize_busy&&!(zeroize_req===1'b1)&&(child_error | (start && input_domain!=2'b01) | (in_valid&&in_ready&&in_coeff>=3329));
endmodule
