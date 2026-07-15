`timescale 1ns/1ps
module tb_mlkem_keygen;
 reg clk=0,rst_n=0,cmd_valid=0,rng_req_ready=0,rng_data_valid=0,rng_last=0,rng_fail=0,out_ready=1,zeroize_req=0;reg[31:0]rng_data=0;reg[3:0]rng_keep=0;wire cmd_ready,rng_req_valid,rng_data_ready,out_valid,out_last,out_kind,busy,done,error,zeroize_busy,zeroize_done;wire[15:0]rng_req_len_bytes;wire[31:0]out_data;wire[3:0]out_keep;
 reg[7:0]d[0:31],z[0:31],ek[0:1183],dk[0:2399];integer i,w,oi,checks;
 mlkem_keygen dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task success;begin cmd_valid=1;tick;cmd_valid=0;if(!rng_req_valid||rng_req_len_bytes!=64)$fatal;rng_req_ready=1;tick;rng_req_ready=0;for(w=0;w<16;w=w+1)begin rng_data=w<8?{d[w*4+3],d[w*4+2],d[w*4+1],d[w*4]}:{z[(w-8)*4+3],z[(w-8)*4+2],z[(w-8)*4+1],z[(w-8)*4]};rng_keep=4'hf;rng_last=w==15;rng_data_valid=1;while(!rng_data_ready)tick;tick;rng_data_valid=0;end oi=0;while(!done)begin if(out_valid)begin for(i=0;i<4;i=i+1)begin if(!out_kind&&out_data[i*8+:8]!==ek[oi*4+i])$fatal;if(out_kind&&out_data[i*8+:8]!==dk[(oi-296)*4+i])$fatal;checks=checks+1;end oi=oi+1;end tick;end if(error||oi!=896)$fatal;end endtask
 initial begin string dir;repeat(2)tick;rst_n=1;tick;if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;$readmemh({dir,"/smoke_d.mem"},d);$readmemh({dir,"/smoke_z.mem"},z);$readmemh({dir,"/smoke_ek.mem"},ek);$readmemh({dir,"/smoke_dk.mem"},dk);checks=0;success;tick;cmd_valid=1;tick;cmd_valid=0;rng_fail=1;tick;rng_fail=0;while(!done)tick;if(!error||out_valid)$fatal;for(i=0;i<64;i=i+1)if(dut.entropy[i]!==0)$fatal;$display("PASS success=1 rng_failure=1 bytes=%0d",checks);$finish;end
 initial begin #4000000000;$fatal;end
endmodule
