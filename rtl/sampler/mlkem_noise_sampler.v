`timescale 1ns/1ps
module mlkem_noise_sampler(
 input wire clk,input wire rst_n,input wire start,input wire[255:0]seed,input wire[7:0]nonce,input wire[1:0]eta,
 output reg busy,output reg done,output reg error,
 output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain);
 reg child_start;wire pr,po,pbusy,pdone,perr;wire[31:0]pd;wire[3:0]pk;wire pl;wire cbusy,cdone,cerr,ci;
 mlkem_prf p(clk,rst_n,child_start,pr,seed,nonce,eta,po,ci,pd,pk,pl,pbusy,pdone,perr);
 sample_poly_cbd_pipe c(clk,rst_n,child_start,eta,cbusy,cdone,cerr,po,ci,pd,pk,pl,out_valid,out_ready,out_coeff,out_index,out_domain);
 always@(posedge clk)begin child_start<=0;done<=0;if(!rst_n)begin busy<=0;error<=0;end else if(start)begin if(busy)error<=1;else if(eta!=2&&eta!=3)error<=1;else begin busy<=1;error<=0;child_start<=1;end end else if(busy)begin if(perr||cerr)begin error<=1;busy<=0;end if(cdone)begin busy<=0;done<=1;end end end
endmodule
