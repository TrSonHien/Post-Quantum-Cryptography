`timescale 1ns/1ps
module tb_poly_basemul_pipe;
 reg clk=0,rst_n=0,load_begin=0,load_operand=0,load_we=0,start=0,result_req=0,result_release=0;reg[1:0]load_domain;reg[7:0]load_idx,result_idx;reg[11:0]load_coeff;wire load_ready,busy,done,error,result_valid,result_complete;wire[11:0]result_coeff;wire[1:0]result_domain;always#5 clk=~clk;
 poly_basemul_pipe dut(.clk(clk),.rst_n(rst_n),.load_begin(load_begin),.load_operand(load_operand),.load_domain(load_domain),
  .a_load_we(load_we&&!load_operand),.a_load_idx(load_idx),.a_load_coeff(load_coeff),
  .b_load_we(load_we&&load_operand),.b_load_idx(load_idx),.b_load_coeff(load_coeff),.load_ready(load_ready),
  .start(start),.busy(busy),.done(done),.error(error),.result_req(result_req),.result_idx(result_idx),
  .result_valid(result_valid),.result_coeff(result_coeff),.result_domain(result_domain),.result_complete(result_complete),.result_release(result_release));
 reg[11:0]va[0:255],vb[0:255],ve[0:255];integer fd,vid,i,rc,checks=0,comparisons=0,cycles,start_cycle,measured=0,done_pulses;string file;
 task loadop;input op;begin @(negedge clk);load_operand=op;load_domain=2;load_begin=1;@(negedge clk);load_begin=0;for(i=0;i<256;i=i+1)begin load_we=1;load_idx=i;load_coeff=op?vb[i]:va[i];@(negedge clk);end load_we=0;end endtask
 task run;begin start_cycle=cycles;@(negedge clk);start=1;@(negedge clk);start=0;i=0;while(!done&&i<400)begin@(negedge clk);i=i+1;end if(!done)$fatal(1,"timeout state=%0d pair=%0d",dut.state,dut.issue_pair);measured=cycles-start_cycle;done_pulses=done_pulses+1;@(negedge clk);if(done)$fatal(1,"done width");if(!result_complete||result_domain!=2)$fatal(1,"domain");for(i=0;i<256;i=i+1)begin result_req=1;result_idx=i;@(negedge clk);if(!result_valid||result_coeff!==ve[i])$fatal(1,"vector=%0d idx=%0d exp=%0d got=%0d",vid,i,ve[i],result_coeff);comparisons=comparisons+1;end result_req=0;result_release=1;@(negedge clk);result_release=0;end endtask
 always@(posedge clk)cycles<=cycles+1;
 initial begin cycles=0;done_pulses=0;if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(vid=0;vid<32;vid=vid+1)begin for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",va[i]);for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",vb[i]);for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",ve[i]);loadop(0);loadop(1);run();end
  if(error)$fatal(1,"legal error");if(done_pulses!=32)$fatal(1,"done count");
  $display("PASS tb_poly_basemul_pipe vectors=32 comparisons=%0d requests_per_vector=128 writes_per_vector=128 cycles=%0d",comparisons,measured);$finish;end
endmodule
