`timescale 1ns/1ps
module tb_ntt_intt_zeroize;
 reg clk=0,rst_n=0,zeroize_req=0,start=0,preload_en=0,result_rd_req=0;
 reg[7:0]preload_idx=0,result_rd_idx=0;reg[11:0]preload_coeff=0;
 wire nb,nd,ne,npr,nrv,nzb,nzd,ib,id,ie,ipr,irv,izb,izd;wire[11:0]nrd,ird;
 integer i,checks=0,cycles=0;reg[1:0]done_seen;
 always#5 clk=~clk;
 ntt_core_pipe n(.clk(clk),.rst_n(rst_n),.start(start),.busy(nb),.done(nd),.error(ne),
  .preload_en(preload_en),.preload_idx(preload_idx),.preload_coeff(preload_coeff),.preload_ready(npr),
  .result_rd_req(result_rd_req),.result_rd_idx(result_rd_idx),.result_rd_valid(nrv),.result_rd_data(nrd),
  .zeroize_req(zeroize_req),.zeroize_busy(nzb),.zeroize_done(nzd));
 intt_core_pipe ii(.clk(clk),.rst_n(rst_n),.start(start),.busy(ib),.done(id),.error(ie),
  .preload_en(preload_en),.preload_idx(preload_idx),.preload_coeff(preload_coeff),.preload_ready(ipr),
  .result_rd_req(result_rd_req),.result_rd_idx(result_rd_idx),.result_rd_valid(irv),.result_rd_data(ird),
  .zeroize_req(zeroize_req),.zeroize_busy(izb),.zeroize_done(izd));
 task tick;begin @(posedge clk);#1;cycles=cycles+1;done_seen=done_seen|{id,nd};end endtask
 task fill_nonzero;begin
  for(i=0;i<128;i=i+1)begin
   n.preload_lo[i]=12'(i+1);ii.preload_first[i]=12'(i+129);
   n.u_banks.u_set_a_bank0.mem[i]=12'(i+1);n.u_banks.u_set_a_bank1.mem[i]=12'(i+129);
   n.u_banks.u_set_b_bank0.mem[i]=12'(i+257);n.u_banks.u_set_b_bank1.mem[i]=12'(i+385);
   ii.u_banks.u_set_a_bank0.mem[i]=12'(i+513);ii.u_banks.u_set_a_bank1.mem[i]=12'(i+641);
   ii.u_banks.u_set_b_bank0.mem[i]=12'(i+769);ii.u_banks.u_set_b_bank1.mem[i]=12'(i+897);
  end
  n.u_zeta_delay.payload_pipe[0]=12'habc;ii.u_zeta_delay.payload_pipe[0]=12'hdef;
  n.u_butterfly.u_mul.prod_s1=24'h123456;ii.u_butterfly.zeta_mont_d1=12'h789;
 end endtask
 task request_scrub;begin zeroize_req=1;tick;zeroize_req=0;if(!nzb||!izb||!nb||!ib)$fatal(1,"core zeroize busy missing");checks=checks+4;end endtask
 initial begin
  tick;rst_n=1;tick;fill_nonzero;request_scrub;repeat(20)tick;rst_n=0;tick;
  if(nzd||izd||nzb||izb)$fatal(1,"reset did not cancel core scrub");checks=checks+4;
  if(n.preload_lo[127]===0||ii.preload_first[127]===0||n.u_banks.u_set_a_bank0.mem[127]===0||ii.u_banks.u_set_b_bank1.mem[127]===0)$fatal(1,"reset falsely completed core scrub");checks=checks+4;
  rst_n=1;tick;fill_nonzero;request_scrub;
  done_seen=0;while(!nzd||!izd)begin tick;if(cycles>400)$fatal(1,"core zeroize timeout n=%b i=%b",nzd,izd);end
  checks=checks+2;tick;if(nzd||izd)$fatal(1,"core zeroize done stale");checks=checks+2;
  for(i=0;i<128;i=i+1)begin
   if(n.preload_lo[i]!==0||ii.preload_first[i]!==0||
      n.u_banks.u_set_a_bank0.mem[i]!==0||n.u_banks.u_set_a_bank1.mem[i]!==0||n.u_banks.u_set_b_bank0.mem[i]!==0||n.u_banks.u_set_b_bank1.mem[i]!==0||
      ii.u_banks.u_set_a_bank0.mem[i]!==0||ii.u_banks.u_set_a_bank1.mem[i]!==0||ii.u_banks.u_set_b_bank0.mem[i]!==0||ii.u_banks.u_set_b_bank1.mem[i]!==0)
      $fatal(1,"core retained address %0d not zero",i);
   checks=checks+10;
  end
  if(n.u_zeta_delay.payload_pipe[0]!==0||ii.u_zeta_delay.payload_pipe[0]!==0||n.u_butterfly.u_mul.prod_s1!==0||ii.u_butterfly.zeta_mont_d1!==0)$fatal(1,"core pipeline payload not zero");checks=checks+4;
  if(n.results_valid||ii.results_valid||n.preload_pair_count!=0||ii.preload_pair_count!=0)$fatal(1,"core metadata not invalid");checks=checks+4;

  // Clean zero transform proves both cores are reusable after hierarchical scrub.
  preload_en=1;preload_coeff=0;
  for(i=0;i<256;i=i+1)begin preload_idx=i[7:0];tick;end
  preload_en=0;start=1;tick;start=0;done_seen=0;
  while(done_seen!=2'b11)begin tick;if(cycles>3000)$fatal(1,"clean transform timeout seen=%b",done_seen);end
  if(ne||ie)$fatal(1,"clean transform error");checks=checks+2;
  result_rd_idx=0;result_rd_req=1;tick;tick;
  if(!nrv||!irv||nrd!==0||ird!==0)$fatal(1,"clean transform result mismatch n=%0d i=%0d",nrd,ird);checks=checks+4;
  result_rd_req=0;tick;
  $display("PASS ntt_intt_zeroize checks=%0d locations=1284",checks);$finish;
 end
 initial begin #1000000;$fatal(1,"watchdog");end
endmodule
