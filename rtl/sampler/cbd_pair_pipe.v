`timescale 1ns/1ps
module cbd_pair_pipe(
 input wire clk,input wire rst_n,input wire in_valid,output wire in_ready,input wire[1:0]eta,input wire[11:0]in_bits,
 output reg out_valid,input wire out_ready,output reg[11:0]coeff0,output reg[11:0]coeff1,output reg error,
 input wire zeroize_req,output reg zeroize_busy,output reg zeroize_done);
 function automatic[2:0]pc3(input[2:0]v);begin pc3={2'd0,v[0]}+{2'd0,v[1]}+{2'd0,v[2]};end endfunction
 reg[2:0]x0,y0,x1,y1;
 assign in_ready=!zeroize_busy&&!(zeroize_req===1'b1)&&(!out_valid||out_ready);
 always@*begin
  if(eta==2)begin x0=pc3({1'b0,in_bits[1:0]});y0=pc3({1'b0,in_bits[3:2]});x1=pc3({1'b0,in_bits[5:4]});y1=pc3({1'b0,in_bits[7:6]});end
  else begin x0=pc3(in_bits[2:0]);y0=pc3(in_bits[5:3]);x1=pc3(in_bits[8:6]);y1=pc3(in_bits[11:9]);end end
  always@(posedge clk)begin zeroize_done<=0;if(!rst_n)begin out_valid<=0;coeff0<=0;coeff1<=0;error<=0;zeroize_busy<=0;zeroize_done<=0;end
   else if((zeroize_req===1'b1)&&!zeroize_busy)begin out_valid<=0;coeff0<=0;coeff1<=0;error<=0;zeroize_busy<=1;end
   else if(zeroize_busy)begin out_valid<=0;coeff0<=0;coeff1<=0;error<=0;zeroize_busy<=0;zeroize_done<=1;end
   else if(in_ready)begin out_valid<=in_valid;if(in_valid)begin if(eta!=2&&eta!=3)error<=1;else begin coeff0<=(x0>=y0)?(x0-y0):3329-(y0-x0);coeff1<=(x1>=y1)?(x1-y1):3329-(y1-x1);end end end end
endmodule
