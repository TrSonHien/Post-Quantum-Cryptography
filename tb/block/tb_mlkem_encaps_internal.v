`timescale 1ns/1ps
module tb_mlkem_encaps_internal;
 reg clk=0,rst_n=0,cmd_valid=0,in_valid=0,in_last=0,out_ready=0,zeroize_req=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;wire cmd_ready,in_ready,out_valid,out_last,out_kind,busy,done,error,zeroize_busy,zeroize_done;wire[31:0]out_data,cycle_count;wire[3:0]out_keep;
 reg[7:0]ek[0:1183],m[0:31],k[0:31],c[0:1087];integer i,w,oi=0,bytes=0,stall=0;
 mlkem_encaps_internal dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 initial begin string dir,pfx;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;if(!$value$plusargs("VEC_PREFIX=%s",pfx))pfx="smoke";$readmemh({dir,"/",pfx,"_ek.mem"},ek);$readmemh({dir,"/",pfx,"_m.mem"},m);$readmemh({dir,"/",pfx,"_k.mem"},k);$readmemh({dir,"/",pfx,"_c.mem"},c);
 cmd_valid=1;tick;cmd_valid=0;for(w=0;w<304;w=w+1)begin if(w<296)in_data={ek[w*4+3],ek[w*4+2],ek[w*4+1],ek[w*4]};else in_data={m[(w-296)*4+3],m[(w-296)*4+2],m[(w-296)*4+1],m[(w-296)*4]};in_keep=4'hf;in_last=w==303;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end
 while(!done)begin out_ready=(stall%9)!=4;if(out_valid&&out_ready)begin for(i=0;i<4;i=i+1)begin if(!out_kind)begin if(out_data[i*8+:8]!==k[oi*4+i])$fatal;end else if(out_data[i*8+:8]!==c[(oi-8)*4+i])$fatal;bytes=bytes+1;end oi=oi+1;end tick;stall=stall+1;end if(error||oi!=280)$fatal;
 for(i=0;i<32;i=i+1)if(dut.m[i]!==0||dut.h[i]!==0||dut.k[i]!==0||dut.r[i]!==0)$fatal;$display("PASS vectors=1 byte_comparisons=%0d cycles=%0d scrub_addresses=1184",bytes,cycle_count);$finish;end
 initial begin #3000000000;$fatal;end
endmodule
