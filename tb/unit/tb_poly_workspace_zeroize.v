`timescale 1ns/1ps
module tb_poly_workspace_zeroize;
 reg clk=0,rst_n=0,zeroize_req=0;
 reg load_begin=0,load_we=0;reg[1:0]load_domain=1;reg[7:0]load_idx=0;reg[11:0]load_coeff=0;
 wire load_ready,zeroize_busy,zeroize_done,complete,error,result_valid,int_rd_valid,int_pair_rd_valid;
 wire[1:0]owner,domain;wire[11:0]result_coeff,int_rd_coeff,int_pair_rd0,int_pair_rd1;
 integer i,checks=0,cycle_count=0,start_cycle,latency;
 always#5 clk=~clk;
 poly_workspace dut(
  .clk(clk),.rst_n(rst_n),.load_begin(load_begin),.load_domain(load_domain),
  .load_we(load_we),.load_idx(load_idx),.load_coeff(load_coeff),.load_ready(load_ready),
  .acquire_internal(1'b0),.init_internal(1'b0),.init_domain(2'd0),
  .publish_result(1'b0),.release_internal(1'b0),.owner(owner),.complete(complete),
  .domain(domain),.error(error),.result_req(1'b0),.result_idx(8'd0),
  .result_valid(result_valid),.result_coeff(result_coeff),.int_rd_req(1'b0),
  .int_rd_idx(8'd0),.int_rd_valid(int_rd_valid),.int_rd_coeff(int_rd_coeff),
  .int_pair_rd_req(1'b0),.int_pair_rd_idx(7'd0),.int_pair_rd_valid(int_pair_rd_valid),
  .int_pair_rd0(int_pair_rd0),.int_pair_rd1(int_pair_rd1),.int_wr_en(1'b0),
  .int_wr_idx(8'd0),.int_wr_coeff(12'd0),.int_pair_wr_en(1'b0),
  .int_pair_wr_idx(7'd0),.int_pair_wr0(12'd0),.int_pair_wr1(12'd0),
  .zeroize_req(zeroize_req),.zeroize_busy(zeroize_busy),.zeroize_done(zeroize_done));
 task tick;begin @(posedge clk);#1;cycle_count=cycle_count+1;end endtask
 task fill_nonzero;begin
  for(i=0;i<128;i=i+1)begin dut.bank_even[i]=12'(i+1);dut.bank_odd[i]=12'(i+129);end
  dut.result_coeff=12'habc;dut.int_rd_coeff=12'hdef;dut.int_pair_rd0=12'h123;dut.int_pair_rd1=12'h456;
 end endtask
 task request_scrub;begin zeroize_req=1;tick;zeroize_req=0;if(!zeroize_busy)$fatal(1,"busy missing");checks=checks+1;end endtask
 initial begin
  tick;fill_nonzero;rst_n=1;tick;
  // Reset invalidates metadata, but the module-owned payload is not erased.
  rst_n=0;tick;rst_n=1;tick;
  if(dut.bank_even[0]!==12'd1||dut.bank_odd[127]!==12'd256)$fatal(1,"reset erased payload");checks=checks+2;

  fill_nonzero;request_scrub;
  if(load_ready||result_valid||int_rd_valid||int_pair_rd_valid)$fatal(1,"access visible during scrub");checks=checks+4;
  tick;
  if(dut.bank_even[0]!==0||dut.bank_odd[0]!==0||dut.bank_even[1]===0)$fatal(1,"first scrub write/order failed");checks=checks+3;
  repeat(63)tick;
  if(dut.bank_even[63]!==0||dut.bank_odd[63]!==0||dut.bank_even[64]===0)$fatal(1,"middle scrub write/order failed");checks=checks+3;

  // Interrupted scrub is incomplete and must restart at address zero.
  rst_n=0;tick;
  if(zeroize_busy||zeroize_done)$fatal(1,"reset did not cancel completion");checks=checks+2;
  if(dut.bank_even[127]===0)$fatal(1,"reset falsely completed scrub");checks=checks+1;
  rst_n=1;tick;fill_nonzero;start_cycle=cycle_count;request_scrub;
  while(!zeroize_done)begin tick;if(cycle_count-start_cycle>140)$fatal(1,"scrub timeout");end
  latency=cycle_count-start_cycle;
  if(latency!=130)$fatal(1,"scrub latency exp=130 got=%0d",latency);checks=checks+1;
  if(zeroize_busy)$fatal(1,"busy remained high at completion");checks=checks+1;
  tick;if(zeroize_done)$fatal(1,"done wider than one cycle");checks=checks+1;
  for(i=0;i<128;i=i+1)begin
   if(dut.bank_even[i]!==0||dut.bank_odd[i]!==0)$fatal(1,"payload address %0d not zero",i);
   checks=checks+2;
  end
  if(dut.result_coeff!==0||dut.int_rd_coeff!==0||dut.int_pair_rd0!==0||dut.int_pair_rd1!==0)$fatal(1,"scalar payload not zero");checks=checks+4;
  if(complete||domain!=0||error)$fatal(1,"metadata not invalidated");checks=checks+3;

  // A clean normal load is accepted once ready returns.
  load_begin=1;tick;load_begin=0;load_idx=8'd17;load_coeff=12'd777;load_we=1;tick;load_we=0;
  if(dut.bank_odd[8]!==12'd777)$fatal(1,"reload after scrub failed");checks=checks+1;
  $display("PASS poly_workspace_zeroize checks=%0d locations=260 latency=%0d",checks,latency);
  $finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
