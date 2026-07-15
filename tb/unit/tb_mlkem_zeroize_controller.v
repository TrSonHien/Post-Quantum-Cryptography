`timescale 1ns/1ps
module tb_mlkem_zeroize_controller;
 reg clk=0,rst_n=0,start=0;reg[3:0]client_done=0;wire busy,done,error,clear_secret_scalars;wire[3:0]client_start;integer checks=0;
 mlkem_zeroize_controller #(.CLIENTS(4))dut(.*);always #5 clk=~clk;task tick;begin @(posedge clk);#1;end endtask
 initial begin repeat(2)tick;rst_n=1;tick;start=1;tick;start=0;if(!busy||client_start!=4'hf||!clear_secret_scalars)$fatal;checks=checks+3;
  client_done=4'b0010;tick;client_done=0;repeat(3)tick;if(done)$fatal;client_done=4'b1001;tick;client_done=0;if(done)$fatal;client_done=4'b0100;tick;client_done=0;if(!done||busy)$fatal;checks=checks+4;
  tick;start=1;tick;start=0;repeat(2)tick;rst_n=0;tick;rst_n=1;tick;if(busy||done)$fatal;checks=checks+2;
  start=1;tick;start=0;client_done=4'hf;tick;client_done=0;if(!done)$fatal;checks=checks+1;
  $display("PASS checks=%0d clients=4",checks);$finish;end
 initial begin #100000;$fatal;end
endmodule
