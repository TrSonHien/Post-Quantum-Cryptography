`timescale 1ns/1ps
module tb_mlkem_ek_check;
 reg clk=0,rst_n=0,start=0,in_valid=0,in_last=0,read_req=0,zeroize=0;reg[31:0]in_data=0;reg[3:0]in_keep=0;reg[10:0]read_addr=0;
 wire busy,in_ready,done,error,checked_key_valid,noncanonical_seen,read_valid,zeroize_busy,zeroize_done;wire[9:0]coefficients_scanned;wire[7:0]read_data;
 reg[7:0]vec[0:1183];integer i,cycles,reference_cycles=-1,cases=0;
 mlkem_ek_check dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task set_raw(input integer idx,input integer val);integer b;begin b=(idx/2)*3;if((idx&1)==0)begin vec[b]=val[7:0];vec[b+1]=(vec[b+1]&8'hf0)|((val>>8)&8'h0f);end else begin vec[b+1]=(vec[b+1]&8'h0f)|((val&8'h0f)<<4);vec[b+2]=(val>>4)&8'hff;end end endtask
 task init_valid;begin for(i=0;i<1184;i=i+1)vec[i]=0;for(i=0;i<768;i=i+1)set_raw(i,(i*37)%3329);for(i=1152;i<1184;i=i+1)vec[i]=i^8'ha5;end endtask
 task run_case(input exp_valid,input integer mode);integer w;begin start=1;tick;start=0;for(w=0;w<296;w=w+1)begin in_data={vec[w*4+3],vec[w*4+2],vec[w*4+1],vec[w*4]};in_keep=4'hf;in_last=w==295;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end cycles=0;while(!done)begin tick;cycles=cycles+1;end if(checked_key_valid!==exp_valid||coefficients_scanned!=768||error)begin $display("FAIL mode=%0d valid=%b scan=%0d err=%b",mode,checked_key_valid,coefficients_scanned,error);$fatal;end if(reference_cycles<0)reference_cycles=cycles;else if(cycles!=reference_cycles)begin $display("FAIL variable scan cycles=%0d ref=%0d",cycles,reference_cycles);$fatal;end cases=cases+1;tick;end endtask
 initial begin repeat(2)tick;rst_n=1;tick;
  init_valid;run_case(1,0);init_valid;set_raw(0,3329);run_case(0,1);init_valid;set_raw(384,3330);run_case(0,2);init_valid;set_raw(767,4095);run_case(0,3);init_valid;set_raw(0,3329);set_raw(300,3330);set_raw(767,4095);run_case(0,4);
  init_valid;vec[1183]=vec[1183]^8'hff;run_case(1,5);
  zeroize=1;tick;zeroize=0;while(!zeroize_done)tick;for(i=0;i<1184;i=i+1)if(dut.ek[i]!==0)$fatal;
  // malformed final keep/last
  start=1;tick;start=0;in_data=0;in_keep=4'h7;in_last=1;in_valid=1;tick;in_valid=0;if(!done||!error||checked_key_valid)$fatal;
  $display("PASS cases=%0d coefficients_per_case=768 scan_cycles=%0d scrub_bytes=1184",cases,reference_cycles);$finish;
 end
 initial begin #200000000;$display("FAIL timeout");$fatal;end
endmodule
