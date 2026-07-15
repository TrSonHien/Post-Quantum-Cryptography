`timescale 1ns/1ps
module mlkem_dk_parse(
 input wire clk,input wire rst_n,input wire load_start,input wire in_valid,output wire in_ready,input wire[7:0]in_data,input wire in_last,
 output reg complete,output reg error,
 input wire read_req,input wire[11:0]read_addr,output reg read_valid,output reg[7:0]read_data,output reg[1:0]read_kind,output reg[10:0]read_offset,
 input wire zeroize,output reg zeroize_busy,output reg zeroize_done);
 reg[7:0]dk[0:2399];reg[11:0]count,scrub_addr;reg loading;
 assign in_ready=loading&&!zeroize_busy;
 always@(posedge clk)begin read_valid<=0;zeroize_done<=0;
  if(!rst_n)begin count<=0;scrub_addr<=0;loading<=0;complete<=0;error<=0;read_valid<=0;read_data<=0;read_kind<=0;read_offset<=0;zeroize_busy<=0;end
  else if(zeroize&&!zeroize_busy)begin loading<=0;complete<=0;error<=0;scrub_addr<=0;zeroize_busy<=1;end
  else if(zeroize_busy)begin dk[scrub_addr]<=0;if(scrub_addr==2399)begin scrub_addr<=0;zeroize_busy<=0;zeroize_done<=1;end else scrub_addr<=scrub_addr+1'b1;end
  else begin
   if(load_start)begin if(loading)error<=1;else begin loading<=1;complete<=0;error<=0;count<=0;end end
   if(in_valid&&in_ready)begin if(in_last!=(count==2399))begin loading<=0;error<=1;end else begin dk[count]<=in_data;if(count==2399)begin loading<=0;complete<=1;end else count<=count+1'b1;end end
   if(in_valid&&!in_ready&&!load_start)error<=1;
   if(read_req)begin read_valid<=1;if(!complete||read_addr>=2400)begin read_data<=0;read_kind<=0;read_offset<=0;error<=1;end
    else begin read_data<=dk[read_addr];if(read_addr<1152)begin read_kind<=0;read_offset<=read_addr;end else if(read_addr<2336)begin read_kind<=1;read_offset<=read_addr-1152;end else if(read_addr<2368)begin read_kind<=2;read_offset<=read_addr-2336;end else begin read_kind<=3;read_offset<=read_addr-2368;end end end
  end
 end
endmodule
