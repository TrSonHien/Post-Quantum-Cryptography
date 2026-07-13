`timescale 1ns/1ps
module poly_encode12_pipe(
 input wire clk,input wire rst_n,input wire start,input wire[1:0] input_domain,
 output wire busy,output wire done,output wire error,
 input wire in_valid,output wire in_ready,input wire[11:0] in_coeff,
 output wire out_valid,input wire out_ready,output wire[31:0] out_data,output wire[3:0] out_keep,output wire out_last);
 wire child_error;
 byte_encode_poly_pipe #(.D(12)) u(clk,rst_n,start,busy,done,child_error,in_valid,in_ready,in_coeff,out_valid,out_ready,out_data,out_keep,out_last);
 assign error=child_error | (start && !((input_domain==2'b01)||(input_domain==2'b10)));
endmodule
