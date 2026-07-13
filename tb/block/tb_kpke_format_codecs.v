`timescale 1ns/1ps
module tb_kpke_format_codecs #(parameter integer WORDS=296,parameter integer SPLIT=288,parameter integer VECTORS=32);
 reg clk=0,rst_n=0,start=0,iv=0,last=0,ordy=1;reg[31:0]id;wire busy,done,error,ir,ov,ol,seg;wire[31:0]od;wire[3:0]ok;
 integer fd,rc,v,w,got,checks=0;reg[31:0]exp[0:295];string file;always#5 clk=~clk;
 kpke_format_pipe #(.WORDS(WORDS),.SPLIT_WORDS(SPLIT))dut(clk,rst_n,start,busy,done,error,iv,ir,id,4'hf,last,ov,ordy,od,ok,ol,seg);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<VECTORS;v=v+1)begin for(w=0;w<WORDS;w=w+1)rc=$fscanf(fd,"%h\n",exp[w]);@(negedge clk);start=1;@(negedge clk);start=0;got=0;
   for(w=0;w<WORDS;w=w+1)begin while(!ir)@(negedge clk);iv=1;id=exp[w];last=(w==WORDS-1);@(negedge clk);iv=0;last=0;end while(!done)@(negedge clk);if(error||got!=WORDS)$fatal(1,"status");end
  $display("PASS tb_kpke_format_codecs vectors=%0d bytes=%0d checks=%0d",VECTORS,VECTORS*WORDS*4,checks);$finish;end
 always@(posedge clk)if(ov&&ordy)begin if(od!==exp[got]||ol!=(got==WORDS-1)||seg!=(got>=SPLIT))$fatal(1,"v=%0d w=%0d",v,got);got=got+1;checks=checks+4;end
endmodule
