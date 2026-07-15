`timescale 1ns/1ps
module tb_arithmetic_pipeline_zeroize;
 reg clk=0,rst_n=0,z=0,in_valid=0;reg[11:0]a=0,b=0;reg[31:0]ma=0;
 wire av,sv,mv,rv;wire[11:0]ar,sr,mr,rr;
 wire ab,ad,sb,sd,mb,md,rb,rd;
 integer checks=0,cycles=0;reg[3:0]seen;reg got_mul=0,got_red=0;reg[11:0]restart_mul,restart_red;
 always#5 clk=~clk;
 mod_add_pipe add(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.a(a),.b(b),.out_valid(av),.r(ar),.zeroize_req(z),.zeroize_busy(ab),.zeroize_done(ad));
 mod_sub_pipe sub(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.a(a),.b(b),.out_valid(sv),.r(sr),.zeroize_req(z),.zeroize_busy(sb),.zeroize_done(sd));
 mod_mul_pipe mul(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.a(a),.b(b),.out_valid(mv),.r(mr),.zeroize_req(z),.zeroize_busy(mb),.zeroize_done(md));
 montgomery_reduce_pipe red(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.a(ma),.out_valid(rv),.r(rr),.zeroize_req(z),.zeroize_busy(rb),.zeroize_done(rd));
 task tick;begin @(posedge clk);#1;cycles=cycles+1;seen=seen|{rd,md,sd,ad};end endtask
 initial begin
  tick;rst_n=1;tick;
  add.r=12'h111;sub.r=12'h222;mul.prod_s1=24'habcdef;mul.u_reduce.m_reg=16'h1234;
  mul.u_reduce.a_d1=32'hdeadbeef;mul.u_reduce.mq_reg=28'h1234567;mul.u_reduce.a_d2=32'h76543210;mul.u_reduce.r=12'h333;
  red.m_reg=16'h5678;red.a_d1=32'h11112222;red.mq_reg=28'h7654321;red.a_d2=32'h33334444;red.r=12'h444;
  rst_n=0;tick;rst_n=1;tick;
  if(add.r===0||sub.r===0||mul.prod_s1===0||red.a_d2===0)$fatal(1,"reset erased arithmetic payload");checks=checks+4;
  seen=0;z=1;tick;z=0;
  if(!ab||!sb||!mb||!rb||av||sv||mv||rv)$fatal(1,"arithmetic zeroize protocol start failed");checks=checks+8;
  while(seen!=4'hf)begin tick;if(cycles>30)$fatal(1,"arithmetic zeroize timeout seen=%x",seen);end
  if(add.r!==0||sub.r!==0||mul.prod_s1!==0||mul.val_s1!==0||
     mul.u_reduce.m_reg!==0||mul.u_reduce.a_d1!==0||mul.u_reduce.mq_reg!==0||mul.u_reduce.a_d2!==0||mul.u_reduce.r!==0||
     red.m_reg!==0||red.a_d1!==0||red.mq_reg!==0||red.a_d2!==0||red.r!==0)
    $fatal(1,"arithmetic retained payload not zero");checks=checks+14;
  if(add.out_valid||sub.out_valid||mul.val_s1||mul.u_reduce.val_d1||mul.u_reduce.val_d2||mul.u_reduce.out_valid||red.val_d1||red.val_d2||red.out_valid)
    $fatal(1,"arithmetic valid metadata not zero");checks=checks+9;
  tick;if(ad||sd||md||rd)$fatal(1,"arithmetic done pulse stale");checks=checks+4;
  a=12'd2;b=12'd3;ma=32'd65536;in_valid=1;tick;in_valid=0;
  while(!got_mul||!got_red)begin
   tick;if(mv)begin got_mul=1;restart_mul=mr;end if(rv)begin got_red=1;restart_red=rr;end
   if(cycles>50)$fatal(1,"arithmetic restart timeout");
  end
  if(restart_mul!=12'd1014||restart_red!=12'd1)$fatal(1,"arithmetic restart mismatch mul=%0d red=%0d",restart_mul,restart_red);checks=checks+2;
  $display("PASS arithmetic_pipeline_zeroize checks=%0d locations=23",checks);$finish;
 end
 initial begin #10000;$fatal(1,"watchdog");end
endmodule
