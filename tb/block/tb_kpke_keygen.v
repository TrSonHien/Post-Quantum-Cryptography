`timescale 1ns/1ps
module tb_kpke_keygen;
 reg clk=0,rst_n=0,cmd_valid=0,in_valid=0,out_ready=1;reg[31:0]in_data;reg[3:0]in_keep;reg in_last;
 wire cmd_ready,in_ready,out_valid;wire[31:0]out_data;wire[3:0]out_keep;wire out_last,out_type,busy,done,error;
 wire[31:0]cycle_count;wire[3:0]g_operations,sample_ntt_operations,noise_operations,polyvec_ntt_operations,dot_operations,poly_add_operations;
 reg[255:0]d_seed,exp_rho,exp_sigma;reg[11:0]exp_s[0:767],exp_e[0:767],exp_sh[0:767],exp_eh[0:767],exp_th[0:767];reg[7:0]exp_ek[0:1183],exp_dk[0:1151];
 integer fd,rc,v,i,w,got_bytes,checks=0,byte_checks=0,coeff_checks=0,cycles,max_vectors=20,stall_cycle=0;string file;
 reg held;reg[31:0]hd;reg[3:0]hk;reg hl,ht;
 always#5 clk=~clk;
 kpke_keygen dut(clk,rst_n,cmd_valid,cmd_ready,in_valid,in_ready,in_data,in_keep,in_last,out_valid,out_ready,out_data,out_keep,out_last,out_type,busy,done,error,cycle_count,g_operations,sample_ntt_operations,noise_operations,polyvec_ntt_operations,dot_operations,poly_add_operations);

 task read_vector;begin
  rc=$fscanf(fd,"%h %h %h\n",d_seed,exp_rho,exp_sigma);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp_s[i]);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp_e[i]);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp_sh[i]);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp_eh[i]);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp_th[i]);
  for(i=0;i<1184;i=i+1)rc=$fscanf(fd,"%h",exp_ek[i]);
  for(i=0;i<1152;i=i+1)rc=$fscanf(fd,"%h",exp_dk[i]);
 end endtask

 task run_vector;begin
  @(negedge clk);cmd_valid=1;@(negedge clk);cmd_valid=0;
  for(w=0;w<8;w=w+1)begin while(!in_ready)@(negedge clk);in_valid=1;in_data=d_seed[w*32+:32];in_keep=4'hf;in_last=(w==7);@(negedge clk);in_valid=0;end
  got_bytes=0;cycles=0;while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>120000)$fatal(1,"watchdog v=%0d state=%0d row=%0d elem=%0d idx=%0d child base=%b ntt=%b mat=%b add=%b enc=%b",v,dut.state,dut.row,dut.elem,dut.idx,dut.base_busy,dut.ntt_busy,dut.mat_busy,dut.add_busy,dut.enc_busy);end
  if(error||got_bytes!=2336)$fatal(1,"status v=%0d state=%0d bytes=%0d error=%b",v,dut.state,got_bytes,error);
  if(g_operations!=1||sample_ntt_operations!=9||noise_operations!=6||polyvec_ntt_operations!=2||dot_operations!=3||poly_add_operations!=3)$fatal(1,"counts g=%0d mat=%0d noise=%0d ntt=%0d dot=%0d add=%0d",g_operations,sample_ntt_operations,noise_operations,polyvec_ntt_operations,dot_operations,poly_add_operations);
  for(i=0;i<32;i=i+1)begin if(dut.rho[i]!==exp_rho[i*8+:8]||dut.sigma[i]!==exp_sigma[i*8+:8])$fatal(1,"G v=%0d byte=%0d rho=%02x/%02x sigma=%02x/%02x",v,i,dut.rho[i],exp_rho[i*8+:8],dut.sigma[i],exp_sigma[i*8+:8]);byte_checks=byte_checks+2;end
  for(i=0;i<768;i=i+1)begin
   if(dut.s[i]!==exp_s[i])$fatal(1,"s v=%0d p=%0d i=%0d exp=%0d got=%0d",v,i/256,i%256,exp_s[i],dut.s[i]);
   if(dut.e[i]!==exp_e[i])$fatal(1,"e v=%0d p=%0d i=%0d exp=%0d got=%0d",v,i/256,i%256,exp_e[i],dut.e[i]);
   if(dut.s_hat[i]!==exp_sh[i])$fatal(1,"s_hat v=%0d p=%0d i=%0d exp=%0d got=%0d",v,i/256,i%256,exp_sh[i],dut.s_hat[i]);
   if(dut.e_hat[i]!==exp_eh[i])$fatal(1,"e_hat v=%0d p=%0d i=%0d exp=%0d got=%0d",v,i/256,i%256,exp_eh[i],dut.e_hat[i]);
   if(dut.t_hat[i]!==exp_th[i])$fatal(1,"t_hat v=%0d p=%0d i=%0d exp=%0d got=%0d",v,i/256,i%256,exp_th[i],dut.t_hat[i]);coeff_checks=coeff_checks+5;
  end
  checks=checks+1;$display("KEYGEN_VECTOR_PASS id=%0d cycles=%0d",v,cycle_count);
 end endtask

 initial begin
  if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");void'($value$plusargs("VECTORS=%d",max_vectors));fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<max_vectors;v=v+1)begin read_vector();run_vector();end
  $display("PASS tb_kpke_keygen vectors=%0d coefficient_comparisons=%0d byte_comparisons=%0d final_bytes=%0d last_cycles=%0d operation_counts=PASS backpressure=PASS",checks,coeff_checks,byte_checks+max_vectors*2336,max_vectors*2336,cycle_count);$finish;
 end
 always@(negedge clk)if(rst_n)begin stall_cycle=stall_cycle+1;out_ready=(stall_cycle%13)!=6;end
 always@(posedge clk)if(!rst_n)held<=0;else begin
  if(held&&(!out_valid||out_data!==hd||out_keep!==hk||out_last!==hl||out_type!==ht))$fatal(1,"output changed while stalled");held=out_valid&&!out_ready;if(out_valid&&!out_ready)begin hd=out_data;hk=out_keep;hl=out_last;ht=out_type;end
  if(out_valid&&out_ready)begin
   if(out_keep!=4'hf||out_type!==(got_bytes>=1184)||out_last!==((got_bytes==1180)||(got_bytes==2332)))$fatal(1,"metadata v=%0d off=%0d type=%b last=%b",v,got_bytes,out_type,out_last);
   for(i=0;i<4;i=i+1)begin if(got_bytes+i<1184)begin if(out_data[i*8+:8]!==exp_ek[got_bytes+i])begin $display("DEBUG state=%0d enc_word=%0d t252=%h t253=%h t254=%h t255=%h dot252=%h dot253=%h dot254=%h dot255=%h eh254=%h eh255=%h e766=%h e767=%h sh766=%h sh767=%h s766=%h s767=%h",dut.state,dut.enc_word,dut.t_hat[252],dut.t_hat[253],dut.t_hat[254],dut.t_hat[255],dut.dot[252],dut.dot[253],dut.dot[254],dut.dot[255],dut.e_hat[254],dut.e_hat[255],dut.e[766],dut.e[767],dut.s_hat[766],dut.s_hat[767],dut.s[766],dut.s[767]);$fatal(1,"ek v=%0d byte=%0d exp=%02x got=%02x",v,got_bytes+i,exp_ek[got_bytes+i],out_data[i*8+:8]);end end else if(out_data[i*8+:8]!==exp_dk[got_bytes+i-1184])$fatal(1,"dk v=%0d byte=%0d exp=%02x got=%02x",v,got_bytes+i-1184,exp_dk[got_bytes+i-1184],out_data[i*8+:8]);end got_bytes=got_bytes+4;
  end
 end
endmodule
