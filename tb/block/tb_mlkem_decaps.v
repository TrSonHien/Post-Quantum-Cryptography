`timescale 1ns/1ps
module tb_mlkem_decaps;
 reg clk=0,rst_n=0,cmd_valid=0,in_valid=0,in_kind=0,in_last=0,out_ready=1,zeroize_req=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;wire cmd_ready,in_ready,out_valid,out_last,busy,done,error,zeroize_busy,zeroize_done;wire[31:0]out_data;wire[3:0]out_keep;
 reg[7:0]dk[0:2399],bad_dk[0:2399],c[0:1087],badc[0:1087],k[0:31],badk[0:31];integer i,w,oi,checks=0;
 mlkem_decaps dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task run(input reject,input badhash);reg[7:0]exp;begin cmd_valid=1;tick;cmd_valid=0;for(w=0;w<872;w=w+1)begin in_kind=w>=600;if(w<600)in_data=badhash?{bad_dk[w*4+3],bad_dk[w*4+2],bad_dk[w*4+1],bad_dk[w*4]}:{dk[w*4+3],dk[w*4+2],dk[w*4+1],dk[w*4]};else if(reject)in_data={badc[(w-600)*4+3],badc[(w-600)*4+2],badc[(w-600)*4+1],badc[(w-600)*4]};else in_data={c[(w-600)*4+3],c[(w-600)*4+2],c[(w-600)*4+1],c[(w-600)*4]};in_keep=4'hf;in_last=(w==599)||(w==871);in_valid=1;while(!in_ready)tick;tick;in_valid=0;end oi=0;while(!done)begin if(out_valid)begin if(badhash)$fatal;for(i=0;i<4;i=i+1)begin exp=reject?badk[oi*4+i]:k[oi*4+i];if(out_data[i*8+:8]!==exp)$fatal;checks=checks+1;end oi=oi+1;end tick;end if(error!==badhash||(!badhash&&oi!=8)||(badhash&&oi!=0))$fatal;tick;end endtask
 initial begin string dir;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;$readmemh({dir,"/smoke_dk.mem"},dk);$readmemh({dir,"/smoke_c.mem"},c);$readmemh({dir,"/smoke_modified_c.mem"},badc);$readmemh({dir,"/smoke_k.mem"},k);$readmemh({dir,"/smoke_modified_k.mem"},badk);for(i=0;i<2400;i=i+1)bad_dk[i]=dk[i];bad_dk[2336]^=1;
  if($test$plusargs("HASH_ONLY"))run(0,1);else if($test$plusargs("REJECT_ONLY"))run(1,0);else begin run(0,0);run(1,0);run(0,1);end
  $display("PASS valid=%0d implicit_rejection=%0d hash_failure=%0d K_bytes=%0d",!$test$plusargs("HASH_ONLY")&&!$test$plusargs("REJECT_ONLY"),$test$plusargs("REJECT_ONLY")||(!$test$plusargs("HASH_ONLY")&&!$test$plusargs("REJECT_ONLY")),$test$plusargs("HASH_ONLY")||(!$test$plusargs("HASH_ONLY")&&!$test$plusargs("REJECT_ONLY")),checks);$finish;end
 initial begin #10000000000;$fatal;end
endmodule
