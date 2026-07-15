`timescale 1ns/1ps
module mlkem_xof(
 input wire clk,input wire rst_n,input wire init_valid,output wire init_ready,
 input wire[255:0]seed,input wire[7:0]index0,input wire[7:0]index1,
 input wire use_generic_input,input wire[271:0]generic_input,
 input wire squeeze_req_valid,output wire squeeze_req_ready,input wire[31:0]squeeze_len_bytes,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,
 output wire[3:0]out_keep,output wire out_last,output wire context_valid,
 output wire busy,output reg done,output reg error,input wire zeroize_req,
 output reg zeroize_busy,output reg zeroize_done);
 localparam IDLE=3'd0,CTX_INIT=3'd1,FEED=3'd2,FINAL=3'd3,WAIT_ACTIVE=3'd4,ACTIVE=3'd5;
 reg[2:0]state;reg[271:0]input_reg;reg[3:0]word_index;
 wire ci_ready,cf_ready,cv,cap,csp,cb,cd,ce,ca_ready,cs_ready,cov,ctx_zeroize_done;wire[31:0]cod;wire[3:0]cok;wire col;
 reg child_zeroize_req;
 wire[31:0]feed_data=(word_index<8)?input_reg[32*word_index +:32]:{16'h0,input_reg[271:256]};
 wire[3:0]feed_keep=(word_index<8)?4'b1111:4'b0011;
 assign init_ready=!zeroize_busy&&((state==IDLE)||(state==ACTIVE&&ci_ready&&!cb));
 assign squeeze_req_ready=!zeroize_busy&&(state==ACTIVE)&&cs_ready;assign out_valid=!zeroize_busy&&(state==ACTIVE)&&cov;
 assign out_data=cod;assign out_keep=cok;assign out_last=col;assign context_valid=!zeroize_busy&&(state==ACTIVE)&&cv;
 assign busy=zeroize_busy||!(state==IDLE||state==ACTIVE)||cb;
 keccak_sponge_ctx u_ctx(.clk(clk),.rst_n(rst_n),.init_valid(state==CTX_INIT&&!zeroize_busy),.init_ready(ci_ready),.mode(2'd2),.finalize_valid(state==FINAL&&!zeroize_busy),.finalize_ready(cf_ready),.context_valid(cv),.absorb_phase(cap),.squeeze_phase(csp),.busy(cb),.done(cd),.error(ce),.absorb_valid(state==FEED&&!zeroize_busy),.absorb_ready(ca_ready),.absorb_data(feed_data),.absorb_keep(feed_keep),.squeeze_req_valid((state==ACTIVE)&&squeeze_req_valid&&!zeroize_busy),.squeeze_req_ready(cs_ready),.squeeze_len_bytes(squeeze_len_bytes),.out_valid(cov),.out_ready((state==ACTIVE)&&out_ready&&!zeroize_busy),.out_data(cod),.out_keep(cok),.out_last(col),.zeroize_req(child_zeroize_req),.zeroize_done(ctx_zeroize_done));
 always @(posedge clk)begin
  child_zeroize_req<=0;zeroize_done<=0;
  if(!rst_n)begin state<=IDLE;input_reg<=0;word_index<=0;done<=0;error<=0;zeroize_busy<=0;zeroize_done<=0;child_zeroize_req<=0;end
  else if(zeroize_req===1'b1&&!zeroize_busy)begin state<=IDLE;input_reg<=0;word_index<=0;done<=0;error<=0;zeroize_busy<=1;child_zeroize_req<=1;end
  else if(zeroize_busy)begin state<=IDLE;input_reg<=0;word_index<=0;done<=0;error<=0;child_zeroize_req<=1;if(ctx_zeroize_done)begin zeroize_busy<=0;zeroize_done<=1;child_zeroize_req<=0;end end
  else begin done<=0;if(ce)error<=1;if(init_valid&&!init_ready)error<=1;
   if(state==ACTIVE&&cov&&out_ready&&col)done<=1;
   case(state)
    IDLE,ACTIVE:if(init_valid&&init_ready)begin input_reg<=use_generic_input?generic_input:{index1,index0,seed};word_index<=0;error<=0;state<=CTX_INIT;end
    CTX_INIT:if(ci_ready)state<=FEED;
    FEED:if(ca_ready)begin if(word_index==8)state<=FINAL;else word_index<=word_index+1'b1;end
    FINAL:if(cf_ready)state<=WAIT_ACTIVE;
    WAIT_ACTIVE:if(csp)state<=ACTIVE;
    default:begin error<=1;state<=IDLE;end
   endcase
  end
 end
endmodule
