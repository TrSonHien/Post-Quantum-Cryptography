`timescale 1ns/1ps
module tb_byte_encode_poly_pipe #(parameter integer D=12, parameter integer VECTORS=68);
 reg clk=0,rst_n=0,start=0,iv=0,ordy=0;reg[11:0]val;wire busy,done,err,irdy,ov,last;wire[31:0]odata;wire[3:0]keep;
 integer fd,rc,v,i,w,got,checks=0,cycle=0;reg[11:0]vals[0:255];reg[31:0]exp[0:95];string file;always#5 clk=~clk;
 byte_encode_poly_pipe #(.D(D))dut(clk,rst_n,start,busy,done,err,iv,irdy,val,ov,ordy,odata,keep,last);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<VECTORS;v=v+1)begin for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",vals[i]);for(w=0;w<8*D;w=w+1)rc=$fscanf(fd,"%h\n",exp[w]);
   @(negedge clk);start=1;@(negedge clk);start=0;got=0;ordy=1;
   for(i=0;i<256;i=i+1)begin while(!irdy)@(negedge clk);iv=1;val=vals[i];@(negedge clk);iv=0;end
   while(!done)begin @(negedge clk);ordy=((cycle+v)%7)!=2;cycle=cycle+1;if(cycle>200000)$fatal(1,"watchdog");end
   ordy=0;if(err)$fatal(1,"error v=%0d",v);if(got!=8*D)$fatal(1,"words v=%0d got=%0d",v,got);end
  $display("PASS tb_byte_encode_poly_pipe D=%0d vectors=%0d bytes=%0d checks=%0d",D,VECTORS,VECTORS*32*D,checks);$finish;end
 always@(posedge clk)if(rst_n&&ov&&ordy)begin if(odata!==exp[got])$fatal(1,"D=%0d v=%0d word=%0d exp=%08x got=%08x",D,v,got,exp[got],odata);if(keep!=4'hf||last!=(got==8*D-1))$fatal(1,"protocol");got=got+1;checks=checks+4;end
endmodule
