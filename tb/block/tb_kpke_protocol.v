`timescale 1ns/1ps
module tb_kpke_protocol;
 reg clk=0,rst_n=0;always#5 clk=~clk;localparam PK=1,PE=2,PD=3;integer phase=0;wire kg_clk=(!rst_n||phase==PK)?clk:0,en_clk=(!rst_n||phase==PE)?clk:0,de_clk=(!rst_n||phase==PD)?clk:0;
 reg kg_cmd=0,kg_iv=0,kg_or=1;reg[31:0]kg_id;reg[3:0]kg_ik=15;reg kg_il;wire kg_cr,kg_ir,kg_ov;wire[31:0]kg_od;wire[3:0]kg_ok;wire kg_ol,kg_ot,kg_busy,kg_done,kg_err;wire[31:0]kg_cyc;wire[3:0]kg1,kg2,kg3,kg4,kg5,kg6;
 reg en_cmd=0,en_iv=0,en_or=1;reg[31:0]en_id;reg[3:0]en_ik=15;reg en_il;wire en_cr,en_ir,en_ov;wire[31:0]en_od;wire[3:0]en_ok;wire en_ol,en_busy,en_done,en_err,en_nc;wire[31:0]en_cyc;wire[3:0]en1,en2,en3,en4,en5,en6,en7;
 reg de_cmd=0,de_iv=0,de_or=1;reg[31:0]de_id;reg[3:0]de_ik=15;reg de_il;wire de_cr,de_ir,de_ov;wire[31:0]de_od;wire[3:0]de_ok;wire de_ol,de_busy,de_done,de_err,de_nc;wire[31:0]de_cyc;wire[3:0]de1,de2,de3,de4,de5;
 reg[255:0]d,m,r;reg[7:0]ek[0:1183],dk[0:1151],c[0:1087];integer fd,rc,i,x,watch,checks=0;string file;
 kpke_keygen kg(kg_clk,rst_n,kg_cmd,kg_cr,kg_iv,kg_ir,kg_id,kg_ik,kg_il,kg_ov,kg_or,kg_od,kg_ok,kg_ol,kg_ot,kg_busy,kg_done,kg_err,kg_cyc,kg1,kg2,kg3,kg4,kg5,kg6);
 kpke_encrypt en(en_clk,rst_n,en_cmd,en_cr,en_iv,en_ir,en_id,en_ik,en_il,en_ov,en_or,en_od,en_ok,en_ol,en_busy,en_done,en_err,en_nc,en_cyc,en1,en2,en3,en4,en5,en6,en7);
 kpke_decrypt de(de_clk,rst_n,de_cmd,de_cr,de_iv,de_ir,de_id,de_ik,de_il,de_ov,de_or,de_od,de_ok,de_ol,de_busy,de_done,de_err,de_nc,de_cyc,de1,de2,de3,de4,de5);
 task feed_kg;begin for(x=0;x<8;x=x+1)begin kg_iv=1;kg_id=d[x*32+:32];kg_ik=15;kg_il=x==7;@(negedge clk);end kg_iv=0;end endtask
 task feed_en;begin for(x=0;x<312;x=x+1)begin en_iv=1;if(x<296)en_id={ek[x*4+3],ek[x*4+2],ek[x*4+1],ek[x*4]};else if(x<304)en_id=m[(x-296)*32+:32];else en_id=r[(x-304)*32+:32];en_ik=15;en_il=x==311;@(negedge clk);end en_iv=0;end endtask
 task feed_de;begin for(x=0;x<560;x=x+1)begin de_iv=1;if(x<288)de_id={dk[x*4+3],dk[x*4+2],dk[x*4+1],dk[x*4]};else de_id={c[(x-288)*4+3],c[(x-288)*4+2],c[(x-288)*4+1],c[(x-288)*4]};de_ik=15;de_il=x==559;@(negedge clk);end de_iv=0;end endtask
 task reset_kg;input integer target;begin phase=PK;kg_or=target==35?0:1;@(negedge clk);kg_cmd=1;@(negedge clk);kg_cmd=0;if(target!=1)feed_kg();watch=0;while(kg.state!=target&&watch<100000)begin@(negedge clk);watch=watch+1;end if(watch>=100000)$fatal(1,"kg reset target %0d",target);repeat(3)@(negedge clk);rst_n=0;@(negedge clk);if(kg_busy||kg_done||kg_ov||kg_err)$fatal(1,"kg reset status target=%0d",target);rst_n=1;kg_or=1;checks=checks+1;end endtask
 task reset_en;input integer target;begin phase=PE;en_or=target==50?0:1;@(negedge clk);en_cmd=1;@(negedge clk);en_cmd=0;if(target!=1)feed_en();watch=0;while(en.state!=target&&watch<150000)begin@(negedge clk);watch=watch+1;end if(watch>=150000)$fatal(1,"en reset target %0d",target);repeat(3)@(negedge clk);rst_n=0;@(negedge clk);if(en_busy||en_done||en_ov||en_err)$fatal(1,"en reset status target=%0d",target);rst_n=1;en_or=1;checks=checks+1;end endtask
 task reset_de;input integer target;begin phase=PD;de_or=target==42?0:1;@(negedge clk);de_cmd=1;@(negedge clk);de_cmd=0;if(target!=1)feed_de();watch=0;while(de.state!=target&&watch<70000)begin@(negedge clk);watch=watch+1;end if(watch>=70000)$fatal(1,"de reset target %0d",target);repeat(3)@(negedge clk);rst_n=0;@(negedge clk);if(de_busy||de_done||de_ov||de_err)$fatal(1,"de reset status target=%0d",target);rst_n=1;de_or=1;checks=checks+1;end endtask
 task complete_kg;begin phase=PK;@(negedge clk);kg_cmd=1;@(negedge clk);kg_cmd=0;feed_kg();watch=0;while(!kg_done&&watch<100000)begin@(negedge clk);watch=watch+1;end if(!kg_done||kg_err)$fatal(1,"kg restart");checks=checks+1;end endtask
 task complete_en;begin phase=PE;@(negedge clk);en_cmd=1;@(negedge clk);en_cmd=0;feed_en();watch=0;while(!en_done&&watch<150000)begin@(negedge clk);watch=watch+1;end if(!en_done||en_err)$fatal(1,"en restart");checks=checks+1;end endtask
 task complete_de;begin phase=PD;@(negedge clk);de_cmd=1;@(negedge clk);de_cmd=0;feed_de();watch=0;while(!de_done&&watch<70000)begin@(negedge clk);watch=watch+1;end if(!de_done||de_err)$fatal(1,"de restart");checks=checks+1;end endtask
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");rc=$fscanf(fd,"%h %h %h\n",d,m,r);for(i=0;i<1184;i=i+1)rc=$fscanf(fd,"%h",ek[i]);for(i=0;i<1152;i=i+1)rc=$fscanf(fd,"%h",dk[i]);for(i=0;i<1088;i=i+1)rc=$fscanf(fd,"%h",c[i]);repeat(3)@(negedge clk);rst_n=1;
  // Input, hash/decode, sampler, transform, dot, INTT/add/sub, codec, and stalled output.
  reset_kg(1);reset_kg(4);reset_kg(6);reset_kg(12);reset_kg(17);reset_kg(21);reset_kg(28);reset_kg(34);reset_kg(35);complete_kg();
  reset_en(1);reset_en(4);reset_en(6);reset_en(14);reset_en(19);reset_en(23);reset_en(30);reset_en(37);reset_en(43);reset_en(46);reset_en(50);complete_en();
  reset_de(1);reset_de(4);reset_de(10);reset_de(14);reset_de(20);reset_de(27);reset_de(35);reset_de(41);reset_de(42);complete_de();
  // Malformed keep plus command-while-busy for all modes.
  phase=PK;@(negedge clk);kg_cmd=1;@(negedge clk);kg_cmd=0;kg_iv=1;kg_id=0;kg_ik=4'b0101;kg_il=1;@(negedge clk);kg_iv=0;if(!kg_err||kg_busy)$fatal(1,"kg malformed");rst_n=0;@(negedge clk);rst_n=1;
  phase=PE;@(negedge clk);en_cmd=1;@(negedge clk);en_cmd=0;en_cmd=1;@(negedge clk);en_cmd=0;if(!en_err)$fatal(1,"en cmd busy");rst_n=0;@(negedge clk);rst_n=1;
  phase=PD;@(negedge clk);de_cmd=1;@(negedge clk);de_cmd=0;de_iv=1;de_id=0;de_ik=4'b0011;de_il=1;@(negedge clk);de_iv=0;if(!de_err||de_busy)$fatal(1,"de malformed");checks=checks+3;
  $display("PASS tb_kpke_protocol checks=%0d reset_input=PASS reset_hash_decode=PASS reset_sampler=PASS reset_ntt=PASS reset_dot=PASS reset_intt=PASS reset_add_sub=PASS reset_codec=PASS reset_stalled_output=PASS clean_restart=PASS malformed=PASS command_busy=PASS",checks);$finish;end
endmodule
