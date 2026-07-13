`timescale 1ns/1ps
module tb_polyvec_codec_pipe #(parameter integer D=12,parameter integer COMPRESS=0,parameter integer VECTORS=32);
 reg clk=0,rst_n=0,es=0,eiv=0,eordy=1,ds=0,div=0,dordy=1,dlast=0;reg[11:0]ec;reg[31:0]did;
 wire eb,ed,ee,eir,eov,eol,db,dd,de,dir,dov,nc;wire[31:0]eod;wire[3:0]eok;wire[11:0]doc;wire[7:0]doi;wire[1:0]edom,epi,dpi;
 integer fd,rc,v,i,w,egot,dgot;reg[11:0]src[0:767],expdec[0:767];reg[31:0]expword[0:287],capword[0:287];string file;always#5 clk=~clk;
 polyvec_codec_pipe #(.D(D),.ENCODE(1),.COMPRESS(COMPRESS))enc(clk,rst_n,es,(COMPRESS?2'b01:2'b10),eb,ed,ee,eiv,eir,ec,1'b0,,32'd0,4'd0,1'b0,eov,eordy,eod,eok,eol,,1'b0,,,,epi,);
 polyvec_codec_pipe #(.D(D),.ENCODE(0),.COMPRESS(COMPRESS))dec(clk,rst_n,ds,(COMPRESS?2'b01:2'b10),db,dd,de,1'b0,,12'd0,div,dir,did,4'hf,dlast,,1'b0,,, ,dov,dordy,doc,doi,edom,dpi,nc);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<VECTORS;v=v+1)begin for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h\n",src[i]);for(w=0;w<24*D;w=w+1)rc=$fscanf(fd,"%h\n",expword[w]);for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h\n",expdec[i]);
   @(negedge clk);es=1;@(negedge clk);es=0;egot=0;for(i=0;i<768;i=i+1)begin while(!eir)@(negedge clk);eiv=1;ec=src[i];@(negedge clk);eiv=0;end while(!ed)@(negedge clk);if(ee||egot!=24*D)$fatal(1,"encode status");
   @(negedge clk);ds=1;@(negedge clk);ds=0;dgot=0;for(w=0;w<24*D;w=w+1)begin while(!dir)@(negedge clk);div=1;did=capword[w];dlast=(w==24*D-1);@(negedge clk);div=0;dlast=0;end while(!dd)@(negedge clk);if(de||nc||dgot!=768)$fatal(1,"decode status");end
  $display("PASS tb_polyvec_codec_pipe D=%0d vectors=%0d byte_checks=%0d coeff_checks=%0d",D,VECTORS,VECTORS*96*D,VECTORS*768);$finish;end
 always@(posedge clk)begin if(eov&&eordy)begin if(eod!==expword[egot]||eol!=(egot==24*D-1))$fatal(1,"encode D=%0d v=%0d w=%0d",D,v,egot);capword[egot]=eod;egot=egot+1;end if(dov&&dordy)begin if(doc!==expdec[dgot]||doi!==dgot[7:0]||dpi!==(dgot/256))$fatal(1,"decode D=%0d v=%0d i=%0d pi=%0d idx=%0d exp=%0d got=%0d",D,v,dgot,dpi,doi,expdec[dgot],doc);dgot=dgot+1;end end
endmodule
