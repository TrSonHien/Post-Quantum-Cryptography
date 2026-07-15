`timescale 1ns/1ps
// Public FIPS 203 Algorithm 21: length/hash checks then internal decapsulation.
module mlkem_decaps(
 input wire clk,input wire rst_n,input wire cmd_valid,output wire cmd_ready,
 input wire in_valid,output wire in_ready,input wire in_kind,input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,output wire[3:0]out_keep,output wire out_last,
 output reg busy,output reg done,output reg error,
 input wire zeroize_req,output wire zeroize_busy,output reg zeroize_done);
 localparam IDLE=0,LOAD=1,CWAIT=2,CZ=3,CZW=4,I_CMD=5,I_FEED=6,I_WAIT=7,SCRUB=8,SCRUB_WAIT=9;reg[3:0]state;
 reg[7:0]dk[0:2399],c[0:1087];reg[9:0]word_count;reg[11:0]scrub_addr;reg check_pass,explicit_scrub;reg[1:0]child_zeroize_req,child_zeroized;integer lane,reset_i;
 wire cb,cr,cd,ce,cv,czb,czd;wire[5:0]cc;wire icr,iir,iov,iol,ib,id,ie,izb,izd;wire[31:0]iod,icy;wire[3:0]iok;wire[10:0]cmp;wire[5:0]sel;
 assign zeroize_busy=explicit_scrub&&((state==SCRUB)||(state==SCRUB_WAIT));assign cmd_ready=state==IDLE&&!zeroize_req;assign in_ready=state==LOAD&&cr&&!zeroize_req;assign out_valid=state==I_WAIT&&iov&&!zeroize_req;assign out_data=iod;assign out_keep=iok;assign out_last=iol;
 mlkem_decaps_input_check chk(clk,rst_n,cmd_valid&&cmd_ready,cb,in_valid&&state==LOAD,cr,in_kind,in_data,in_keep,in_last,cd,ce,cv,cc,(state==CZ)||child_zeroize_req[0],czb,czd);
 wire[31:0]ifeed=word_count<600?{dk[word_count*4+3],dk[word_count*4+2],dk[word_count*4+1],dk[word_count*4]}:{c[(word_count-600)*4+3],c[(word_count-600)*4+2],c[(word_count-600)*4+1],c[(word_count-600)*4]};
 mlkem_decaps_internal core(clk,rst_n,state==I_CMD,icr,state==I_FEED,iir,ifeed,4'hf,word_count==871,iov,state==I_WAIT&&out_ready,iod,iok,iol,ib,id,ie,icy,cmp,sel,child_zeroize_req[1],izb,izd);
 always@(posedge clk)begin done<=0;zeroize_done<=0;if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;word_count<=0;scrub_addr<=0;check_pass<=0;explicit_scrub<=0;child_zeroize_req<=0;child_zeroized<=0;zeroize_done<=0;end else begin
  if(czd&&state!=CZW)begin child_zeroized[0]<=1;child_zeroize_req[0]<=0;end if(izd)begin child_zeroized[1]<=1;child_zeroize_req[1]<=0;end
  if((zeroize_req===1'b1)&&!zeroize_busy)begin state<=SCRUB;busy<=1;done<=0;error<=0;word_count<=0;scrub_addr<=0;check_pass<=0;explicit_scrub<=1;child_zeroize_req<=2'b11;child_zeroized<=0;end else case(state)
   IDLE:if(cmd_valid)begin busy<=1;error<=0;word_count<=0;explicit_scrub<=0;state<=LOAD;end
   LOAD:if(in_valid&&in_ready)begin if(!in_kind)for(lane=0;lane<4;lane=lane+1)dk[word_count*4+lane]<=in_data[lane*8+:8];else for(lane=0;lane<4;lane=lane+1)c[(word_count-600)*4+lane]<=in_data[lane*8+:8];if(word_count==871)state<=CWAIT;else word_count<=word_count+1;end
   CWAIT:if(cd)begin check_pass<=cv&&!ce;state<=CZ;end CZ:state<=CZW;
   CZW:if(czd)begin if(check_pass)state<=I_CMD;else begin error<=1;scrub_addr<=0;child_zeroize_req<=2'b11;child_zeroized<=0;state<=SCRUB;end end
   I_CMD:if(icr)begin word_count<=0;state<=I_FEED;end I_FEED:if(iir)begin if(word_count==871)state<=I_WAIT;else word_count<=word_count+1;end
   I_WAIT:if(ie)begin error<=1;scrub_addr<=0;child_zeroize_req<=2'b11;child_zeroized<=0;state<=SCRUB;end else if(id)begin scrub_addr<=0;child_zeroize_req<=2'b11;child_zeroized<=0;state<=SCRUB;end
   SCRUB:begin dk[scrub_addr]<=0;if(scrub_addr<1088)c[scrub_addr]<=0;if(scrub_addr==2399)begin scrub_addr<=0;state<=SCRUB_WAIT;end else scrub_addr<=scrub_addr+1;end
   SCRUB_WAIT:if(&(child_zeroized|{izd,czd}))begin busy<=0;if(explicit_scrub)zeroize_done<=1;else done<=1;explicit_scrub<=0;child_zeroize_req<=0;child_zeroized<=0;word_count<=0;check_pass<=0;state<=IDLE;end
  endcase end end
endmodule
