`timescale 1ns/1ps
module tb_polyvec_workspace;
 reg clk=0,rst_n=0,lb=0,lw=0,acq=0,init=0,pub=0,rel=0,rr=0,ir=0,iw=0;reg[1:0]lp,lwp,ld,rp,ip,wp;reg[7:0]li,ri,ii,wi;reg[11:0]lc,wc;wire lr,rv,iv,vc,dc;wire[11:0]rc,ic;wire[2:0]pc;wire[1:0]vd;wire err;integer p,i,checks=0;always#5 clk=~clk;
 wire zeroize_busy,zeroize_done;
 polyvec_workspace d(clk,rst_n,lb,lp,ld,lw,lwp,li,lc,lr,acq,init,ld,pub,rel,pc,vc,dc,vd,err,rr,rp,ri,rv,rc,ir,ip,ii,iv,ic,iw,wp,wi,wc,1'b0,zeroize_busy,zeroize_done);
 initial begin repeat(3)@(negedge clk);rst_n=1;for(p=0;p<3;p=p+1)begin@(negedge clk);lb=1;lp=p;ld=1;@(negedge clk);lb=0;for(i=255;i>=0;i=i-1)begin lw=1;lwp=p;li=i;lc=(p*257+i)%3329;@(negedge clk);end lw=0;if(!pc[p])$fatal(1,"poly complete %0d",p);end if(!vc||!dc||vd!=1)$fatal(1,"vector metadata");
  @(negedge clk);acq=1;@(negedge clk);acq=0;rel=1;@(negedge clk);rel=0;
  for(p=0;p<3;p=p+1)for(i=0;i<256;i=i+1)begin rr=1;rp=p;ri=i;@(negedge clk);if(!rv||rc!==((p*257+i)%3329))$fatal(1,"read p=%0d i=%0d",p,i);checks=checks+1;end rr=0;
  rp=3;rr=1;@(negedge clk);rr=0;if(!err)$fatal(1,"invalid poly index");rst_n=0;@(negedge clk);rst_n=1;if(vc||vd!=0||rv||iv)$fatal(1,"reset metadata");
  $display("PASS tb_polyvec_workspace checks=%0d locations=768",checks);$finish;end
endmodule
