`timescale 1ns/1ps
module mlkem_prf(
 input wire clk,input wire rst_n,input wire start,output wire ready,
 input wire[255:0]seed,input wire[7:0]nonce,input wire[1:0]eta,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,
 output wire[3:0]out_keep,output wire out_last,output reg busy,
 output reg done,output reg error);
 localparam IDLE=3'd0,CMD=3'd1,FEED=3'd2,OUTPUT=3'd3;
 reg[2:0]state;reg[255:0]seed_reg;reg[7:0]nonce_reg;reg[1:0]eta_reg;reg[3:0]word_index;
 wire hc_ready,hi_ready,hov,hbusy,hdone,herror;wire[31:0]hod;wire[3:0]hok;wire hol;
 wire[31:0]feed_data=(word_index<8)?seed_reg[32*word_index +:32]:{24'h0,nonce_reg};
 wire[3:0]feed_keep=(word_index<8)?4'b1111:4'b0001;wire feed_last=(word_index==8);
 assign ready=(state==IDLE);assign out_valid=(state==OUTPUT)&&hov;assign out_data=hod;assign out_keep=hok;assign out_last=hol;
 keccak_hash_stream u_hash(.clk(clk),.rst_n(rst_n),.cmd_valid(state==CMD),.cmd_ready(hc_ready),.mode(2'd3),.msg_len_bytes(33),.out_len_bytes((eta_reg==2)?128:192),.in_valid(state==FEED),.in_ready(hi_ready),.in_data(feed_data),.in_keep(feed_keep),.in_last(feed_last),.out_valid(hov),.out_ready((state==OUTPUT)&&out_ready),.out_data(hod),.out_keep(hok),.out_last(hol),.busy(hbusy),.done(hdone),.error(herror));
 always @(posedge clk)begin
  if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;seed_reg<=0;nonce_reg<=0;eta_reg<=0;word_index<=0;end
  else begin done<=0;if(herror)error<=1;if(start&&busy)error<=1;
   case(state)
    IDLE:if(start)begin if(eta!=2&&eta!=3)error<=1;else begin seed_reg<=seed;nonce_reg<=nonce;eta_reg<=eta;word_index<=0;busy<=1;error<=0;state<=CMD;end end
    CMD:if(hc_ready)state<=FEED;
    FEED:if(hi_ready)begin if(word_index==8)state<=OUTPUT;else word_index<=word_index+1'b1;end
    OUTPUT:if(hov&&out_ready&&hol)begin busy<=0;done<=1;state<=IDLE;end
    default:begin error<=1;busy<=0;state<=IDLE;end
   endcase
  end
 end
endmodule
