`timescale 1ns/1ps
module tb_message_codec_pipe;
 reg clk=0,rst_n=0,ds=0,div=0,dlast=0,dordy=1,es=0,eiv=0,eordy=1;reg[31:0]did;reg[11:0]ec;
 wire db,dd,de,dir,dov,eb,ed,ee,eir,eov,eol;wire[11:0]doc;wire[7:0]doi;wire[1:0]dom;wire[31:0]eod;wire[3:0]eok;
 integer fd,rc,v,i,w,dgot,egot,checks=0;reg[31:0]msg[0:7];reg[11:0]exp[0:255],cap[0:255];string file;always#5 clk=~clk;
 message_to_poly_pipe dec(clk,rst_n,ds,db,dd,de,div,dir,did,4'hf,dlast,dov,dordy,doc,doi,dom);
 poly_to_message_pipe enc(clk,rst_n,es,2'b01,eb,ed,ee,eiv,eir,ec,eov,eordy,eod,eok,eol);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<388;v=v+1)begin for(w=0;w<8;w=w+1)rc=$fscanf(fd,"%h\n",msg[w]);for(i=0;i<256;i=i+1)rc=$fscanf(fd,"%h\n",exp[i]);
   @(negedge clk);ds=1;@(negedge clk);ds=0;dgot=0;for(w=0;w<8;w=w+1)begin while(!dir)@(negedge clk);div=1;did=msg[w];dlast=(w==7);@(negedge clk);div=0;dlast=0;end while(!dd)@(negedge clk);if(de||dgot!=256)$fatal(1,"decode");
   @(negedge clk);es=1;@(negedge clk);es=0;egot=0;for(i=0;i<256;i=i+1)begin while(!eir)@(negedge clk);eiv=1;ec=cap[i];@(negedge clk);eiv=0;end while(!ed)@(negedge clk);if(ee||egot!=8)$fatal(1,"encode");end
  $display("PASS tb_message_codec_pipe vectors=388 byte_checks=%0d coeff_checks=%0d",388*32,388*256);$finish;end
 always@(posedge clk)begin if(dov&&dordy)begin if(doc!==exp[dgot])$fatal(1,"decode v=%0d i=%0d",v,dgot);cap[dgot]=doc;dgot=dgot+1;checks=checks+1;end if(eov&&eordy)begin if(eod!==msg[egot]||eol!=(egot==7))$fatal(1,"roundtrip v=%0d w=%0d",v,egot);egot=egot+1;checks=checks+4;end end
endmodule
