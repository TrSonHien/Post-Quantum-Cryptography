`timescale 1ns/1ps
module tb_m7_kpke_zeroize;
 reg clk=0,rst_n=0,zk=0,ze=0,zd=0,sk=0,se=0,sd=0,ck=0,ce=0,cd=0;reg[6:0]kg_ack;reg[10:0]en_ack;reg[7:0]de_ack;integer i,checks=0,normal_done_seen=0;always#5 clk=~clk;
 wire kb,kd,eb,ed,db,dd,kg_done,en_done,de_done,kg_ready,en_ready,de_ready,kg_out,en_out,de_out;
 kpke_keygen kg(.clk(clk),.rst_n(rst_n),.cmd_valid(ck),.cmd_ready(kg_ready),.in_valid(1'b0),.out_valid(kg_out),.out_ready(1'b0),.done(kg_done),.zeroize(zk),.zeroize_busy(kb),.zeroize_done(kd));
 kpke_encrypt en(.clk(clk),.rst_n(rst_n),.cmd_valid(ce),.cmd_ready(en_ready),.in_valid(1'b0),.out_valid(en_out),.out_ready(1'b0),.done(en_done),.zeroize(ze),.zeroize_busy(eb),.zeroize_done(ed));
 kpke_decrypt de(.clk(clk),.rst_n(rst_n),.cmd_valid(cd),.cmd_ready(de_ready),.in_valid(1'b0),.out_valid(de_out),.out_ready(1'b0),.done(de_done),.zeroize(zd),.zeroize_busy(db),.zeroize_done(dd));
 task tick;begin @(posedge clk);#1;end endtask
 always@(posedge clk)begin if(!rst_n)begin kg_ack<=0;en_ack<=0;de_ack<=0;normal_done_seen<=0;end else begin kg_ack<=kg_ack|kg.child_done_seen|kg.child_zeroize_done;en_ack<=en_ack|en.child_zeroized|en.child_zeroize_done;de_ack<=de_ack|de.child_zeroized|de.child_zeroize_done;if(kg_done||en_done||de_done)normal_done_seen<=1;end end
 initial begin
  tick;rst_n=1;tick;
  for(i=0;i<1184;i=i+1)begin
   kg.ek[i]=8'haa;en.ek[i]=8'haa;
   if(i<1152)begin kg.dk[i]=8'haa;de.dk[i]=8'haa;end
   if(i<1088)begin en.c[i]=8'haa;de.c[i]=8'haa;end
   if(i<32)begin kg.d[i]=8'haa;kg.rho[i]=8'haa;kg.sigma[i]=8'haa;en.m[i]=8'haa;en.r[i]=8'haa;en.rho[i]=8'haa;de.msg[i]=8'haa;end
   if(i<768)begin kg.s[i]=12'haa;kg.e[i]=12'haa;kg.s_hat[i]=12'haa;kg.e_hat[i]=12'haa;kg.a_row[i]=12'haa;kg.t_hat[i]=12'haa;en.t_hat[i]=12'haa;en.y[i]=12'haa;en.e1[i]=12'haa;en.y_hat[i]=12'haa;en.a_row[i]=12'haa;en.u[i]=12'haa;de.u[i]=12'haa;de.s_hat[i]=12'haa;de.u_hat[i]=12'haa;end
   if(i<256)begin kg.dot[i]=12'haa;en.e2[i]=12'haa;en.dot[i]=12'haa;en.product[i]=12'haa;en.mu[i]=12'haa;en.temp[i]=12'haa;en.v[i]=12'haa;de.vp[i]=12'haa;de.dot[i]=12'haa;de.product[i]=12'haa;de.wpoly[i]=12'haa;end
  end
  // Populate representative retained payload at every M7 child-owner class.
  kg.nv.seed_q=256'h1;kg.mr.rho_q=256'h2;en.nv.seed_q=256'h3;en.mr.rho_q=256'h4;en.e2s.p.seed_reg=256'h5;
  en.pn.u.va.w0.bank_even[0]=12'h123;en.pn.u.gn.child.impl.ws_in.bank_even[0]=12'h124;
  en.pn.u.gn.child.impl.ntt_gen.core.preload_lo[0]=12'h125;
  en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank0.mem[0]=12'h126;
  en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank1.mem[0]=12'h127;
  en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_b_bank0.mem[0]=12'h128;
  en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_b_bank1.mem[0]=12'h129;
  en.ba.va.w0.bank_even[0]=12'h12a;en.ba.child.wa.bank_even[0]=12'h12b;en.ba.child.bm.m00.product_s1=24'h123456;
  en.pa.impl.ws_a.bank_even[0]=12'h12c;
  zk=1;ze=1;zd=1;tick;zk=0;ze=0;zd=0;
  while(!(sk&&se&&sd))begin tick;if(kd)sk=1;if(ed)se=1;if(dd)sd=1;end
  for(i=0;i<1184;i=i+1)begin
   if(kg.ek[i]!==0||en.ek[i]!==0)$fatal;checks=checks+2;
   if(i<1152)begin if(kg.dk[i]!==0||de.dk[i]!==0)$fatal;checks=checks+2;end
   if(i<1088)begin if(en.c[i]!==0||de.c[i]!==0)$fatal;checks=checks+2;end
   if(i<32)begin if(kg.d[i]!==0||kg.rho[i]!==0||kg.sigma[i]!==0||en.m[i]!==0||en.r[i]!==0||en.rho[i]!==0||de.msg[i]!==0)$fatal;checks=checks+7;end
   if(i<768)begin if(kg.s[i]!==0||kg.e[i]!==0||kg.s_hat[i]!==0||kg.e_hat[i]!==0||kg.a_row[i]!==0||kg.t_hat[i]!==0||en.t_hat[i]!==0||en.y[i]!==0||en.e1[i]!==0||en.y_hat[i]!==0||en.a_row[i]!==0||en.u[i]!==0||de.u[i]!==0||de.s_hat[i]!==0||de.u_hat[i]!==0)$fatal;checks=checks+15;end
   if(i<256)begin if(kg.dot[i]!==0||en.e2[i]!==0||en.dot[i]!==0||en.product[i]!==0||en.mu[i]!==0||en.temp[i]!==0||en.v[i]!==0||de.vp[i]!==0||de.dot[i]!==0||de.product[i]!==0||de.wpoly[i]!==0)$fatal;checks=checks+11;end
  end
  if(kg_ack!==7'h7f||en_ack!==11'h7ff||de_ack!==8'hff)$fatal(1,"child acknowledgement coverage incomplete kg=%h en=%h de=%h",kg_ack,en_ack,de_ack);
  if(kg.nv.seed_q!==0||kg.mr.rho_q!==0||en.nv.seed_q!==0||en.mr.rho_q!==0||en.e2s.p.seed_reg!==0)$fatal(1,"sampler retained state not scrubbed");
  if(en.pn.u.va.w0.bank_even[0]!==0||en.pn.u.gn.child.impl.ws_in.bank_even[0]!==0||en.pn.u.gn.child.impl.ntt_gen.core.preload_lo[0]!==0)$fatal(1,"transform workspace/preload not scrubbed");
  if(en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank0.mem[0]!==0||en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_a_bank1.mem[0]!==0||en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_b_bank0.mem[0]!==0||en.pn.u.gn.child.impl.ntt_gen.core.u_banks.u_set_b_bank1.mem[0]!==0)$fatal(1,"NTT banks not scrubbed");
  if(en.ba.va.w0.bank_even[0]!==0||en.ba.child.wa.bank_even[0]!==0||en.ba.child.bm.m00.product_s1!==0||en.pa.impl.ws_a.bank_even[0]!==0)$fatal(1,"basemul/add retained state not scrubbed");
  checks=checks+42;
  // Repeated scrub must be accepted and complete exactly as a scrub operation.
  sk=0;se=0;sd=0;zk=1;ze=1;zd=1;tick;zk=0;ze=0;zd=0;
  while(!(sk&&se&&sd))begin tick;if(kd)sk=1;if(ed)se=1;if(dd)sd=1;end checks=checks+3;
  // A normal command may begin only after scrub completion; zeroize then aborts it without normal output/done.
  if(!kg_ready||!en_ready||!de_ready)$fatal(1,"clean restart not ready");
  ck=1;ce=1;cd=1;tick;ck=0;ce=0;cd=0;tick;
  if(kg_ready||en_ready||de_ready)$fatal(1,"command did not enter input state");
  zk=1;ze=1;zd=1;tick;zk=0;ze=0;zd=0;sk=0;se=0;sd=0;
  while(!(sk&&se&&sd))begin tick;if(kg_out||en_out||de_out)$fatal(1,"output leaked during abort scrub");if(kd)sk=1;if(ed)se=1;if(dd)sd=1;end
  if(normal_done_seen)$fatal(1,"normal done pulsed during zeroize");checks=checks+6;
  // Reset interrupts completion but retains payload; the following explicit scrub must restart at address zero.
  en.m[31]=8'h5a;ze=1;tick;ze=0;repeat(8)tick;rst_n=0;tick;
  if(en.m[31]!==8'h5a||ed||eb)$fatal(1,"reset incorrectly erased payload or completed scrub");
  rst_n=1;tick;ze=1;tick;ze=0;while(!ed)tick;if(en.m[31]!==0)$fatal(1,"restart scrub failed");checks=checks+3;
  $display("PASS m7_controller_zeroize checks=%0d local_locations=21408 representative_child_locations=16 child_acknowledgements=26 protocol_checks=12 repeated=PASS active_abort=PASS reset_interrupt=PASS clean_restart=PASS",checks);$finish;
 end
 initial begin #1000000;$fatal(1,"timeout");end
endmodule
