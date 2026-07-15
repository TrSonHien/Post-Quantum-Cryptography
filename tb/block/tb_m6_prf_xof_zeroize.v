`timescale 1ns/1ps
module tb_m6_prf_xof_zeroize;
 reg clk=0,rst_n=0,z=0;integer checks=0,cycles=0;reg[1:0]zseen=0;
 wire pr,pov,pbusy,pdone,perr,pzb,pzd;wire[31:0]pod;wire[3:0]pok;wire pol;
 wire xi,xsr,xov,xcv,xbusy,xdone,xerr,xzb,xzd;wire[31:0]xod;wire[3:0]xok;wire xol;
 always#5 clk=~clk;
 mlkem_prf p(.clk(clk),.rst_n(rst_n),.start(1'b0),.ready(pr),.seed(256'd0),.nonce(8'd0),.eta(2'd2),
  .out_valid(pov),.out_ready(1'b0),.out_data(pod),.out_keep(pok),.out_last(pol),.busy(pbusy),.done(pdone),.error(perr),
  .zeroize_req(z),.zeroize_busy(pzb),.zeroize_done(pzd));
 mlkem_xof x(.clk(clk),.rst_n(rst_n),.init_valid(1'b0),.init_ready(xi),.seed(256'd0),.index0(8'd0),.index1(8'd0),
  .use_generic_input(1'b0),.generic_input(272'd0),.squeeze_req_valid(1'b0),.squeeze_req_ready(xsr),.squeeze_len_bytes(32'd0),
  .out_valid(xov),.out_ready(1'b0),.out_data(xod),.out_keep(xok),.out_last(xol),.context_valid(xcv),.busy(xbusy),.done(xdone),.error(xerr),
  .zeroize_req(z),.zeroize_busy(xzb),.zeroize_done(xzd));
 task tick;begin @(posedge clk);#1;cycles=cycles+1;zseen=zseen|{xzd,pzd};end endtask
 task fill_nonzero;begin
  p.seed_reg={256{1'b1}};p.nonce_reg=8'h55;p.eta_reg=3;p.word_index=9;
  p.u_hash.u_ctx.state_reg={1600{1'b1}};p.u_hash.u_ctx.perm_state_in={1600{1'b1}};
  p.u_hash.u_ctx.u_perm.state_reg={1600{1'b1}};p.u_hash.u_ctx.u_perm.state_out={1600{1'b1}};
  x.input_reg={272{1'b1}};x.word_index=9;
  x.u_ctx.state_reg={1600{1'b1}};x.u_ctx.perm_state_in={1600{1'b1}};
  x.u_ctx.u_perm.state_reg={1600{1'b1}};x.u_ctx.u_perm.state_out={1600{1'b1}};
 end endtask
 initial begin
  tick;rst_n=1;tick;fill_nonzero;z=1;tick;z=0;
  if(!pzb||!xzb||pr||xi||pov||xov||pdone||xdone)$fatal(1,"PRF/XOF zeroize protocol start failed");checks=checks+8;
  zseen=0;while(zseen!=2'b11)begin tick;if(cycles>30)$fatal(1,"PRF/XOF zeroize timeout seen=%b",zseen);end
  if(p.seed_reg!==0||p.nonce_reg!==0||p.eta_reg!==0||p.word_index!==0||
     p.u_hash.u_ctx.state_reg!==0||p.u_hash.u_ctx.perm_state_in!==0||p.u_hash.u_ctx.u_perm.state_reg!==0||p.u_hash.u_ctx.u_perm.state_out!==0)
    $fatal(1,"PRF retained state not zero");checks=checks+8;
  if(x.input_reg!==0||x.word_index!==0||x.u_ctx.state_reg!==0||x.u_ctx.perm_state_in!==0||x.u_ctx.u_perm.state_reg!==0||x.u_ctx.u_perm.state_out!==0)
    $fatal(1,"XOF retained state not zero");checks=checks+6;
  tick;if(pzd||xzd)$fatal(1,"PRF/XOF done stale");checks=checks+2;
  fill_nonzero;z=1;tick;z=0;rst_n=0;tick;
  if(pzd||xzd||pzb||xzb)$fatal(1,"reset did not cancel PRF/XOF zeroize");checks=checks+4;
  if(p.u_hash.u_ctx.state_reg===0||x.u_ctx.state_reg===0)$fatal(1,"reset falsely erased sponge payload");checks=checks+2;
  rst_n=1;tick;zseen=0;z=1;tick;z=0;while(zseen!=2'b11)tick;
  if(p.u_hash.u_ctx.state_reg!==0||x.u_ctx.state_reg!==0)$fatal(1,"restart zeroize failed");checks=checks+2;
  $display("PASS m6_prf_xof_zeroize checks=%0d locations=14",checks);$finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
