`timescale 1ns/1ps
module sample_ntt_parser(
 input wire clk,input wire rst_n,input wire start,output reg busy,output reg done,output reg error,
 input wire in_valid,output wire in_ready,input wire[23:0]in_data,
 output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain,
 output reg[31:0]groups_examined,output reg[31:0]candidates_accepted,output reg[31:0]candidates_rejected,
 input wire zeroize_req,output reg zeroize_busy,output reg zeroize_done);
 reg[11:0]q0,q1;reg[1:0]qcount;reg[8:0]count;wire[11:0]d1={in_data[11:8],in_data[7:0]};wire[11:0]d2={in_data[23:16],in_data[15:12]};wire a1=d1<3329;wire a2=d2<3329;
 assign in_ready=!zeroize_busy&&!(zeroize_req===1'b1)&&busy&&(qcount==0);assign out_valid=!zeroize_busy&&busy&&(qcount!=0);assign out_coeff=zeroize_busy?0:q0;assign out_index=zeroize_busy?0:count[7:0];assign out_domain=2'b10;
 always@(posedge clk)begin done<=0;zeroize_done<=0;if(!rst_n)begin busy<=0;error<=0;q0<=0;q1<=0;qcount<=0;count<=0;groups_examined<=0;candidates_accepted<=0;candidates_rejected<=0;zeroize_busy<=0;zeroize_done<=0;end
  else if((zeroize_req===1'b1)&&!zeroize_busy)begin busy<=0;error<=0;q0<=0;q1<=0;qcount<=0;count<=0;groups_examined<=0;candidates_accepted<=0;candidates_rejected<=0;zeroize_busy<=1;end
  else if(zeroize_busy)begin busy<=0;error<=0;q0<=0;q1<=0;qcount<=0;count<=0;groups_examined<=0;candidates_accepted<=0;candidates_rejected<=0;zeroize_busy<=0;zeroize_done<=1;end
  else if(start)begin if(busy)error<=1;else begin busy<=1;error<=0;qcount<=0;count<=0;groups_examined<=0;candidates_accepted<=0;candidates_rejected<=0;end end
  else if(busy)begin
   if(out_valid&&out_ready)begin if(count==255)begin busy<=0;done<=1;qcount<=0;end else begin count<=count+1;if(qcount==2)begin q0<=q1;qcount<=1;end else qcount<=0;end end
   if(in_valid&&in_ready)begin groups_examined<=groups_examined+1;candidates_rejected<=candidates_rejected+(!a1)+(!a2);
    if(a1)begin q0<=d1;if(a2&&count<255)begin q1<=d2;qcount<=2;candidates_accepted<=candidates_accepted+2;end else begin qcount<=1;candidates_accepted<=candidates_accepted+1;if(a2&&count==255)candidates_rejected<=candidates_rejected+1;end end
    else if(a2)begin q0<=d2;qcount<=1;candidates_accepted<=candidates_accepted+1;end
   end
  end end
endmodule
