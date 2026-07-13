`timescale 1ns/1ps
// Registered exact-length concatenation/split adapter for encoded codec streams.
module kpke_format_pipe #(parameter integer WORDS=296,parameter integer SPLIT_WORDS=288)(
 input wire clk,input wire rst_n,input wire start,output reg busy,output reg done,output reg error,
 input wire in_valid,output wire in_ready,input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,
 output reg out_valid,input wire out_ready,output reg[31:0]out_data,output reg[3:0]out_keep,output reg out_last,
 output reg segment);
 reg[9:0]count;
 assign in_ready=busy&&(!out_valid||out_ready);
 always@(posedge clk)begin done<=0;if(!rst_n)begin busy<=0;error<=0;out_valid<=0;count<=0;out_data<=0;out_keep<=0;out_last<=0;segment<=0;end
  else if(start)begin if(busy)error<=1;else begin busy<=1;error<=0;out_valid<=0;count<=0;segment<=0;end end
  else if(busy)begin
   if(out_valid&&out_ready)begin if(out_last)begin busy<=0;done<=1;end out_valid<=0;end
   if(in_valid&&in_ready)begin
    if(in_keep!=4'hf||in_last!=(count==WORDS-1))begin error<=1;busy<=0;out_valid<=0;end
    else begin out_valid<=1;out_data<=in_data;out_keep<=4'hf;out_last<=(count==WORDS-1);segment<=(count>=SPLIT_WORDS);count<=count+1;end
   end
  end end
endmodule
