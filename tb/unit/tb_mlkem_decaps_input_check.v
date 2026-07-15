`timescale 1ns/1ps
module tb_mlkem_decaps_input_check;
 reg clk=0,rst_n=0,start=0,in_valid=0,in_kind=0,in_last=0,zeroize=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;
 wire busy,in_ready,done,error,inputs_valid,zeroize_busy,zeroize_done;wire[5:0]hash_bytes_compared;
 reg[7:0]dkv[0:2399],cv[0:1087],origdk[0:2399];integer i,cases=0,refcmp=-1;
 mlkem_decaps_input_check dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task send(input k,input integer n);integer w;begin for(w=0;w<n/4;w=w+1)begin in_kind=k;if(k)in_data={cv[w*4+3],cv[w*4+2],cv[w*4+1],cv[w*4]};else in_data={dkv[w*4+3],dkv[w*4+2],dkv[w*4+1],dkv[w*4]};in_keep=4'hf;in_last=w==n/4-1;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end end endtask
 task run_case(input exp,input integer mode);begin start=1;tick;start=0;send(0,2400);send(1,1088);while(!done)tick;if(error||inputs_valid!==exp||hash_bytes_compared!=32)begin $display("FAIL mode=%0d valid=%b error=%b compare=%0d",mode,inputs_valid,error,hash_bytes_compared);$fatal;end if(refcmp<0)refcmp=hash_bytes_compared;else if(hash_bytes_compared!=refcmp)$fatal;cases=cases+1;tick;end endtask
 initial begin string dir;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;$readmemh({dir,"/smoke_dk.mem"},origdk);$readmemh({dir,"/smoke_c.mem"},cv);
  for(i=0;i<2400;i=i+1)dkv[i]=origdk[i];run_case(1,0);
  for(i=0;i<2400;i=i+1)dkv[i]=origdk[i];dkv[1152]^=1;run_case(0,1);
  for(i=0;i<2400;i=i+1)dkv[i]=origdk[i];dkv[2336+16]^=1;run_case(0,2);
  for(i=0;i<2400;i=i+1)dkv[i]=origdk[i];dkv[2368]^=1;run_case(1,3);
  for(i=0;i<2400;i=i+1)dkv[i]=origdk[i];dkv[0]^=1;run_case(1,4);
  zeroize=1;tick;zeroize=0;while(!zeroize_done)tick;for(i=0;i<2400;i=i+1)if(dut.dk[i]!==0)$fatal;for(i=0;i<1088;i=i+1)if(dut.c[i]!==0)$fatal;
  $display("PASS cases=%0d hash_bytes_per_case=32 scrub_bytes=%0d",cases,2400+1088+32);$finish;
 end
 initial begin #1000000000;$display("FAIL timeout");$fatal;end
endmodule
