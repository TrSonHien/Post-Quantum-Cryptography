`timescale 1ns/1ps
module tb_secure_payload_reset;
 reg clk=0,rst_n=0;integer i,checks=0;always#5 clk=~clk;
 wire rv;wire[11:0]rd;
 sync_1r1w_ram #(.DATA_WIDTH(12),.ADDR_WIDTH(7),.DEPTH(128)) ram(
  .clk(clk),.rst_n(rst_n),.rd_en(1'b0),.rd_addr(7'd0),.rd_valid(rv),.rd_data(rd),.wr_en(1'b0),.wr_addr(7'd0),.wr_data(12'd0));
 wire[1:0]owner,domain;wire complete,lr,err,rvalid,irvalid,iprvalid;wire[11:0]rc,irc,ipr0,ipr1;
 poly_workspace ws(.clk(clk),.rst_n(rst_n),.load_begin(1'b0),.load_domain(2'd0),.load_we(1'b0),.load_idx(8'd0),.load_coeff(12'd0),.load_ready(lr),.acquire_internal(1'b0),.init_internal(1'b0),.init_domain(2'd0),.publish_result(1'b0),.release_internal(1'b0),.owner(owner),.complete(complete),.domain(domain),.error(err),.result_req(1'b0),.result_idx(8'd0),.result_valid(rvalid),.result_coeff(rc),.int_rd_req(1'b0),.int_rd_idx(8'd0),.int_rd_valid(irvalid),.int_rd_coeff(irc),.int_pair_rd_req(1'b0),.int_pair_rd_idx(7'd0),.int_pair_rd_valid(iprvalid),.int_pair_rd0(ipr0),.int_pair_rd1(ipr1),.int_wr_en(1'b0),.int_wr_idx(8'd0),.int_wr_coeff(12'd0),.int_pair_wr_en(1'b0),.int_pair_wr_idx(7'd0),.int_pair_wr0(12'd0),.int_pair_wr1(12'd0));
 wire dv;wire[11:0]dp;wire[7:0]dm;
 fixed_latency_delay #(.PAYLOAD_WIDTH(12),.METADATA_WIDTH(8),.LATENCY(4)) delay(.clk(clk),.rst_n(rst_n),.in_valid(1'b0),.in_payload(12'd0),.in_metadata(8'd0),.out_valid(dv),.out_payload(dp),.out_metadata(dm));
 initial begin
  for(i=0;i<128;i=i+1)begin ram.mem[i]=12'habc;ws.bank_even[i]=12'h123;ws.bank_odd[i]=12'h456;end
  for(i=0;i<4;i=i+1)begin delay.payload_pipe[i]=12'h789;delay.metadata_pipe[i]=8'haa;end
  #2;@(posedge clk);#1;
  for(i=0;i<128;i=i+1)begin if(ram.mem[i]!==12'habc||ws.bank_even[i]!==12'h123||ws.bank_odd[i]!==12'h456)$fatal;checks=checks+3;end
  for(i=0;i<4;i=i+1)begin if(delay.payload_pipe[i]!==12'h789||delay.metadata_pipe[i]!==8'haa)$fatal;checks=checks+2;end
  if(dv)$fatal;checks=checks+1;rst_n=1;@(posedge clk);#1;
  $display("PASS reset_logical_invalidation_payload_retained checks=%0d",checks);$finish;
 end
 initial begin #10000;$fatal(1,"timeout");end
endmodule
