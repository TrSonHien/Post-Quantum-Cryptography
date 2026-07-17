`timescale 1ns/1ps
`ifndef MLKEM_TOP_TB_MODULE
`define MLKEM_TOP_TB_MODULE tb_mlkem768_top
`endif
module `MLKEM_TOP_TB_MODULE;
 reg clk=0,rst_n=0,cmd_valid=0;reg[1:0]cmd_mode=0;reg in_valid=0,in_last=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;reg[1:0]in_kind=0;reg rng_req_ready=0,rng_data_valid=0,rng_last=0,rng_fail=0;reg[31:0]rng_data=0;reg[3:0]rng_keep=0;reg out_ready=1;
 wire cmd_ready,busy,done,error,in_ready,rng_req_valid,rng_data_ready,out_valid,out_last;wire[15:0]rng_req_len_bytes;wire[31:0]out_data;wire[3:0]out_keep;wire[1:0]out_kind;
 reg[7:0]d[0:31],z[0:31],m[0:31],exp_ek[0:1183],exp_dk[0:2399],exp_c[0:1087],exp_k[0:31],got_ek[0:1183],got_dk[0:2399],got_c[0:1087],got_k[0:31];integer i,w,off,zero_checks=0;
 mlkem768_top dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task command(input[1:0]mde);begin cmd_mode=mde;cmd_valid=1;while(!cmd_ready)tick;$display("M8_TOP_PROGRESS command mode=%0d top_state=%0d kg_state=%0d en_state=%0d de_state=%0d cycle=%0t",mde,dut.state,dut.kg.state,dut.en.state,dut.de.state,$time);tick;cmd_valid=0;$display("M8_TOP_PROGRESS command_accepted mode=%0d top_state=%0d kg_state=%0d en_state=%0d de_state=%0d cycle=%0t",mde,dut.state,dut.kg.state,dut.en.state,dut.de.state,$time);end endtask
 task rng_send(input integer n,input integer which);begin while(!rng_req_valid)tick;if(rng_req_len_bytes!=n)$fatal;rng_req_ready=1;tick;rng_req_ready=0;for(w=0;w<n/4;w=w+1)begin if(which==0)rng_data=w<8?{d[w*4+3],d[w*4+2],d[w*4+1],d[w*4]}:{z[(w-8)*4+3],z[(w-8)*4+2],z[(w-8)*4+1],z[(w-8)*4]};else rng_data={m[w*4+3],m[w*4+2],m[w*4+1],m[w*4]};rng_keep=4'hf;rng_last=w==n/4-1;rng_data_valid=1;while(!rng_data_ready)tick;tick;rng_data_valid=0;end end endtask
 task send_record(input[1:0]kind,input integer n,input integer src);begin for(w=0;w<n/4;w=w+1)begin in_kind=kind;if(src==0)in_data={got_ek[w*4+3],got_ek[w*4+2],got_ek[w*4+1],got_ek[w*4]};else if(src==1)in_data={got_dk[w*4+3],got_dk[w*4+2],got_dk[w*4+1],got_dk[w*4]};else in_data={got_c[w*4+3],got_c[w*4+2],got_c[w*4+1],got_c[w*4]};in_keep=4'hf;in_last=w==n/4-1;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end end endtask
 task check_kg_zero;integer q;begin
  for(q=0;q<64;q=q+1)begin if(dut.kg.entropy[q]!==0)$fatal(1,"KeyGen entropy not scrubbed q=%0d",q);zero_checks=zero_checks+1;end
  for(q=0;q<32;q=q+1)begin if(dut.kg.core.d[q]!==0||dut.kg.core.z[q]!==0||dut.kg.core.h[q]!==0)$fatal(1,"KeyGen internal scalar buffer not scrubbed q=%0d",q);zero_checks=zero_checks+3;end
  for(q=0;q<1184;q=q+1)begin if(dut.kg.core.ek[q]!==0)$fatal(1,"KeyGen internal EK not scrubbed q=%0d",q);zero_checks=zero_checks+1;end
  for(q=0;q<1152;q=q+1)begin if(dut.kg.core.dkpke[q]!==0)$fatal(1,"KeyGen internal dkPKE not scrubbed q=%0d",q);zero_checks=zero_checks+1;end
  for(q=0;q<2400;q=q+1)begin if(dut.kg.core.dk[q]!==0)$fatal(1,"KeyGen internal DK not scrubbed q=%0d",q);zero_checks=zero_checks+1;end
  if(dut.kg.core.kcore.d[0]!==0||dut.kg.core.kcore.s[0]!==0||dut.kg.core.kcore.nv.seed_q!==0)$fatal(1,"KeyGen K-PKE hierarchy not scrubbed");zero_checks=zero_checks+3;
 end endtask
 task check_en_zero;integer q;begin
  for(q=0;q<1184;q=q+1)begin if(dut.en.ek[q]!==0||dut.en.core.ek[q]!==0)$fatal(1,"Encaps EK copy not scrubbed q=%0d",q);zero_checks=zero_checks+2;end
  for(q=0;q<32;q=q+1)begin if(dut.en.m[q]!==0||dut.en.core.m[q]!==0||dut.en.core.h[q]!==0||dut.en.core.k[q]!==0||dut.en.core.r[q]!==0)$fatal(1,"Encaps secret scalar buffer not scrubbed q=%0d",q);zero_checks=zero_checks+5;end
  for(q=0;q<1088;q=q+1)begin if(dut.en.core.c[q]!==0)$fatal(1,"Encaps ciphertext staging not scrubbed q=%0d",q);zero_checks=zero_checks+1;end
  if(dut.en.core.ec.m[0]!==0||dut.en.core.ec.nv.seed_q!==0||dut.en.core.ec.pn.u.va.w0.bank_even[0]!==0||dut.en.core.ec.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank0.mem[0]!==0)$fatal(1,"Encaps K-PKE workspace hierarchy not scrubbed");zero_checks=zero_checks+4;
  if(dut.en.core.hc.u.u.u_ctx.state_reg!==0||dut.en.core.hc.u.u.u_ctx.u_perm.state_reg!==0||dut.en.core.ec.dec.u.word_count!==0)$fatal(1,"Encaps hash/codec hierarchy not scrubbed");zero_checks=zero_checks+3;
 end endtask
 task check_de_zero;integer q;begin
  for(q=0;q<2400;q=q+1)begin if(dut.de.dk[q]!==0||dut.de.core.dk[q]!==0)$fatal(1,"Decaps DK copy not scrubbed q=%0d",q);zero_checks=zero_checks+2;end
  for(q=0;q<1088;q=q+1)begin if(dut.de.c[q]!==0||dut.de.core.c[q]!==0||dut.de.core.cp[q]!==0)$fatal(1,"Decaps ciphertext buffer not scrubbed q=%0d",q);zero_checks=zero_checks+3;end
  for(q=0;q<32;q=q+1)begin if(dut.de.core.mp[q]!==0||dut.de.core.kp[q]!==0||dut.de.core.rp[q]!==0||dut.de.core.kb[q]!==0||dut.de.core.kout[q]!==0)$fatal(1,"Decaps secret buffer not scrubbed q=%0d",q);zero_checks=zero_checks+5;end
  if(dut.de.core.mismatch!==0||dut.de.core.mask!==0||dut.de.core.dc.dk[0]!==0||dut.de.core.ec.m[0]!==0)$fatal(1,"Decaps reject/K-PKE hierarchy not scrubbed");zero_checks=zero_checks+4;
  if(dut.de.core.gc.u.u.u_ctx.state_reg!==0||dut.de.core.jc.u.u.u_ctx.state_reg!==0)$fatal(1,"Decaps G/J hierarchy not scrubbed");zero_checks=zero_checks+2;
 end endtask
 initial begin string dir,pfx;repeat(2)tick;rst_n=1;tick;while(!cmd_ready)tick;$display("M8_TOP_PROGRESS boot_scrub_done cycle=%0t",$time);if(!$value$plusargs("VEC_DIR=%s",dir))$fatal;if(!$value$plusargs("VEC_PREFIX=%s",pfx))pfx="smoke";$readmemh({dir,"/",pfx,"_d.mem"},d);$readmemh({dir,"/",pfx,"_z.mem"},z);$readmemh({dir,"/",pfx,"_m.mem"},m);$readmemh({dir,"/",pfx,"_ek.mem"},exp_ek);$readmemh({dir,"/",pfx,"_dk.mem"},exp_dk);$readmemh({dir,"/",pfx,"_c.mem"},exp_c);$readmemh({dir,"/",pfx,"_k.mem"},exp_k);
  command(0);rng_send(64,0);off=0;while(!done)begin if(out_valid)begin for(i=0;i<4;i=i+1)if(out_kind==0)got_ek[off*4+i]=out_data[i*8+:8];else got_dk[(off-296)*4+i]=out_data[i*8+:8];off=off+1;end tick;end if(error||off!=896)$fatal;for(i=0;i<1184;i=i+1)if(got_ek[i]!==exp_ek[i])$fatal;for(i=0;i<2400;i=i+1)if(got_dk[i]!==exp_dk[i])$fatal;check_kg_zero;$display("M8_TOP_PROGRESS keygen_done cycle=%0t",$time);tick;
  command(1);send_record(0,1184,0);rng_send(32,1);off=0;while(!done)begin if(out_valid)begin for(i=0;i<4;i=i+1)if(out_kind==2)got_k[off*4+i]=out_data[i*8+:8];else got_c[(off-8)*4+i]=out_data[i*8+:8];off=off+1;end tick;end if(error||off!=280)$fatal;for(i=0;i<1088;i=i+1)if(got_c[i]!==exp_c[i])$fatal;check_en_zero;$display("M8_TOP_PROGRESS encaps_done cycle=%0t",$time);tick;
  command(2);send_record(1,2400,1);send_record(2,1088,2);off=0;while(!done)begin if(out_valid)begin for(i=0;i<4;i=i+1)got_k[off*4+i]=out_data[i*8+:8];off=off+1;end tick;end if(error||off!=8)$fatal;for(i=0;i<32;i=i+1)if(got_k[i]!==exp_k[i])$fatal;check_de_zero;$display("M8_TOP_PROGRESS decaps_done cycle=%0t",$time);tick;
  for(i=0;i<64;i=i+1)dut.kg.entropy[i]=8'haa;
  for(i=0;i<1184;i=i+1)begin dut.en.ek[i]=8'haa;if(i<32)dut.en.m[i]=8'haa;end
  for(i=0;i<2400;i=i+1)begin dut.de.dk[i]=8'haa;if(i<1088)dut.de.c[i]=8'haa;end
  dut.kg.core.d[0]=8'haa;dut.kg.core.kcore.s[0]=12'haa;
  dut.en.core.m[0]=8'haa;dut.en.core.ec.m[0]=8'haa;dut.en.core.ec.nv.seed_q=256'h1;
  dut.en.core.ec.pn.u.va.w0.bank_even[0]=12'haa;dut.en.core.ec.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank0.mem[0]=12'haa;
  dut.en.core.hc.u.u.u_ctx.state_reg={1600{1'b1}};dut.en.core.ec.dec.u.word_count=8'hff;
  dut.de.core.dk[0]=8'haa;dut.de.core.kp[0]=8'haa;dut.de.core.mismatch=1;dut.de.core.mask=8'hff;dut.error=1;
  command(3);while(!done)tick;if(error)$fatal;
  for(i=0;i<64;i=i+1)if(dut.kg.entropy[i]!==0)$fatal;
  for(i=0;i<1184;i=i+1)begin if(dut.en.ek[i]!==0)$fatal;if(i<32&&dut.en.m[i]!==0)$fatal;end
  for(i=0;i<2400;i=i+1)begin if(dut.de.dk[i]!==0)$fatal;if(i<1088&&dut.de.c[i]!==0)$fatal;end
  check_kg_zero;check_en_zero;check_de_zero;if(dut.error!==0||out_valid)$fatal;zero_checks=zero_checks+2;
  tick;command(0);while(!rng_req_valid)tick;rng_req_ready=1;tick;rng_req_ready=0;rng_data=32'ha5a5a5a5;rng_keep=4'hf;rng_last=0;rng_data_valid=1;tick;rng_data_valid=0;command(3);while(!done)tick;if(error||out_valid)$fatal;
  command(0);while(!rng_req_valid)tick;rng_fail=1;tick;rng_fail=0;while(!done)tick;if(!error)$fatal;
  // Reset interrupts scrub without erasing payload; mandatory boot scrub restarts at address zero.
  dut.de.dk[2399]=8'h5a;command(3);repeat(8)tick;rst_n=0;tick;
  if(dut.de.dk[2399]!==8'h5a||done||cmd_ready)$fatal(1,"reset incorrectly erased payload or exposed completion");zero_checks=zero_checks+3;
  rst_n=1;tick;if(cmd_ready)$fatal(1,"cmd_ready asserted before boot scrub");zero_checks=zero_checks+1;
  while(!cmd_ready)tick;if(dut.de.dk[2399]!==0)$fatal(1,"boot scrub did not restart and clear final address");zero_checks=zero_checks+1;
  $display("PASS public_chains=1 keygen_bytes=3584 encaps_bytes=1120 decaps_bytes=32 zeroize_mode=2 active_abort=1 restart=1 reset_interrupt=1 boot_scrub=2 zeroize_locations=%0d",zero_checks);$finish;end
 initial begin #15000000000;$fatal;end
 initial begin
  wait(rst_n);
  repeat(100000)tick;
  if((dut.state==0)||(dut.state==1))begin
   $display("FAIL boot_scrub_timeout top_state=%0d req=%b seen=%b done=%b kg_state=%0d en_state=%0d de_state=%0d kg_req=%b kg_seen=%b en_req=%b en_seen=%b de_req=%b de_seen=%b kgi_state=%0d eni_state=%0d dei_state=%0d",
    dut.state,dut.child_zeroize_req,dut.child_zeroized,dut.child_zeroize_done,
    dut.kg.state,dut.en.state,dut.de.state,dut.kg.child_zeroize_req,dut.kg.child_zeroized,
    dut.en.child_zeroize_req,dut.en.child_zeroized,dut.de.child_zeroize_req,dut.de.child_zeroized,
    dut.kg.core.state,dut.en.core.state,dut.de.core.state);
   $fatal;
  end
 end
endmodule
