`timescale 1ns/1ps
module tb_polyvec_basemul_acc_pipe;
 reg clk=0,rst_n=0,lb=0,lop=0,lw=0,start=0,rr=0,rl=0;reg[1:0]lp,ld;reg[7:0]li,ri;reg[11:0]lc;wire lr,busy,done,error,rv,complete;wire[11:0]rc;wire[1:0]rd;always#5 clk=~clk;
 polyvec_basemul_acc_pipe dut(clk,rst_n,lb,lop,lp,ld,lw,li,lc,lr,start,busy,done,error,rr,ri,rv,rc,rd,complete,rl);
 reg[11:0]mem[0:57343];integer v,p,i,base,cycles=0,sc,measured,watch,comparisons=0,starts=0,requests=0,writes=0,addwrites=0;string file;always@(posedge clk)begin cycles<=cycles+1;if(rst_n&&dut.child_start)starts<=starts+1;if(rst_n&&dut.child.pair_req)requests<=requests+1;if(rst_n&&dut.child.bc_valid&&dut.child.meta_valid)writes<=writes+1;if(rst_n&&dut.add_write)addwrites<=addwrites+1;end
 task loadvec;input operand;input integer off;begin lop=operand;for(p=0;p<3;p=p+1)begin@(negedge clk);lb=1;lp=p;ld=2;@(negedge clk);lb=0;for(i=0;i<256;i=i+1)begin lw=1;li=i;lc=mem[off+p*256+i];@(negedge clk);end lw=0;end end endtask
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");$readmemh(file,mem);repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<32;v=v+1)begin base=v*1792;loadvec(0,base);loadvec(1,base+768);sc=cycles;@(negedge clk);start=1;@(negedge clk);start=0;watch=0;while(!done&&watch<5000)begin@(negedge clk);watch=watch+1;end if(!done)$fatal(1,"timeout state=%0d elem=%0d idx=%0d",dut.state,dut.elem,dut.idx);measured=cycles-sc;if(!complete||rd!=2)$fatal(1,"domain");for(i=0;i<256;i=i+1)begin rr=1;ri=i;@(negedge clk);if(!rv||rc!==mem[base+1536+i])$fatal(1,"v=%0d i=%0d exp=%0d got=%0d",v,i,mem[base+1536+i],rc);comparisons=comparisons+1;end rr=0;rl=1;@(negedge clk);rl=0;end
  if(error)$fatal(1,"legal error");if(starts!=96||requests!=12288||writes!=12288||addwrites!=16384)$fatal(1,"counts starts=%0d req=%0d writes=%0d add=%0d",starts,requests,writes,addwrites);
  rst_n=0;@(negedge clk);rst_n=1;loadvec(0,0);loadvec(1,768);@(negedge clk);start=1;@(negedge clk);start=0;repeat(100)@(negedge clk);rst_n=0;@(negedge clk);if(busy||done||complete||rv)$fatal(1,"reset cancellation");rst_n=1;
  loadvec(0,0);loadvec(1,768);@(negedge clk);start=1;@(negedge clk);start=0;watch=0;while(!done&&watch<5000)begin@(negedge clk);watch=watch+1;end if(!done||error)$fatal(1,"restart");start=1;@(negedge clk);start=0;@(negedge clk);if(!error)$fatal(1,"overwrite/start error");
  $display("PASS tb_polyvec_basemul_acc_pipe vectors=32 comparisons=%0d cycles=%0d basemuls_per_vector=3 requests_per_vector=384 writes_per_vector=384 accumulation_writes_per_vector=512 reset_control=PASS",comparisons,measured);$finish;end
endmodule
