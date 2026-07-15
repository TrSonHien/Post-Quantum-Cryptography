`timescale 1ns/1ps
module poly_ntt_pipe(
 input wire clk,input wire rst_n,input wire load_begin,input wire[1:0]load_domain,
 input wire load_we,input wire[7:0]load_idx,input wire[11:0]load_coeff,output wire load_ready,
 input wire start,output wire busy,output wire done,output wire error,
 input wire result_req,input wire[7:0]result_idx,output wire result_valid,output wire[11:0]result_coeff,
 output wire[1:0]result_domain,output wire result_complete,input wire result_release,
 input wire zeroize_req,output wire zeroize_busy,output wire zeroize_done);
 poly_transform_pipe #(.IS_INVERSE(0)) impl(.*);
endmodule
