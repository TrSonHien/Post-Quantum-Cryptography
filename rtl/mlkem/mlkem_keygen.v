`timescale 1ns/1ps
// Public FIPS 203 Algorithm 19. Entropy is supplied by an external RBG.
module mlkem_keygen(
 input wire clk,input wire rst_n,input wire cmd_valid,output wire cmd_ready,
 output wire rng_req_valid,input wire rng_req_ready,output wire[15:0]rng_req_len_bytes,
 input wire rng_data_valid,output wire rng_data_ready,input wire[31:0]rng_data,input wire[3:0]rng_keep,input wire rng_last,input wire rng_fail,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,output wire[3:0]out_keep,output wire out_last,output wire out_kind,
 output reg busy,output reg done,output reg error,
 input wire zeroize_req,output wire zeroize_busy,output reg zeroize_done);
 localparam IDLE=0,RREQ=1,RDATA=2,I_CMD=3,I_FEED=4,I_WAIT=5,SCRUB=6,SCRUB_WAIT=7;reg[2:0]state;reg[7:0]entropy[0:63];reg[4:0]word_count;reg[6:0]scrub_addr;reg explicit_scrub,child_zeroize_req,child_zeroized;
 wire ic_ready,ii_ready,io_valid,io_last,io_kind,ib,ido,ier,izb,izd;wire[31:0]io_data,icycles;wire[3:0]io_keep;integer lane,reset_i;
 assign zeroize_busy=explicit_scrub&&((state==SCRUB)||(state==SCRUB_WAIT));assign cmd_ready=state==IDLE&&!zeroize_req;assign rng_req_valid=state==RREQ&&!zeroize_req;assign rng_req_len_bytes=64;assign rng_data_ready=state==RDATA&&!zeroize_req;
 assign out_valid=state==I_WAIT&&io_valid;assign out_data=io_data;assign out_keep=io_keep;assign out_last=io_last;assign out_kind=io_kind;
 mlkem_keygen_internal core(clk,rst_n,state==I_CMD,ic_ready,state==I_FEED,ii_ready,{entropy[word_count*4+3],entropy[word_count*4+2],entropy[word_count*4+1],entropy[word_count*4]},4'hf,word_count==15,io_valid,(state==I_WAIT)&&out_ready,io_data,io_keep,io_last,io_kind,ib,ido,ier,icycles,child_zeroize_req,izb,izd);
 always@(posedge clk)begin done<=0;zeroize_done<=0;if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;word_count<=0;scrub_addr<=0;explicit_scrub<=0;child_zeroize_req<=0;child_zeroized<=0;zeroize_done<=0;end else begin
  if(izd)begin child_zeroized<=1;child_zeroize_req<=0;end
  if((zeroize_req===1'b1)&&!zeroize_busy)begin state<=SCRUB;busy<=1;done<=0;error<=0;word_count<=0;scrub_addr<=0;explicit_scrub<=1;child_zeroize_req<=1;child_zeroized<=0;end else case(state)
   IDLE:if(cmd_valid)begin busy<=1;error<=0;explicit_scrub<=0;state<=RREQ;end
   RREQ:begin if(rng_fail)begin error<=1;scrub_addr<=0;child_zeroize_req<=1;child_zeroized<=0;state<=SCRUB;end else if(rng_req_ready)begin word_count<=0;state<=RDATA;end end
   RDATA:begin if(rng_fail)begin error<=1;scrub_addr<=0;child_zeroize_req<=1;child_zeroized<=0;state<=SCRUB;end else if(rng_data_valid)begin if(rng_keep!=4'hf||rng_last!=(word_count==15))begin error<=1;scrub_addr<=0;child_zeroize_req<=1;child_zeroized<=0;state<=SCRUB;end else begin for(lane=0;lane<4;lane=lane+1)entropy[word_count*4+lane]<=rng_data[lane*8+:8];if(word_count==15)state<=I_CMD;else word_count<=word_count+1;end end end
   I_CMD:if(ic_ready)begin word_count<=0;state<=I_FEED;end
   I_FEED:if(ii_ready)begin if(word_count==15)state<=I_WAIT;else word_count<=word_count+1;end
   I_WAIT:if(ier)begin error<=1;scrub_addr<=0;child_zeroize_req<=1;child_zeroized<=0;state<=SCRUB;end else if(ido)begin scrub_addr<=0;child_zeroize_req<=1;child_zeroized<=0;state<=SCRUB;end
   SCRUB:begin entropy[scrub_addr]<=0;if(scrub_addr==63)begin scrub_addr<=0;state<=SCRUB_WAIT;end else scrub_addr<=scrub_addr+1;end
   SCRUB_WAIT:if(child_zeroized||izd)begin busy<=0;if(explicit_scrub)zeroize_done<=1;else done<=1;explicit_scrub<=0;child_zeroize_req<=0;child_zeroized<=0;word_count<=0;state<=IDLE;end
  endcase
 end end
endmodule
