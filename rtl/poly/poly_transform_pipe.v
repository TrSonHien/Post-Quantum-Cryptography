`timescale 1ns/1ps
module poly_transform_pipe #(parameter IS_INVERSE=0)(
 input wire clk,input wire rst_n,input wire load_begin,input wire[1:0]load_domain,
 input wire load_we,input wire[7:0]load_idx,input wire[11:0]load_coeff,output wire load_ready,
 input wire start,output reg busy,output reg done,output reg error,
 input wire result_req,input wire[7:0]result_idx,output wire result_valid,output wire[11:0]result_coeff,
 output wire[1:0]result_domain,output wire result_complete,input wire result_release);
 localparam[1:0]INVALID=0,NORMAL=1,NTT=2;
 localparam[3:0]IDLE=0,LOAD_READ=1,LOAD_DRAIN=2,START_CORE=3,WAIT_CORE=4,
                 READ_CORE=5,READ_DRAIN=6,PUBLISH=7,DONE=8;
 reg[3:0]state;reg[7:0]transfer_idx,load_idx_d,result_idx_d;reg result_available;
 wire in_complete,out_complete;wire[1:0]in_domain,out_domain,in_owner,out_owner;wire in_error,out_error;
 wire ws_rd_req=(state==LOAD_READ);wire ws_rd_valid;wire[11:0]ws_rd_coeff;
 wire core_start=(state==START_CORE);wire core_busy,core_done,core_error,core_preload_ready;
 wire core_result_req=(state==READ_CORE)||(state==READ_DRAIN);wire core_result_valid;wire[11:0]core_result_data;
 wire expected_input=(IS_INVERSE?in_domain==NTT:in_domain==NORMAL);
 wire[1:0]expected_output=IS_INVERSE?NORMAL:NTT;
 wire start_ok=!busy&&!result_available&&in_complete&&expected_input;
 wire accepted=start&&start_ok;wire publish=(state==PUBLISH);wire source_release=(state==PUBLISH);
 assign load_ready=!busy;
 assign result_domain=result_available?out_domain:INVALID;
 assign result_complete=result_available&&out_complete;

 poly_workspace ws_in(.clk(clk),.rst_n(rst_n),.load_begin(load_begin),.load_domain(load_domain),
  .load_we(load_we),.load_idx(load_idx),.load_coeff(load_coeff),.load_ready(),
  .acquire_internal(accepted),.init_internal(1'b0),.init_domain(2'b0),.publish_result(1'b0),
  .release_internal(source_release),.owner(in_owner),.complete(in_complete),.domain(in_domain),.error(in_error),
  .result_req(1'b0),.result_idx(8'b0),.result_valid(),.result_coeff(),
  .int_rd_req(ws_rd_req),.int_rd_idx(transfer_idx),.int_rd_valid(ws_rd_valid),.int_rd_coeff(ws_rd_coeff),
  .int_pair_rd_req(1'b0),.int_pair_rd_idx(7'b0),.int_pair_rd_valid(),.int_pair_rd0(),.int_pair_rd1(),
  .int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),
  .int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0));
 poly_workspace ws_out(.clk(clk),.rst_n(rst_n),.load_begin(1'b0),.load_domain(2'b0),
  .load_we(1'b0),.load_idx(8'b0),.load_coeff(12'b0),.load_ready(),
  .acquire_internal(1'b0),.init_internal(accepted),.init_domain(expected_output),.publish_result(publish),
  .release_internal(1'b0),.owner(out_owner),.complete(out_complete),.domain(out_domain),.error(out_error),
  .result_req(result_req&&result_available),.result_idx(result_idx),.result_valid(result_valid),.result_coeff(result_coeff),
  .int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),
  .int_pair_rd_req(1'b0),.int_pair_rd_idx(7'b0),.int_pair_rd_valid(),.int_pair_rd0(),.int_pair_rd1(),
  .int_wr_en(core_result_valid),.int_wr_idx(result_idx_d),.int_wr_coeff(core_result_data),
  .int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0));

 generate if(IS_INVERSE) begin:intt_gen
  intt_core_pipe core(.clk(clk),.rst_n(rst_n),.start(core_start),.busy(core_busy),.done(core_done),.error(core_error),
   .preload_en(ws_rd_valid),.preload_idx(load_idx_d),.preload_coeff(ws_rd_coeff),.preload_ready(core_preload_ready),
   .result_rd_req(core_result_req),.result_rd_idx(transfer_idx),.result_rd_valid(core_result_valid),.result_rd_data(core_result_data));
 end else begin:ntt_gen
  ntt_core_pipe core(.clk(clk),.rst_n(rst_n),.start(core_start),.busy(core_busy),.done(core_done),.error(core_error),
   .preload_en(ws_rd_valid),.preload_idx(load_idx_d),.preload_coeff(ws_rd_coeff),.preload_ready(core_preload_ready),
   .result_rd_req(core_result_req),.result_rd_idx(transfer_idx),.result_rd_valid(core_result_valid),.result_rd_data(core_result_data));
 end endgenerate

 always @(posedge clk) begin
  if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;transfer_idx<=0;load_idx_d<=0;result_idx_d<=0;result_available<=0;end
  else begin
   done<=0;
   if(ws_rd_req)load_idx_d<=transfer_idx;
   if(core_result_req)result_idx_d<=transfer_idx;
   if(in_error||out_error||core_error)error<=1;
   if(start&&!start_ok)error<=1;
   if(busy&&(load_begin||load_we||result_req||result_release))error<=1;
   if(result_req&&!result_available)error<=1;
   if(result_release&&!busy)result_available<=0;
   if(ws_rd_valid&&!core_preload_ready)error<=1;
   case(state)
    IDLE:if(accepted)begin busy<=1;result_available<=0;transfer_idx<=0;state<=LOAD_READ;end
    LOAD_READ:if(transfer_idx==255)state<=LOAD_DRAIN;else transfer_idx<=transfer_idx+1'b1;
    LOAD_DRAIN:if(ws_rd_valid&&load_idx_d==255)state<=START_CORE;
    START_CORE:state<=WAIT_CORE;
    WAIT_CORE:if(core_done)begin transfer_idx<=0;state<=READ_CORE;end
    READ_CORE:if(transfer_idx==255)state<=READ_DRAIN;else transfer_idx<=transfer_idx+1'b1;
    READ_DRAIN:if(core_result_valid&&result_idx_d==255)state<=PUBLISH;
    PUBLISH:state<=DONE;
    DONE:begin busy<=0;done<=1;result_available<=1;state<=IDLE;end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
