`timescale 1ns/1ps
module tb_m5_mlkem_zeroize;
 reg clk=0,rst_n=0,zh=0,zg=0,zj=0;
 reg h_cmd_valid=0,h_in_valid=0,h_out_ready=0;
 reg[31:0]h_msg_len=0,h_in_data=0;
 reg[3:0]h_in_keep=0;reg h_in_last=0;
 integer checks=0,cycles=0,word_index=0;
 reg[31:0]expected_word[0:7];
 always#5 clk=~clk;

 wire h_cmd_ready,h_in_ready,h_out_valid,h_out_last,h_busy,h_done,h_error,hb,hd;
 wire[31:0]h_out_data;wire[3:0]h_out_keep;
 wire g_cmd_ready,g_in_ready,g_out_valid,g_out_last,g_busy,g_done,g_error,gb,gd;
 wire[31:0]g_out_data;wire[3:0]g_out_keep;
 wire j_cmd_ready,j_in_ready,j_out_valid,j_out_last,j_busy,j_done,j_error,jb,jd;
 wire[31:0]j_out_data;wire[3:0]j_out_keep;

 mlkem_h h(.clk(clk),.rst_n(rst_n),.cmd_valid(h_cmd_valid),.cmd_ready(h_cmd_ready),
  .msg_len_bytes(h_msg_len),.in_valid(h_in_valid),.in_ready(h_in_ready),
  .in_data(h_in_data),.in_keep(h_in_keep),.in_last(h_in_last),
  .out_valid(h_out_valid),.out_ready(h_out_ready),.out_data(h_out_data),
  .out_keep(h_out_keep),.out_last(h_out_last),.busy(h_busy),.done(h_done),
  .error(h_error),.zeroize_req(zh),.zeroize_busy(hb),.zeroize_done(hd));
 mlkem_g g(.clk(clk),.rst_n(rst_n),.cmd_valid(1'b0),.cmd_ready(g_cmd_ready),
  .msg_len_bytes(0),.in_valid(1'b0),.in_ready(g_in_ready),.in_data(0),
  .in_keep(4'h0),.in_last(1'b0),.out_valid(g_out_valid),.out_ready(1'b0),
  .out_data(g_out_data),.out_keep(g_out_keep),.out_last(g_out_last),
  .busy(g_busy),.done(g_done),.error(g_error),.zeroize_req(zg),
  .zeroize_busy(gb),.zeroize_done(gd));
 mlkem_j j(.clk(clk),.rst_n(rst_n),.cmd_valid(1'b0),.cmd_ready(j_cmd_ready),
  .msg_len_bytes(0),.in_valid(1'b0),.in_ready(j_in_ready),.in_data(0),
  .in_keep(4'h0),.in_last(1'b0),.out_valid(j_out_valid),.out_ready(1'b0),
  .out_data(j_out_data),.out_keep(j_out_keep),.out_last(j_out_last),
  .busy(j_busy),.done(j_done),.error(j_error),.zeroize_req(zj),
  .zeroize_busy(jb),.zeroize_done(jd));

 task tick;begin @(posedge clk);#1;cycles=cycles+1;end endtask
 task preload_all;
 begin
  h.u.u.u_ctx.state_reg={1600{1'b1}};h.u.u.u_ctx.perm_state_in={1600{1'b1}};
  h.u.u.u_ctx.u_perm.state_reg={1600{1'b1}};h.u.u.u_ctx.u_perm.state_out={1600{1'b1}};
  h.u.u.u_ctx.hold_data=32'h13579bdf;h.u.u.u_ctx.build_data=32'h2468ace0;
  h.u.u.u_ctx.out_data=32'h55aa55aa;h.u.u.u_ctx.out_valid=1'b1;
  g.u.u.u_ctx.state_reg={1600{1'b1}};g.u.u.u_ctx.perm_state_in={1600{1'b1}};
  g.u.u.u_ctx.u_perm.state_reg={1600{1'b1}};g.u.u.u_ctx.u_perm.state_out={1600{1'b1}};
  g.u.u.u_ctx.hold_data=32'h13579bdf;g.u.u.u_ctx.build_data=32'h2468ace0;
  g.u.u.u_ctx.out_data=32'h55aa55aa;g.u.u.u_ctx.out_valid=1'b1;
  j.u.u.u_ctx.state_reg={1600{1'b1}};j.u.u.u_ctx.perm_state_in={1600{1'b1}};
  j.u.u.u_ctx.u_perm.state_reg={1600{1'b1}};j.u.u.u_ctx.u_perm.state_out={1600{1'b1}};
  j.u.u.u_ctx.hold_data=32'h13579bdf;j.u.u.u_ctx.build_data=32'h2468ace0;
  j.u.u.u_ctx.out_data=32'h55aa55aa;j.u.u.u_ctx.out_valid=1'b1;
 end endtask
 task check_all_zero;
 begin
  if(h.u.u.u_ctx.state_reg!==0||h.u.u.u_ctx.perm_state_in!==0||
     h.u.u.u_ctx.u_perm.state_reg!==0||h.u.u.u_ctx.u_perm.state_out!==0||
     h.u.u.u_ctx.hold_data!==0||h.u.u.u_ctx.build_data!==0||h.u.u.u_ctx.out_data!==0)
    $fatal(1,"H retained payload not zero");checks=checks+7;
  if(g.u.u.u_ctx.state_reg!==0||g.u.u.u_ctx.perm_state_in!==0||
     g.u.u.u_ctx.u_perm.state_reg!==0||g.u.u.u_ctx.u_perm.state_out!==0||
     g.u.u.u_ctx.hold_data!==0||g.u.u.u_ctx.build_data!==0||g.u.u.u_ctx.out_data!==0)
    $fatal(1,"G retained payload not zero");checks=checks+7;
  if(j.u.u.u_ctx.state_reg!==0||j.u.u.u_ctx.perm_state_in!==0||
     j.u.u.u_ctx.u_perm.state_reg!==0||j.u.u.u_ctx.u_perm.state_out!==0||
     j.u.u.u_ctx.hold_data!==0||j.u.u.u_ctx.build_data!==0||j.u.u.u_ctx.out_data!==0)
    $fatal(1,"J retained payload not zero");checks=checks+7;
 end endtask
 task request_all_zeroize;
 begin
  zh=1;zg=1;zj=1;tick;zh=0;zg=0;zj=0;
  if(!hb||!gb||!jb)$fatal(1,"zeroize_busy did not assert");checks=checks+3;
  if(h_cmd_ready||h_in_ready||h_out_valid||h_done||h_error||
     g_cmd_ready||g_in_ready||g_out_valid||g_done||g_error||
     j_cmd_ready||j_in_ready||j_out_valid||j_done||j_error)
    $fatal(1,"normal protocol visible during zeroize");checks=checks+15;
  while(!(hd&&gd&&jd))begin tick;if(cycles>200)$fatal(1,"zeroize timeout");end
  checks=checks+3;tick;
  if(hd||gd||jd)$fatal(1,"zeroize_done wider than one cycle");checks=checks+3;
 end endtask

 initial begin
  expected_word[0]=32'hf8c6ffa7;expected_word[1]=32'h66d71ebf;
  expected_word[2]=32'h5647c151;expected_word[3]=32'h62d661a0;
  expected_word[4]=32'h4dff80f5;expected_word[5]=32'hfa493be4;
  expected_word[6]=32'h4b0ad882;expected_word[7]=32'h4a43f880;
  tick;rst_n=1;tick;

  // Explicit zeroize covers absorb, permutation, squeeze, and output staging.
  preload_all;request_all_zeroize;check_all_zero;

  // Reset cancels zeroize but does not claim or perform payload destruction.
  h.u.u.u_ctx.state_reg={1600{1'b1}};h.u.u.u_ctx.u_perm.state_reg={1600{1'b1}};
  zh=1;tick;zh=0;
  if(!hb)$fatal(1,"H zeroize_busy missing before reset");checks=checks+1;
  rst_n=0;tick;
  if(hd||hb)$fatal(1,"reset did not invalidate zeroize completion");checks=checks+2;
  if(h.u.u.u_ctx.state_reg===0||h.u.u.u_ctx.u_perm.state_reg===0)
    $fatal(1,"reset was incorrectly used as payload erase");checks=checks+2;
  rst_n=1;tick;zh=1;tick;zh=0;
  while(!hd)begin tick;if(cycles>300)$fatal(1,"restart zeroize timeout");end
  tick;
  if(h.u.u.u_ctx.state_reg!==0||h.u.u.u_ctx.u_perm.state_reg!==0)
    $fatal(1,"restart zeroize failed");checks=checks+2;

  // Repeated zeroize is deterministic and leaves the service reusable.
  request_all_zeroize;check_all_zero;
  h_msg_len=0;h_out_ready=0;h_cmd_valid=1;tick;h_cmd_valid=0;
  word_index=0;
  while(word_index<8)begin
   while(!h_out_valid)begin tick;if(cycles>800)$fatal(1,"clean restart timeout");end
    if(h_out_keep!==4'hf||h_out_data!==expected_word[word_index])
      $fatal(1,"clean restart word %0d exp=%08x got=%08x keep=%x",word_index,expected_word[word_index],h_out_data,h_out_keep);
    if(h_out_last!==(word_index==7))$fatal(1,"clean restart last mismatch");
    h_out_ready=1;tick;h_out_ready=0;
    word_index=word_index+1;checks=checks+3;
  end
  if(!h_done)tick;
  if(word_index!=8||h_error)$fatal(1,"clean restart incomplete");checks=checks+2;
  $display("PASS m5_mlkem_zeroize checks=%0d state_bits=19200 cycles=%0d",checks,cycles);
  $finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
