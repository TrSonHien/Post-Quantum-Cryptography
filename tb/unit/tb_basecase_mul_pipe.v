`timescale 1ns/1ps
module tb_basecase_mul_pipe;
 reg clk=0,rst_n=0,in_valid=0;reg[11:0]a0,a1,b0,b1,gamma;wire out_valid;wire[11:0]c0,c1;always#5 clk=~clk;
 basecase_mul_pipe dut(clk,rst_n,in_valid,a0,a1,b0,b1,gamma,out_valid,c0,c1);
 integer fd,rc,checks=0,issued=0,received=0,i;reg[11:0]x0,x1,y0,y1,g,e0,e1;reg[11:0]q0[0:31],q1[0:31];reg vq[0:31];string file;
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");for(i=0;i<32;i=i+1)vq[i]=0;repeat(3)@(negedge clk);rst_n=1;
  while(!$feof(fd))begin rc=$fscanf(fd,"%h %h %h %h %h %h %h\n",x0,x1,y0,y1,g,e0,e1);if(rc==7)begin@(negedge clk);in_valid=1;a0=x0;a1=x1;b0=y0;b1=y1;gamma=g;q0[issued%32]=e0;q1[issued%32]=e1;vq[issued%32]=1;issued=issued+1;end end
  @(negedge clk);in_valid=0;repeat(24)@(negedge clk);if(received!=issued)$fatal(1,"count");$display("PASS tb_basecase_mul_pipe checks=%0d latency=9 ii=1",checks);$finish;end
 always@(posedge clk)if(rst_n&&out_valid)begin if(!vq[received%32])$fatal(1,"unexpected");if(c0!==q0[received%32]||c1!==q1[received%32])$fatal(1,"basecase tx=%0d exp=%0d,%0d got=%0d,%0d",received,q0[received%32],q1[received%32],c0,c1);if(c0>=3329||c1>=3329)$fatal(1,"canonical");vq[received%32]=0;received=received+1;checks=checks+1;end
endmodule
