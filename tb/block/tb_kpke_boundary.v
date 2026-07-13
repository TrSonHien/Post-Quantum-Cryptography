`timescale 1ns/1ps
module tb_kpke_boundary;
 reg clk=0,rst_n=0;always#5 clk=~clk;integer phase=0;localparam PE=1,PD=2;
 wire en_clk=(!rst_n||phase==PE)?clk:0,de_clk=(!rst_n||phase==PD)?clk:0;
 reg en_cmd=0,en_iv=0,en_or=1;reg[31:0]en_id;reg[3:0]en_ik=15;reg en_il;wire en_cr,en_ir,en_ov;wire[31:0]en_od;wire[3:0]en_ok;wire en_ol,en_busy,en_done,en_err,en_nc;wire[31:0]en_cyc;wire[3:0]en1,en2,en3,en4,en5,en6,en7;
 reg de_cmd=0,de_iv=0,de_or=1;reg[31:0]de_id;reg[3:0]de_ik=15;reg de_il;wire de_cr,de_ir,de_ov;wire[31:0]de_od;wire[3:0]de_ok;wire de_ol,de_busy,de_done,de_err,de_nc;wire[31:0]de_cyc;wire[3:0]de1,de2,de3,de4,de5;
 reg[7:0]ek[0:1183],dk[0:1151],c[0:1087],expected_c[0:1087];reg[255:0]m,r,expected_m;
 integer fd,rc,i,x,got,watch,checks=0,byte_checks=0;string file;
 kpke_encrypt en(en_clk,rst_n,en_cmd,en_cr,en_iv,en_ir,en_id,en_ik,en_il,en_ov,en_or,en_od,en_ok,en_ol,en_busy,en_done,en_err,en_nc,en_cyc,en1,en2,en3,en4,en5,en6,en7);
 kpke_decrypt de(de_clk,rst_n,de_cmd,de_cr,de_iv,de_ir,de_id,de_ik,de_il,de_ov,de_or,de_od,de_ok,de_ol,de_busy,de_done,de_err,de_nc,de_cyc,de1,de2,de3,de4,de5);
 always@(posedge clk)if(en_ov&&en_or)begin
  if(en_od[7:0]!==expected_c[got]||en_od[15:8]!==expected_c[got+1]||en_od[23:16]!==expected_c[got+2]||en_od[31:24]!==expected_c[got+3])$fatal(1,"encrypt boundary byte=%0d",got);
  got<=got+4;byte_checks<=byte_checks+4;
 end
 always@(posedge clk)if(de_ov&&de_or)begin
  if(de_od!==expected_m[got*8+:32])$fatal(1,"decrypt boundary byte=%0d expected=%h observed=%h",got,expected_m[got*8+:32],de_od);
  got<=got+4;byte_checks<=byte_checks+4;
 end
 task reset_for;input integer next_phase;begin phase=next_phase;rst_n=0;repeat(2)@(negedge clk);rst_n=1;end endtask
 task run_encrypt;begin
  reset_for(PE);got=0;@(negedge clk);en_cmd=1;@(negedge clk);en_cmd=0;
  for(x=0;x<312;x=x+1)begin while(!en_ir)@(negedge clk);if(x<296)en_id={ek[x*4+3],ek[x*4+2],ek[x*4+1],ek[x*4]};else if(x<304)en_id=m[(x-296)*32+:32];else en_id=r[(x-304)*32+:32];en_iv=1;en_il=x==311;@(negedge clk);en_iv=0;end
  watch=0;while(!en_done&&watch<150000)begin@(negedge clk);watch=watch+1;end
  if(!en_done||en_err||!en_nc||got!=1088)$fatal(1,"encrypt boundary status done=%b error=%b nc=%b bytes=%0d",en_done,en_err,en_nc,got);checks=checks+1;
 end endtask
 task run_decrypt;input integer expect_nc;begin
  reset_for(PD);got=0;@(negedge clk);de_cmd=1;@(negedge clk);de_cmd=0;
  for(x=0;x<560;x=x+1)begin while(!de_ir)@(negedge clk);if(x<288)de_id={dk[x*4+3],dk[x*4+2],dk[x*4+1],dk[x*4]};else de_id={c[(x-288)*4+3],c[(x-288)*4+2],c[(x-288)*4+1],c[(x-288)*4]};de_iv=1;de_il=x==559;@(negedge clk);de_iv=0;end
  watch=0;while(!de_done&&watch<70000)begin@(negedge clk);watch=watch+1;end
  if(!de_done||de_err||de_nc!==expect_nc[0]||got!=32)$fatal(1,"decrypt boundary status done=%b error=%b nc=%b expected_nc=%0d bytes=%0d",de_done,de_err,de_nc,expect_nc,got);checks=checks+1;
 end endtask
 initial begin
  if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");
  for(i=0;i<1184;i=i+1)rc=$fscanf(fd,"%h",ek[i]);rc=$fscanf(fd,"%h %h\n",m,r);for(i=0;i<1088;i=i+1)rc=$fscanf(fd,"%h",expected_c[i]);run_encrypt();
  for(i=0;i<1152;i=i+1)rc=$fscanf(fd,"%h",dk[i]);for(i=0;i<1088;i=i+1)rc=$fscanf(fd,"%h",c[i]);rc=$fscanf(fd,"%h\n",expected_m);run_decrypt(1);
  for(i=0;i<1152;i=i+1)rc=$fscanf(fd,"%h",dk[i]);for(i=0;i<1088;i=i+1)rc=$fscanf(fd,"%h",c[i]);rc=$fscanf(fd,"%h\n",expected_m);run_decrypt(0);
  $display("PASS tb_kpke_boundary checks=%0d byte_comparisons=%0d noncanonical_encrypt=PASS noncanonical_decrypt=PASS arbitrary_ciphertext=PASS",checks,byte_checks);$finish;
 end
endmodule
