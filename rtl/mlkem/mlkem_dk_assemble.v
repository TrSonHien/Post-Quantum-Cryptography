`timescale 1ns/1ps
module mlkem_dk_assemble(
 input wire clk,input wire rst_n,input wire load_start,
 input wire in_valid,output wire in_ready,input wire[1:0]in_kind,input wire[7:0]in_data,input wire in_last,
 output reg complete,output reg error,
 input wire output_start,output wire out_valid,input wire out_ready,output wire[7:0]out_data,output wire[11:0]out_addr,output wire out_last,output reg done,
 input wire zeroize,output reg zeroize_busy,output reg zeroize_done);
 localparam DKPKE=0,EK=1,HASH=2,Z=3;
 reg[7:0]dkpke[0:1151],ek[0:1183],h[0:31],z[0:31];
 reg[11:0]load_count,out_count,scrub_count;reg[1:0]expected_kind;reg outputting,loading;
 wire[11:0]kind_len=(in_kind==DKPKE)?1152:(in_kind==EK)?1184:32;
 wire[11:0]kind_base=(in_kind==DKPKE)?0:(in_kind==EK)?1152:(in_kind==HASH)?2336:2368;
 assign in_ready=loading&&!zeroize_busy;
 assign out_valid=outputting;assign out_addr=out_count;assign out_last=outputting&&out_count==2399;
 assign out_data=(out_count<1152)?dkpke[out_count]:(out_count<2336)?ek[out_count-1152]:(out_count<2368)?h[out_count-2336]:z[out_count-2368];
 always@(posedge clk)begin done<=0;zeroize_done<=0;
  if(!rst_n)begin load_count<=0;out_count<=0;scrub_count<=0;expected_kind<=0;outputting<=0;loading<=0;complete<=0;error<=0;zeroize_busy<=0;end
  else if(zeroize&&!zeroize_busy)begin loading<=0;outputting<=0;complete<=0;error<=0;scrub_count<=0;zeroize_busy<=1;end
  else if(zeroize_busy)begin
   if(scrub_count<1152)dkpke[scrub_count]<=0;else if(scrub_count<2336)ek[scrub_count-1152]<=0;else if(scrub_count<2368)h[scrub_count-2336]<=0;else z[scrub_count-2368]<=0;
   if(scrub_count==2399)begin zeroize_busy<=0;zeroize_done<=1;scrub_count<=0;end else scrub_count<=scrub_count+1'b1;
  end else begin
   if(load_start)begin if(loading||outputting)error<=1;else begin loading<=1;complete<=0;error<=0;expected_kind<=0;load_count<=0;end end
   if(in_valid&&in_ready)begin
    if(in_kind!=expected_kind||in_last!=(load_count==kind_len-1))begin loading<=0;error<=1;end
    else begin case(in_kind)DKPKE:dkpke[load_count]<=in_data;EK:ek[load_count]<=in_data;HASH:h[load_count]<=in_data;default:z[load_count]<=in_data;endcase
     if(load_count==kind_len-1)begin load_count<=0;if(expected_kind==Z)begin loading<=0;complete<=1;end else expected_kind<=expected_kind+1'b1;end else load_count<=load_count+1'b1;
    end
   end
   if(in_valid&&!in_ready&&!load_start)error<=1;
   if(output_start)begin if(!complete||outputting)error<=1;else begin outputting<=1;out_count<=0;end end
   if(out_valid&&out_ready)begin if(out_count==2399)begin outputting<=0;done<=1;end else out_count<=out_count+1'b1;end
  end
 end
endmodule
