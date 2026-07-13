`timescale 1ns/1ps
module tb_polyvec_elementwise_pipe #(parameter OP=0,parameter VECTOR_FILE="sim/outputs/polyvec_add.mem");
 localparam BIN=(OP<2);reg clk=0,rst_n=0,lb=0,lop=0,lw=0,start=0,rr=0,result_release=0;reg[1:0]lp,ld,rp;reg[7:0]li,ri;reg[11:0]lc;wire lr,busy,done,error,rv,complete;wire[11:0]rc;wire[1:0]rd;always#5 clk=~clk;
 polyvec_elementwise_pipe #(.OP(OP))dut(clk,rst_n,lb,lop,lp,ld,lw,li,lc,lr,start,busy,done,error,rr,rp,ri,rv,rc,rd,complete,result_release);
 localparam WORDS=BIN?36864:24576;reg[11:0]mem[0:WORDS-1];integer v,p,i,base,off,cycles=0,start_cycle,measured=0,comparisons=0,watch;string file;
 task loadvec;input operand;input integer offset;begin lop=operand;for(p=0;p<3;p=p+1)begin@(negedge clk);lb=1;lp=p;ld=(OP==4)?2:1;@(negedge clk);lb=0;for(i=0;i<256;i=i+1)begin lw=1;li=i;lc=mem[offset+p*256+i];@(negedge clk);end lw=0;end end endtask
 always@(posedge clk)cycles<=cycles+1;
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))file=VECTOR_FILE;$readmemh(file,mem);repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<16;v=v+1)begin base=v*(BIN?2304:1536);loadvec(0,base);if(BIN)loadvec(1,base+768);start_cycle=cycles;@(negedge clk);start=1;@(negedge clk);start=0;watch=0;while(!done&&watch<8000)begin@(negedge clk);watch=watch+1;end if(!done)$fatal(1,"timeout op=%0d state=%0d elem=%0d",OP,dut.state,dut.elem);measured=cycles-start_cycle;if(!complete||rd!==(OP==3?2:OP==4?1:1))$fatal(1,"domain op=%0d rd=%0d",OP,rd);off=base+(BIN?1536:768);for(p=0;p<3;p=p+1)for(i=0;i<256;i=i+1)begin rr=1;rp=p;ri=i;@(negedge clk);if(!rv||rc!==mem[off+p*256+i])$fatal(1,"op=%0d v=%0d p=%0d i=%0d exp=%0d got=%0d",OP,v,p,i,mem[off+p*256+i],rc);comparisons=comparisons+1;end rr=0;result_release=1;@(negedge clk);result_release=0;end
  if(error)$fatal(1,"legal error");
  rst_n=0;@(negedge clk);rst_n=1;loadvec(0,0);if(BIN)loadvec(1,768);@(negedge clk);start=1;@(negedge clk);start=0;repeat(20)@(negedge clk);rst_n=0;@(negedge clk);if(busy||done||complete||rv)$fatal(1,"reset cancellation op=%0d",OP);rst_n=1;
  loadvec(0,0);if(BIN)loadvec(1,768);@(negedge clk);start=1;@(negedge clk);start=0;watch=0;while(!done&&watch<8000)begin@(negedge clk);watch=watch+1;end if(!done||error)$fatal(1,"restart op=%0d",OP);
  start=1;@(negedge clk);start=0;@(negedge clk);if(!error)$fatal(1,"overwrite/start error op=%0d",OP);
  $display("PASS tb_polyvec_elementwise_pipe op=%0d vectors=16 comparisons=%0d cycles=%0d reset_control=PASS",OP,comparisons,measured);$finish;end
endmodule
