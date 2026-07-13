`timescale 1ns/1ps
module tb_bits_bytes_pipe;
 reg clk=0,rst_n=0,iv=0,ready=1;reg[7:0]din;wire ir1,ov1,ir2,ov2;wire[7:0]byte_o,bits_o;
 integer i,checks=0,cycle=0;always#5 clk=~clk;
 bits_to_bytes_pipe a(clk,rst_n,iv,ir1,din,ov1,ir2,byte_o);
 bytes_to_bits_pipe b(clk,rst_n,ov1,ir2,byte_o,ov2,ready,bits_o);
 initial begin repeat(3)@(negedge clk);rst_n=1;
  for(i=0;i<256;i=i+1)begin iv=1;din=i;@(negedge clk);while(!ir1)@(negedge clk);end
  iv=0;repeat(12)@(negedge clk);
  if(checks!=256)$fatal(1,"count %0d",checks);
  @(negedge clk);iv=1;din=8'ha5;@(negedge clk);rst_n=0;iv=0;
  @(negedge clk);if(ov1||ov2)$fatal(1,"stale valid");rst_n=1;
  $display("PASS tb_bits_bytes_pipe checks=%0d latency_each=1 ii=1",checks);$finish;end
 always@(posedge clk)if(rst_n&&ov2&&ready)begin if(bits_o!==checks[7:0])$fatal(1,"idx=%0d exp=%02x got=%02x",checks,checks[7:0],bits_o);checks=checks+1;end
 always@(negedge clk)if(rst_n)begin cycle=cycle+1;ready=(cycle%7)!=2;end
endmodule
