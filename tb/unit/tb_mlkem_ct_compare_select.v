`timescale 1ns/1ps
module tb_mlkem_ct_compare_select;
 reg clk=0,rst_n=0,load_start=0,in_valid=0,in_last=0,start=0,out_ready=0,zeroize=0;reg[1:0]in_kind=0;reg[7:0]in_data=0;
 wire in_ready,busy,done,error,out_valid,out_last,zeroize_busy,zeroize_done;wire[7:0]out_data;wire[10:0]compare_count;wire[5:0]select_count;
 reg[7:0]cv[0:1087],cpv[0:1087],kpv[0:31],kbv[0:31];integer i,cycles,refcycles=-1,cases=0,checks=0;
 mlkem_ct_compare_select dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 task send_record(input[1:0]k,input integer n);integer x;begin for(x=0;x<n;x=x+1)begin in_kind=k;case(k)0:in_data=cv[x];1:in_data=cpv[x];2:in_data=kpv[x];default:in_data=kbv[x];endcase in_last=x==n-1;in_valid=1;while(!in_ready)tick;tick;in_valid=0;end end endtask
 task run_case(input reject,input integer mode);integer oi,stall_cycle;reg[7:0]exp;begin load_start=1;tick;load_start=0;send_record(0,1088);send_record(1,1088);send_record(2,32);send_record(3,32);start=1;tick;start=0;cycles=0;while(!out_valid)begin tick;cycles=cycles+1;end if(compare_count!=1088||select_count!=32||dut.mismatch_acc!==0||dut.reject_mask!==0)$fatal;if(refcycles<0)refcycles=cycles;else if(cycles!=refcycles)begin $display("FAIL cycles mode=%0d got=%0d ref=%0d",mode,cycles,refcycles);$fatal;end oi=0;stall_cycle=0;while(!done)begin out_ready=(stall_cycle%5)!=2;if(out_valid&&out_ready)begin exp=reject?kbv[oi]:kpv[oi];if(out_data!==exp)begin $display("FAIL K mode=%0d idx=%0d exp=%02x got=%02x",mode,oi,exp,out_data);$fatal;end oi=oi+1;checks=checks+1;end tick;stall_cycle=stall_cycle+1;end out_ready=0;if(oi!=32)$fatal;for(i=0;i<1088;i=i+1)if(dut.c[i]!==0||dut.cp[i]!==0)$fatal;for(i=0;i<32;i=i+1)if(dut.kp[i]!==0||dut.kb[i]!==0||dut.kout[i]!==0)$fatal;cases=cases+1;tick;end endtask
 task init_equal;begin for(i=0;i<1088;i=i+1)begin cv[i]=(i*29+7);cpv[i]=cv[i];end for(i=0;i<32;i=i+1)begin kpv[i]=i+8'h20;kbv[i]=i+8'hc0;end end endtask
 initial begin repeat(2)tick;rst_n=1;tick;init_equal;run_case(0,0);init_equal;cpv[0]^=1;run_case(1,1);init_equal;cpv[544]^=8'h80;run_case(1,2);init_equal;cpv[1087]^=1;run_case(1,3);init_equal;for(i=0;i<1088;i=i+1)cpv[i]=~cpv[i];run_case(1,4);
  // reset during compare, then clean restart
  init_equal;load_start=1;tick;load_start=0;send_record(0,1088);send_record(1,1088);send_record(2,32);send_record(3,32);start=1;tick;start=0;repeat(100)tick;rst_n=0;tick;rst_n=1;tick;if(busy||done||dut.mismatch_acc)$fatal;init_equal;run_case(0,5);
  $display("PASS cases=%0d K_byte_checks=%0d compare_cycles=1088 select_cycles=32 fixed_preoutput_cycles=%0d",cases,checks,refcycles);$finish;
 end
 initial begin #1000000000;$display("FAIL timeout");$fatal;end
endmodule
