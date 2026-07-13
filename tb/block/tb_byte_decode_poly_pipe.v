`timescale 1ns/1ps
module tb_byte_decode_poly_pipe #(parameter integer D=12, parameter integer VECTORS=68, parameter integer EXPECT_NC=0);
 reg clk=0,rst_n=0,start=0,iv=0,ordy=0,last=0;reg[31:0]idata;wire busy,done,err,irdy,ov,nc;wire[11:0]oval;wire[7:0]oidx;
 integer fd,rc,v,i,w,got,checks=0,cycle=0;reg[31:0]words[0:95];reg[11:0]exp[0:255];string file;always#5 clk=~clk;
 byte_decode_poly_pipe #(.D(D))dut(clk,rst_n,start,busy,done,err,iv,irdy,idata,4'hf,last,ov,ordy,oval,oidx,nc);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<VECTORS;v=v+1)begin for(w=0;w<8*D;w=w+1)rc=$fscanf(fd,"%h\n",words[w]);for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",exp[i]);
   @(negedge clk);start=1;@(negedge clk);start=0;got=0;ordy=1;
   for(w=0;w<8*D;w=w+1)begin while(!irdy)@(negedge clk);iv=1;idata=words[w];last=(w==8*D-1);@(negedge clk);iv=0;last=0;end
   while(!done)begin @(negedge clk);ordy=((cycle+v)%9)!=3;cycle=cycle+1;if(cycle>200000)$fatal(1,"watchdog");end
   ordy=0;if(err||nc!=(EXPECT_NC!=0))$fatal(1,"flags v=%0d err=%b nc=%b",v,err,nc);if(got!=256)$fatal(1,"count");end
  $display("PASS tb_byte_decode_poly_pipe D=%0d vectors=%0d values=%0d checks=%0d",D,VECTORS,VECTORS*256,checks);$finish;end
 always@(posedge clk)if(rst_n&&ov&&ordy)begin if(oidx!==got[7:0]||oval!==exp[got])$fatal(1,"D=%0d v=%0d idx=%0d exp=%0d got=%0d",D,v,got,exp[got],oval);got=got+1;checks=checks+1;end
endmodule
