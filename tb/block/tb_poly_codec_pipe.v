`timescale 1ns/1ps
module tb_poly_codec_pipe #(parameter integer D=10,parameter integer VECTORS=64);
 reg clk=0,rst_n=0,es=0,eiv=0,eordy=1,ds=0,div=0,dordy=1,dlast=0;reg[11:0]ec;reg[31:0]did;
 wire eb,ed,ee,eir,eov,eol,db,dd,de,dir,dov;wire[31:0]eod;wire[3:0]eok;wire[11:0]doc;wire[7:0]doi;wire[1:0]dom;
 integer fd,rc,v,i,w,egot,dgot,checks=0,cycle=0;reg[11:0]src[0:255],expdec[0:255];reg[31:0]expword[0:79],capword[0:79];string file;always#5 clk=~clk;
 poly_compress_encode_pipe #(.D(D))enc(clk,rst_n,es,2'b01,eb,ed,ee,eiv,eir,ec,eov,eordy,eod,eok,eol);
 poly_decode_decompress_pipe #(.D(D))dec(clk,rst_n,ds,db,dd,de,div,dir,did,4'hf,dlast,dov,dordy,doc,doi,dom);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<VECTORS;v=v+1)begin for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",src[i]);for(w=0;w<8*D;w=w+1)rc=$fscanf(fd,"%h\n",expword[w]);for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",expdec[i]);
   @(negedge clk);es=1;@(negedge clk);es=0;egot=0;
   for(i=0;i<256;i=i+1)begin while(!eir)@(negedge clk);eiv=1;ec=src[i];@(negedge clk);eiv=0;end
   while(!ed)begin @(negedge clk);cycle=cycle+1;if(cycle>20000)$fatal(1,"encode watchdog busy=%b in_ready=%b out_valid=%b accepted=%0d emitted=%0d bits=%0d egot=%0d",eb,eir,eov,enc.u.accepted,enc.u.emitted,enc.u.bit_count,egot);end if(ee||egot!=8*D)$fatal(1,"encode status");
   @(negedge clk);ds=1;@(negedge clk);ds=0;dgot=0;
   for(w=0;w<8*D;w=w+1)begin while(!dir)@(negedge clk);div=1;did=capword[w];dlast=(w==8*D-1);@(negedge clk);div=0;dlast=0;end
   while(!dd)begin @(negedge clk);cycle=cycle+1;if(cycle>40000)$fatal(1,"decode watchdog");end if(de||dgot!=256)$fatal(1,"decode status");end
  $display("PASS tb_poly_codec_pipe D=%0d vectors=%0d byte_checks=%0d coeff_checks=%0d",D,VECTORS,VECTORS*32*D,VECTORS*256);$finish;end
 always@(posedge clk)begin if(eov&&eordy)begin if(eod!==expword[egot]||eol!=(egot==8*D-1))$fatal(1,"encode D=%0d v=%0d w=%0d",D,v,egot);capword[egot]=eod;egot=egot+1;checks=checks+4;end
  if(dov&&dordy)begin if(doi!==dgot[7:0]||doc!==expdec[dgot]||dom!=2'b01)$fatal(1,"decode D=%0d v=%0d i=%0d exp=%0d got=%0d",D,v,dgot,expdec[dgot],doc);dgot=dgot+1;checks=checks+1;end end
endmodule
