`timescale 1ns/1ps
module tb_mlkem_decaps_internal;
 reg clk=0,rst_n=0,cmd_valid=0,in_valid=0,in_last=0,out_ready=0,zeroize_req=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;wire cmd_ready,in_ready,out_valid,out_last,busy,done,error,zeroize_busy,zeroize_done;wire[31:0]out_data,cycle_count;wire[3:0]out_keep;wire[10:0]compare_count;wire[5:0]select_count;
 reg[7:0]dk[0:2399],c[0:1087],badc[0:1087],k[0:31],badk[0:31];integer i,w,oi,checks=0,valid_cases=0,reject_cases=0,refpre=-1;
 mlkem_decaps_internal dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task run_case(input reject);integer pre;reg[7:0]exp;begin cmd_valid=1;tick;cmd_valid=0;for(w=0;w<872;w=w+1)begin if(w<600)in_data={dk[w*4+3],dk[w*4+2],dk[w*4+1],dk[w*4]};else if(reject)in_data={badc[(w-600)*4+3],badc[(w-600)*4+2],badc[(w-600)*4+1],badc[(w-600)*4]};else in_data={c[(w-600)*4+3],c[(w-600)*4+2],c[(w-600)*4+1],c[(w-600)*4]};in_keep=4'hf;in_last=w==871;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end pre=0;while(!out_valid)begin tick;pre=pre+1;end if(compare_count!=1088||select_count!=32||dut.mismatch!==0||dut.mask!==0)$fatal;oi=0;out_ready=1;while(!done)begin if(out_valid)begin for(i=0;i<4;i=i+1)begin exp=reject?badk[oi*4+i]:k[oi*4+i];if(out_data[i*8+:8]!==exp)$fatal;checks=checks+1;end oi=oi+1;end tick;end out_ready=0;if(error||oi!=8)$fatal;if(reject)reject_cases=reject_cases+1;else valid_cases=valid_cases+1;tick;end endtask
 initial begin string dir;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;$readmemh({dir,"/smoke_dk.mem"},dk);$readmemh({dir,"/smoke_c.mem"},c);$readmemh({dir,"/smoke_modified_c.mem"},badc);$readmemh({dir,"/smoke_k.mem"},k);$readmemh({dir,"/smoke_modified_k.mem"},badk);run_case(0);run_case(1);
  $display("PASS valid_cases=%0d implicit_rejection_cases=%0d exact_K_bytes=%0d compare_cycles=1088 select_cycles=32 last_cycles=%0d",valid_cases,reject_cases,checks,cycle_count);$finish;end
 initial begin #6000000000;$fatal;end
endmodule
