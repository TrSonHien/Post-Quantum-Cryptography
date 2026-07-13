`timescale 1ns/1ps
module tb_kpke_noise_vector_sampler;
 reg clk=0,rst_n=0,start=0,out_ready=1;reg[255:0]seed;reg[7:0]start_nonce;reg[1:0]eta;
 wire busy,done,error,out_valid;wire[11:0]out_coeff;wire[7:0]out_index;wire[1:0]out_poly_index,out_domain;wire[7:0]active_nonce,next_nonce;wire[2:0]samples_started;
 integer fd,rc,v,e,i,got,checks=0,nonce_checks=0,cycles,starts,stall_cycle=0,reset_elem;reg[11:0]exp[0:767];string file;
 reg held;reg[11:0]hc;reg[7:0]hi;reg[1:0]hp;
 always#5 clk=~clk;
 kpke_noise_vector_sampler dut(clk,rst_n,start,seed,start_nonce,eta,busy,done,error,out_valid,out_ready,out_coeff,out_index,out_poly_index,out_domain,active_nonce,next_nonce,samples_started);
 task launch_and_check;begin @(negedge clk);start=1;@(negedge clk);start=0;got=0;cycles=0;starts=0;while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>8000)$fatal(1,"watchdog v=%0d state=%0d elem=%0d",v,dut.state,dut.element);end if(error||got!=768||samples_started!=3||starts!=3||next_nonce!==start_nonce+3)$fatal(1,"status v=%0d got=%0d samples=%0d starts=%0d next=%0d",v,got,samples_started,starts,next_nonce);end endtask
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<16;v=v+1)begin rc=$fscanf(fd,"%h %h %d\n",seed,start_nonce,eta);for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp[i]);launch_and_check();end
  rc=$fseek(fd,0,0);rc=$fscanf(fd,"%h %h %d\n",seed,start_nonce,eta);for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp[i]);
  @(negedge clk);start=1;@(negedge clk);start=0;got=0;repeat(20)@(negedge clk);start=1;@(negedge clk);start=0;while(!done)@(negedge clk);if(!error||got!=768)$fatal(1,"start busy");
  for(reset_elem=0;reset_elem<3;reset_elem=reset_elem+1)begin rst_n=0;@(negedge clk);rst_n=1;@(negedge clk);start=1;@(negedge clk);start=0;got=0;wait(dut.element==reset_elem&&dut.state==2);repeat(20)@(negedge clk);rst_n=0;@(negedge clk);if(busy||done||out_valid)$fatal(1,"reset");rst_n=1;launch_and_check();end
  $display("PASS tb_kpke_noise_vector_sampler vectors=16 coeff_checks=%0d nonce_checks=%0d reset_elements=3 start_busy=PASS backpressure=PASS",checks,nonce_checks);$finish;end
 always@(negedge clk)if(rst_n)begin stall_cycle=stall_cycle+1;out_ready=(stall_cycle%7)!=3;end
 always@(posedge clk)if(!rst_n)held<=0;else begin if(dut.child_start)begin starts=starts+1;if(active_nonce!==(start_nonce+dut.element))$fatal(1,"nonce elem=%0d exp=%0d got=%0d",dut.element,start_nonce+dut.element,active_nonce);nonce_checks=nonce_checks+1;end if(held&&(!out_valid||out_coeff!==hc||out_index!==hi||out_poly_index!==hp))$fatal(1,"stall");held=out_valid&&!out_ready;if(out_valid&&!out_ready)begin hc=out_coeff;hi=out_index;hp=out_poly_index;end if(out_valid&&out_ready)begin if(got>=768||out_poly_index!==got/256||out_index!==got%256||out_coeff!==exp[got]||out_domain!=1)$fatal(1,"coeff v=%0d elem=%0d idx=%0d exp=%0d got=%0d nonce=%0d eta=%0d",v,out_poly_index,out_index,exp[got],out_coeff,active_nonce,eta);got=got+1;checks=checks+1;end end
endmodule
