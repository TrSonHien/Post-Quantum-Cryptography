`timescale 1ns/1ps
module tb_mod_mul_normal_pipe;
 reg clk=0,rst_n=0,in_valid=0;reg[11:0]a,b;wire out_valid;wire[11:0]r;always#5 clk=~clk;
 mod_mul_normal_pipe dut(clk,rst_n,in_valid,a,b,out_valid,r);
 integer fd,rc,checks=0,issued=0,received=0,cycle=0,i;reg[11:0]x,y,e;reg[11:0]eq[0:15];reg vq[0:15];string file;
 initial begin
  if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE missing");fd=$fopen(file,"r");if(!fd)$fatal(1,"open");
  for(i=0;i<16;i=i+1)vq[i]=0;repeat(3)@(negedge clk);rst_n=1;
  while(!$feof(fd))begin
   rc=$fscanf(fd,"%h %h %h\n",x,y,e);
   if(rc==3)begin@(negedge clk);in_valid=1;a=x;b=y;eq[issued%16]=e;vq[issued%16]=1;issued=issued+1;end
  end
  @(negedge clk);in_valid=0;repeat(12)@(negedge clk);
  if(received!=issued)$fatal(1,"count issued=%0d received=%0d",issued,received);
  @(negedge clk);in_valid=1;a=123;b=456;repeat(2)@(negedge clk);rst_n=0;in_valid=0;
  @(negedge clk);if(out_valid)$fatal(1,"reset did not cancel valid");rst_n=1;
  $display("PASS tb_mod_mul_normal_pipe checks=%0d issued=%0d received=%0d latency=4 ii=1",checks,issued,received);$finish;
 end
 always@(posedge clk)begin cycle<=cycle+1;if(!rst_n)begin if(out_valid)$fatal(1,"stale valid");end else if(out_valid)begin
   if(!vq[received%16])$fatal(1,"unexpected output cycle=%0d",cycle);
   if(r!==eq[received%16])$fatal(1,"mul tx=%0d exp=%0d got=%0d",received,eq[received%16],r);
   if(r>=3329)$fatal(1,"noncanonical");vq[received%16]=0;received=received+1;checks=checks+1;end end
endmodule
