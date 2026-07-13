`timescale 1ns/1ps
module poly_decode12_pipe(
 input wire clk,input wire rst_n,input wire start,input wire[1:0] expected_domain,
 output wire busy,output wire done,output wire error,
 input wire in_valid,output wire in_ready,input wire[31:0] in_data,input wire[3:0] in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[11:0] out_coeff,output wire[7:0] out_index,
 output wire[1:0] out_domain,output wire noncanonical_seen);
 wire child_error;
 byte_decode_poly_pipe #(.D(12)) u(clk,rst_n,start,busy,done,child_error,in_valid,in_ready,in_data,in_keep,in_last,out_valid,out_ready,out_coeff,out_index,noncanonical_seen);
 assign out_domain=expected_domain;
 assign error=child_error | (start && !((expected_domain==2'b01)||(expected_domain==2'b10)));
endmodule
