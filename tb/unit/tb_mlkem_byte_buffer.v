`timescale 1ns/1ps
module tb_mlkem_byte_buffer;
 reg clk=0,rst_n=0,load_start=0,load_valid=0,load_last=0,read_req=0,zeroize=0;
 reg[31:0]load_len_bytes=0,load_data=0;reg[3:0]load_keep=0;reg[5:0]read_addr=0;
 wire load_ready,complete,error,read_valid,zeroize_busy,zeroize_done;wire[7:0]read_data;
 integer i,checks=0,zero_checks=0;
 mlkem_byte_buffer #(.CAPACITY(64),.ADDR_W(6)) dut(.*);
 always #5 clk=~clk;
 task tick;begin @(posedge clk);#1;end endtask
 task start_load(input[31:0]n);begin load_len_bytes=n;load_start=1;tick;load_start=0;end endtask
 task send_word(input[31:0]d,input[3:0]k,input l);begin load_data=d;load_keep=k;load_last=l;load_valid=1;while(!load_ready)tick;tick;load_valid=0;end endtask
 task check_byte(input integer a,input[7:0]e);begin read_addr=a;read_req=1;tick;read_req=0;if(!read_valid||read_data!==e)begin $display("FAIL byte addr=%0d exp=%02x got=%02x",a,e,read_data);$fatal;end checks=checks+1;end endtask
 initial begin
  repeat(2)tick;rst_n=1;tick;
  start_load(64);for(i=0;i<16;i=i+1)send_word(i*32'h04040404+32'h03020100,4'hf,i==15);
  if(!complete||error)$fatal;for(i=0;i<64;i=i+1)check_byte(i,i[7:0]);
  rst_n=0;tick;rst_n=1;tick;if(complete)$fatal; // metadata invalidation only
  start_load(7);send_word(32'h44332211,4'hf,0);send_word(32'h00776655,4'h7,1);
  check_byte(0,8'h11);check_byte(1,8'h22);check_byte(2,8'h33);check_byte(3,8'h44);
  check_byte(4,8'h55);check_byte(5,8'h66);check_byte(6,8'h77);
  zeroize=1;tick;zeroize=0;while(!zeroize_done)tick;
  for(i=0;i<64;i=i+1)begin if(dut.mem[i]!==0)$fatal;zero_checks=zero_checks+1;end
  zeroize=1;tick;zeroize=0;repeat(8)tick;rst_n=0;tick;rst_n=1;tick;
  zeroize=1;tick;zeroize=0;while(!zeroize_done)tick;for(i=0;i<64;i=i+1)begin if(dut.mem[i]!==0)$fatal;zero_checks=zero_checks+1;end
  start_load(4);send_word(32'ha5a5a5a5,4'hf,1);check_byte(0,8'ha5);
  $display("PASS checks=%0d zeroize_checks=%0d",checks,zero_checks);$finish;
 end
 initial begin #200000;$display("FAIL timeout");$fatal;end
endmodule
