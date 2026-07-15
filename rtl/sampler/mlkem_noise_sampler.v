`timescale 1ns/1ps
module mlkem_noise_sampler(
 input wire clk,input wire rst_n,input wire start,input wire[255:0]seed,input wire[7:0]nonce,input wire[1:0]eta,
 output reg busy,output reg done,output reg error,
 output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain,
 input wire zeroize_req,output reg zeroize_busy,output reg zeroize_done);
 reg child_start,child_zeroize_req,prf_zeroized,cbd_zeroized;wire pr,po,pbusy,pdone,perr;wire[31:0]pd;wire[3:0]pk;wire pl;wire cbusy,cdone,cerr,ci;
 wire pzbusy,pzdone,czbusy,czdone;
 mlkem_prf p(clk,rst_n,child_start,pr,seed,nonce,eta,po,ci,pd,pk,pl,pbusy,pdone,perr,child_zeroize_req,pzbusy,pzdone);
 sample_poly_cbd_pipe c(clk,rst_n,child_start,eta,cbusy,cdone,cerr,po,ci,pd,pk,pl,out_valid,out_ready,out_coeff,out_index,out_domain,child_zeroize_req,czbusy,czdone);
 always@(posedge clk)begin child_start<=0;done<=0;zeroize_done<=0;if(!rst_n)begin busy<=0;error<=0;child_zeroize_req<=0;prf_zeroized<=0;cbd_zeroized<=0;zeroize_busy<=0;zeroize_done<=0;end
  else if((zeroize_req===1'b1)&&!zeroize_busy)begin busy<=0;error<=0;child_start<=0;child_zeroize_req<=1;prf_zeroized<=0;cbd_zeroized<=0;zeroize_busy<=1;end
  else if(zeroize_busy)begin busy<=0;error<=0;if(pzdone)prf_zeroized<=1;if(czdone)cbd_zeroized<=1;if((prf_zeroized||pzdone)&&(cbd_zeroized||czdone))begin child_zeroize_req<=0;prf_zeroized<=0;cbd_zeroized<=0;zeroize_busy<=0;zeroize_done<=1;end end
  else if(start)begin if(busy)error<=1;else if(eta!=2&&eta!=3)error<=1;else begin busy<=1;error<=0;child_start<=1;end end else if(busy)begin if(perr||cerr)begin error<=1;busy<=0;end if(cdone)begin busy<=0;done<=1;end end end
endmodule
