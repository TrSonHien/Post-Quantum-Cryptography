`timescale 1ns/1ps
module tb_mlkem_keygen_internal;
 reg clk=0,rst_n=0,cmd_valid=0,in_valid=0,in_last=0,out_ready=0,zeroize_req=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;
 wire cmd_ready,in_ready,out_valid,out_last,out_kind,busy,done,error,zeroize_busy,zeroize_done;wire[31:0]out_data;wire[3:0]out_keep;wire[31:0]cycle_count;
 reg[7:0]d[0:31],z[0:31],ek[0:1183],dk[0:2399];integer i,w,oi=0,bytes=0,stall=0;
 mlkem_keygen_internal dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 initial begin string dir,pfx;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;if(!$value$plusargs("VEC_PREFIX=%s",pfx))pfx="smoke";$readmemh({dir,"/",pfx,"_d.mem"},d);$readmemh({dir,"/",pfx,"_z.mem"},z);$readmemh({dir,"/",pfx,"_ek.mem"},ek);$readmemh({dir,"/",pfx,"_dk.mem"},dk);
  cmd_valid=1;tick;cmd_valid=0;for(w=0;w<16;w=w+1)begin if(w<8)in_data={d[w*4+3],d[w*4+2],d[w*4+1],d[w*4]};else in_data={z[(w-8)*4+3],z[(w-8)*4+2],z[(w-8)*4+1],z[(w-8)*4]};in_keep=4'hf;in_last=w==15;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end
  while(!done)begin out_ready=(stall%7)!=3;if(out_valid&&out_ready)begin for(i=0;i<4;i=i+1)begin if(!out_kind)begin if(out_data[i*8+:8]!==ek[oi*4+i])$fatal;end else begin if(out_data[i*8+:8]!==dk[(oi-296)*4+i])$fatal;end bytes=bytes+1;end if(out_last!==((oi==295)||(oi==895)))$fatal;oi=oi+1;end tick;stall=stall+1;end
  if(error||oi!=896)$fatal;for(i=0;i<32;i=i+1)if(dut.d[i]!==0||dut.z[i]!==0||dut.h[i]!==0)$fatal;for(i=0;i<1184;i=i+1)if(dut.ek[i]!==0)$fatal;for(i=0;i<2400;i=i+1)if(dut.dk[i]!==0)$fatal;
  $display("PASS vectors=1 byte_comparisons=%0d cycles=%0d scrub_addresses=2400",bytes,cycle_count);$finish;end
 initial begin #2000000000;$display("FAIL timeout");$fatal;end
endmodule
