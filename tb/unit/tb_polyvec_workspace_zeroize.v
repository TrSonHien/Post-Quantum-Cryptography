`timescale 1ns/1ps
module tb_polyvec_workspace_zeroize;
 reg clk=0,rst_n=0,zeroize_req=0;
 reg load_begin=0,load_we=0;reg[1:0]load_poly_idx=0,load_poly_idx_we=0,load_domain=1;
 reg[7:0]load_idx=0;reg[11:0]load_coeff=0;
 wire load_ready,zeroize_busy,zeroize_done,error,result_valid,int_rd_valid;
 wire[2:0]poly_complete;wire vector_complete,domain_consistent;wire[1:0]vector_domain;wire[11:0]result_coeff,int_rd_coeff;
 integer p,i,checks=0,cycle_count=0,start_cycle,latency;
 always#5 clk=~clk;
 polyvec_workspace dut(.clk(clk),.rst_n(rst_n),.load_begin(load_begin),
  .load_poly_idx(load_poly_idx),.load_domain(load_domain),.load_we(load_we),
  .load_poly_idx_we(load_poly_idx_we),.load_idx(load_idx),.load_coeff(load_coeff),
  .load_ready(load_ready),.acquire_internal(1'b0),.init_internal(1'b0),
  .init_domain(2'd0),.publish_result(1'b0),.release_internal(1'b0),
  .poly_complete(poly_complete),.vector_complete(vector_complete),
  .domain_consistent(domain_consistent),.vector_domain(vector_domain),.error(error),
  .result_req(1'b0),.result_poly_idx(2'd0),.result_idx(8'd0),
  .result_valid(result_valid),.result_coeff(result_coeff),.int_rd_req(1'b0),
  .int_rd_poly_idx(2'd0),.int_rd_idx(8'd0),.int_rd_valid(int_rd_valid),
  .int_rd_coeff(int_rd_coeff),.int_wr_en(1'b0),.int_wr_poly_idx(2'd0),
  .int_wr_idx(8'd0),.int_wr_coeff(12'd0),.zeroize_req(zeroize_req),
  .zeroize_busy(zeroize_busy),.zeroize_done(zeroize_done));
 task tick;begin @(posedge clk);#1;cycle_count=cycle_count+1;end endtask
 task fill_nonzero;begin
  for(i=0;i<128;i=i+1)begin
   dut.w0.bank_even[i]=12'(i+1);dut.w0.bank_odd[i]=12'(i+129);
   dut.w1.bank_even[i]=12'(i+257);dut.w1.bank_odd[i]=12'(i+385);
   dut.w2.bank_even[i]=12'(i+513);dut.w2.bank_odd[i]=12'(i+641);
  end
 end endtask
 task request_scrub;begin zeroize_req=1;tick;zeroize_req=0;if(!zeroize_busy)$fatal(1,"parent busy missing");checks=checks+1;end endtask
 initial begin
  tick;rst_n=1;tick;fill_nonzero;request_scrub;
  if(load_ready||result_valid||int_rd_valid)$fatal(1,"parent exposed access during scrub");checks=checks+3;
  repeat(20)tick;rst_n=0;tick;
  if(zeroize_busy||zeroize_done)$fatal(1,"reset did not cancel vector scrub");checks=checks+2;
  if(dut.w2.bank_odd[127]===0)$fatal(1,"reset falsely completed vector scrub");checks=checks+1;
  rst_n=1;tick;fill_nonzero;start_cycle=cycle_count;request_scrub;
  while(!zeroize_done)begin tick;if(cycle_count-start_cycle>145)$fatal(1,"vector scrub timeout");end
  latency=cycle_count-start_cycle;
  if(latency!=132)$fatal(1,"vector scrub latency exp=132 got=%0d",latency);checks=checks+1;
  tick;if(zeroize_done)$fatal(1,"vector done wider than one cycle");checks=checks+1;
  for(i=0;i<128;i=i+1)begin
   if(dut.w0.bank_even[i]!==0||dut.w0.bank_odd[i]!==0||
      dut.w1.bank_even[i]!==0||dut.w1.bank_odd[i]!==0||
      dut.w2.bank_even[i]!==0||dut.w2.bank_odd[i]!==0)$fatal(1,"vector address %0d not zero",i);
   checks=checks+6;
  end
  if(dut.w0.result_coeff!==0||dut.w0.int_rd_coeff!==0||dut.w0.int_pair_rd0!==0||dut.w0.int_pair_rd1!==0||
     dut.w1.result_coeff!==0||dut.w1.int_rd_coeff!==0||dut.w1.int_pair_rd0!==0||dut.w1.int_pair_rd1!==0||
     dut.w2.result_coeff!==0||dut.w2.int_rd_coeff!==0||dut.w2.int_pair_rd0!==0||dut.w2.int_pair_rd1!==0)
    $fatal(1,"vector child scalar payload not zero");checks=checks+12;
  if(poly_complete!=0||vector_complete||domain_consistent||vector_domain!=0||error)$fatal(1,"vector metadata not invalidated");checks=checks+5;
  load_poly_idx=0;load_begin=1;tick;load_begin=0;load_poly_idx_we=0;load_idx=8'd4;load_coeff=12'd999;load_we=1;tick;load_we=0;
  if(dut.w0.bank_even[2]!==12'd999)$fatal(1,"vector reload failed");checks=checks+1;
  $display("PASS polyvec_workspace_zeroize checks=%0d locations=780 latency=%0d",checks,latency);
  $finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
