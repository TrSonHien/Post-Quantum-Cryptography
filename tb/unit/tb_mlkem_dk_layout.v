`timescale 1ns/1ps
module tb_mlkem_dk_layout;
 reg clk=0,rst_n=0,load_start=0,in_valid=0,in_last=0,output_start=0,out_ready=0,zeroize=0;
 reg[1:0]in_kind=0;reg[7:0]in_data=0;
 wire in_ready,complete,error,out_valid,out_last,done,zeroize_busy,zeroize_done;wire[7:0]out_data;wire[11:0]out_addr;
 reg p_load_start=0,p_in_valid=0,p_in_last=0,p_read_req=0,p_zeroize=0;reg[7:0]p_in_data=0;reg[11:0]p_read_addr=0;
 wire p_in_ready,p_complete,p_error,p_read_valid,p_zeroize_busy,p_zeroize_done;wire[7:0]p_read_data;wire[1:0]p_read_kind;wire[10:0]p_read_offset;
 integer i,checks=0,seed;
 mlkem_dk_assemble a(clk,rst_n,load_start,in_valid,in_ready,in_kind,in_data,in_last,complete,error,output_start,out_valid,out_ready,out_data,out_addr,out_last,done,zeroize,zeroize_busy,zeroize_done);
 mlkem_dk_parse p(clk,rst_n,p_load_start,p_in_valid,p_in_ready,p_in_data,p_in_last,p_complete,p_error,p_read_req,p_read_addr,p_read_valid,p_read_data,p_read_kind,p_read_offset,p_zeroize,p_zeroize_busy,p_zeroize_done);
 always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 function[7:0]expected(input integer a);begin expected=(a*73+19)^(a>>3);end endfunction
 task send_component(input[1:0]k,input integer n,input integer base);integer x;begin for(x=0;x<n;x=x+1)begin in_kind=k;in_data=expected(base+x);in_last=x==n-1;in_valid=1;while(!in_ready)tick;tick;in_valid=0;if((x%19)==0)tick;end end endtask
 task parse_read(input integer a);reg[1:0]ekind;integer off;begin p_read_addr=a;p_read_req=1;tick;p_read_req=0;if(a<1152)begin ekind=0;off=a;end else if(a<2336)begin ekind=1;off=a-1152;end else if(a<2368)begin ekind=2;off=a-2336;end else begin ekind=3;off=a-2368;end if(!p_read_valid||p_read_data!==expected(a)||p_read_kind!==ekind||p_read_offset!==off)begin $display("FAIL parse addr=%0d data=%02x kind=%0d off=%0d",a,p_read_data,p_read_kind,p_read_offset);$fatal;end checks=checks+1;end endtask
 initial begin seed=32'h8a31;repeat(2)tick;rst_n=1;tick;load_start=1;tick;load_start=0;
  send_component(0,1152,0);send_component(1,1184,1152);send_component(2,32,2336);send_component(3,32,2368);if(!complete||error)$fatal;
  p_load_start=1;tick;p_load_start=0;output_start=1;tick;output_start=0;
  while(!done)begin out_ready=(($random(seed)&3)!=0);p_in_valid=out_valid&&out_ready;p_in_data=out_data;p_in_last=out_last;tick;if(out_valid&&out_ready)begin if(out_data!==expected(out_addr))$fatal;checks=checks+1;end end p_in_valid=0;out_ready=0;tick;if(!p_complete||p_error)$fatal;
  for(i=0;i<2400;i=i+1)parse_read(i);
  zeroize=1;p_zeroize=1;tick;zeroize=0;p_zeroize=0;while(!zeroize_done||!p_zeroize_done)tick;
  for(i=0;i<1152;i=i+1)if(a.dkpke[i]!==0)$fatal;for(i=0;i<1184;i=i+1)if(a.ek[i]!==0)$fatal;for(i=0;i<32;i=i+1)if(a.h[i]!==0||a.z[i]!==0)$fatal;for(i=0;i<2400;i=i+1)if(p.dk[i]!==0)$fatal;
  $display("PASS checks=%0d layout_bytes=2400 scrub_bytes=4800",checks);$finish;
 end
 initial begin #200000000;$display("FAIL timeout");$fatal;end
endmodule
