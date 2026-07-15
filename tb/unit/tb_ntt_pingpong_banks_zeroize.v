`timescale 1ns/1ps
module tb_ntt_pingpong_banks_zeroize;
 reg clk=0,rst_n=0,zeroize_req=0,swap_roles=0,src_rd_en=0,dst_wr_en=0;
 reg[7:0]src_index0=0,src_index1=8'd128,dst_index0=0,dst_index1=8'd128;
 reg[2:0]src_pair_bit=7,src_addr_bit=7,dst_pair_bit=7,dst_addr_bit=7;
 reg src_xor_layout=0,dst_xor_layout=0;reg[11:0]dst_data0=0,dst_data1=0;
 wire role_select,src_rd_valid,zeroize_busy,zeroize_done;wire[11:0]src_data0,src_data1;
 integer i,checks=0,cycle_count=0,start_cycle,latency;
 always#5 clk=~clk;
 ntt_pingpong_banks dut(.clk(clk),.rst_n(rst_n),.swap_roles(swap_roles),
  .role_select(role_select),.src_rd_en(src_rd_en),.src_index0(src_index0),
  .src_index1(src_index1),.src_pair_bit(src_pair_bit),.src_addr_bit(src_addr_bit),
  .src_xor_layout(src_xor_layout),.src_rd_valid(src_rd_valid),.src_data0(src_data0),
  .src_data1(src_data1),.dst_wr_en(dst_wr_en),.dst_index0(dst_index0),
  .dst_index1(dst_index1),.dst_pair_bit(dst_pair_bit),.dst_addr_bit(dst_addr_bit),
  .dst_xor_layout(dst_xor_layout),.dst_data0(dst_data0),.dst_data1(dst_data1),
  .zeroize_req(zeroize_req),.zeroize_busy(zeroize_busy),.zeroize_done(zeroize_done));
 task tick;begin @(posedge clk);#1;cycle_count=cycle_count+1;end endtask
 task fill_nonzero;begin
  for(i=0;i<128;i=i+1)begin
   dut.u_set_a_bank0.mem[i]=12'(i+1);dut.u_set_a_bank1.mem[i]=12'(i+129);
   dut.u_set_b_bank0.mem[i]=12'(i+257);dut.u_set_b_bank1.mem[i]=12'(i+385);
  end
 end endtask
 task request_scrub;begin zeroize_req=1;tick;zeroize_req=0;if(!zeroize_busy)$fatal(1,"busy missing");checks=checks+1;end endtask
 initial begin
  tick;fill_nonzero;rst_n=1;tick;rst_n=0;tick;rst_n=1;tick;
  if(dut.u_set_a_bank0.mem[0]!==12'd1||dut.u_set_b_bank1.mem[127]!==12'd512)$fatal(1,"reset erased transform RAM");checks=checks+2;
  fill_nonzero;request_scrub;src_rd_en=1;dst_wr_en=1;tick;src_rd_en=0;dst_wr_en=0;
  if(src_rd_valid)$fatal(1,"read response escaped during scrub");checks=checks+1;
  if(dut.u_set_a_bank0.mem[0]!==0||dut.u_set_a_bank1.mem[0]!==0||dut.u_set_b_bank0.mem[0]!==0||dut.u_set_b_bank1.mem[0]!==0||dut.u_set_a_bank0.mem[1]===0)$fatal(1,"first bank scrub write/order failed");checks=checks+5;
  repeat(63)tick;
  if(dut.u_set_a_bank0.mem[63]!==0||dut.u_set_b_bank1.mem[63]!==0||dut.u_set_a_bank0.mem[64]===0)$fatal(1,"middle bank scrub write/order failed");checks=checks+3;
  rst_n=0;tick;
  if(zeroize_busy||zeroize_done)$fatal(1,"reset did not cancel bank scrub");checks=checks+2;
  if(dut.u_set_a_bank0.mem[127]===0||dut.u_set_b_bank1.mem[127]===0)$fatal(1,"reset falsely completed bank scrub");checks=checks+2;
  rst_n=1;tick;fill_nonzero;start_cycle=cycle_count;request_scrub;
  while(!zeroize_done)begin tick;if(cycle_count-start_cycle>140)$fatal(1,"bank scrub timeout");end
  latency=cycle_count-start_cycle;
  if(latency!=130)$fatal(1,"bank scrub latency exp=130 got=%0d",latency);checks=checks+1;
  tick;if(zeroize_done)$fatal(1,"bank done wider than one cycle");checks=checks+1;
  for(i=0;i<128;i=i+1)begin
   if(dut.u_set_a_bank0.mem[i]!==0||dut.u_set_a_bank1.mem[i]!==0||
      dut.u_set_b_bank0.mem[i]!==0||dut.u_set_b_bank1.mem[i]!==0)$fatal(1,"bank address %0d not zero",i);
   checks=checks+4;
  end
  dst_addr_bit=3'd6;#1;dst_addr_bit=3'd7;#1;
  dst_data0=12'd111;dst_data1=12'd222;dst_wr_en=1;tick;dst_wr_en=0;
  if(dut.u_set_b_bank0.mem[0]===0||dut.u_set_b_bank1.mem[0]===0)
    $fatal(1,"normal write after scrub failed b0=%0d b1=%0d role=%0d idx=%0d/%0d bits=%0d/%0d xor=%0d sel=%0d/%0d a0=%0d a1=%0d",dut.u_set_b_bank0.mem[0],dut.u_set_b_bank1.mem[0],role_select,dst_index0,dst_index1,dst_pair_bit,dst_addr_bit,dst_xor_layout,dut.dst_bank0_sel,dut.dst_bank1_sel,dut.dst_phys_addr0,dut.dst_phys_addr1);
  checks=checks+2;
  $display("PASS ntt_pingpong_banks_zeroize checks=%0d locations=512 latency=%0d",checks,latency);
  $finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
