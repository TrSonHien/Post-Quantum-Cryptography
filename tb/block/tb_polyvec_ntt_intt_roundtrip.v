`timescale 1ns/1ps
module tb_polyvec_ntt_intt_roundtrip;
 reg clk=0,rst_n=0;always#5 clk=~clk;reg flb=0,flw=0,fs=0,frr=0,frl=0;reg[1:0]fp,fd,frp;reg[7:0]fi,fri;reg[11:0]fc;wire flr,fb,fdone,fe,frv,frc;wire[11:0]frcoef;wire[1:0]frd;
 reg ilb=0,ilw=0,is=0,irr=0,irl=0;reg[1:0]ip,id,irp;reg[7:0]ii,iri;reg[11:0]ic;wire ilr,ib,idone,ie,irv,irc;wire[11:0]ircoef;wire[1:0]ird;
 polyvec_ntt_pipe f(clk,rst_n,flb,1'b0,fp,fd,flw,fi,fc,flr,fs,fb,fdone,fe,frr,frp,fri,frv,frcoef,frd,frc,frl);
 polyvec_intt_pipe g(clk,rst_n,ilb,1'b0,ip,id,ilw,ii,ic,ilr,is,ib,idone,ie,irr,irp,iri,irv,ircoef,ird,irc,irl);
 reg[11:0]mem[0:36863];integer v,p,j,base,watch,fcmp=0,icmp=0,fcycles,icycles,sc,cycles=0;string file;always@(posedge clk)cycles<=cycles+1;
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");$readmemh(file,mem);repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<16;v=v+1)begin base=v*2304;for(p=0;p<3;p=p+1)begin@(negedge clk);flb=1;fp=p;fd=1;@(negedge clk);flb=0;for(j=0;j<256;j=j+1)begin flw=1;fi=j;fc=mem[base+p*256+j];@(negedge clk);end flw=0;end sc=cycles;@(negedge clk);fs=1;@(negedge clk);fs=0;watch=0;while(!fdone&&watch<7000)begin@(negedge clk);watch=watch+1;end fcycles=cycles-sc;if(!fdone)$fatal(1,"f timeout");
   for(p=0;p<3;p=p+1)begin@(negedge clk);ilb=1;ip=p;id=2;@(negedge clk);ilb=0;for(j=0;j<256;j=j+1)begin frr=1;frp=p;fri=j;@(negedge clk);if(!frv||frcoef!==mem[base+768+p*256+j])$fatal(1,"forward v=%0d p=%0d i=%0d",v,p,j);fcmp=fcmp+1;ilw=1;ii=j;ic=frcoef;@(negedge clk);ilw=0;end frr=0;end frl=1;@(negedge clk);frl=0;
   sc=cycles;@(negedge clk);is=1;@(negedge clk);is=0;watch=0;while(!idone&&watch<7500)begin@(negedge clk);watch=watch+1;end icycles=cycles-sc;if(!idone)$fatal(1,"i timeout");for(p=0;p<3;p=p+1)for(j=0;j<256;j=j+1)begin irr=1;irp=p;iri=j;@(negedge clk);if(!irv||ircoef!==mem[base+1536+p*256+j])$fatal(1,"inverse v=%0d p=%0d i=%0d",v,p,j);icmp=icmp+1;end irr=0;irl=1;@(negedge clk);irl=0;end
  if(fe||ie)$fatal(1,"error");$display("PASS tb_polyvec_ntt_intt_roundtrip vectors=16 forward_comparisons=%0d final_comparisons=%0d fwd_cycles=%0d intt_cycles=%0d",fcmp,icmp,fcycles,icycles);$finish;end
endmodule
