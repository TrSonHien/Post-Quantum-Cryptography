`timescale 1ns/1ps
module tb_m6_sampler_zeroize;
 reg clk=0,rst_n=0;always#5 clk=~clk;
 reg z_pair=0,z_cbd=0,z_parser=0,z_noise=0,z_ntt=0;
 wire zb_pair,zd_pair,zb_cbd,zd_cbd,zb_parser,zd_parser,zb_noise,zd_noise,zb_ntt,zd_ntt;
 reg[4:0]seen_done=0;integer checks=0;
 always@(posedge clk)if(!rst_n)seen_done<=0;else seen_done<=seen_done|{zd_ntt,zd_noise,zd_parser,zd_cbd,zd_pair};
 task check_value;input condition;input[255:0]label;begin checks=checks+1;if(!condition)$fatal(1,"sampler zeroize check failed: %0s",label);end endtask

 wire pair_ir,pair_ov,pair_err;wire[11:0]pair_c0,pair_c1;
 cbd_pair_pipe pair(clk,rst_n,1'b0,pair_ir,2'd2,12'd0,pair_ov,1'b0,pair_c0,pair_c1,pair_err,z_pair,zb_pair,zd_pair);
 wire cbd_busy,cbd_done,cbd_err,cbd_ir,cbd_ov;wire[11:0]cbd_oc;wire[7:0]cbd_oi;wire[1:0]cbd_dom;
 sample_poly_cbd_pipe cbd(clk,rst_n,1'b0,2'd2,cbd_busy,cbd_done,cbd_err,1'b0,cbd_ir,32'd0,4'hf,1'b0,cbd_ov,1'b0,cbd_oc,cbd_oi,cbd_dom,z_cbd,zb_cbd,zd_cbd);
 wire p_busy,p_done,p_err,p_ir,p_ov;wire[11:0]p_oc;wire[7:0]p_oi;wire[1:0]p_dom;wire[31:0]p_g,p_a,p_r;
 sample_ntt_parser parser(clk,rst_n,1'b0,p_busy,p_done,p_err,1'b0,p_ir,24'd0,p_ov,1'b0,p_oc,p_oi,p_dom,p_g,p_a,p_r,z_parser,zb_parser,zd_parser);
 wire n_busy,n_done,n_err,n_ov;wire[11:0]n_oc;wire[7:0]n_oi;wire[1:0]n_dom;
 mlkem_noise_sampler noise(clk,rst_n,1'b0,256'd0,8'd0,2'd2,n_busy,n_done,n_err,n_ov,1'b0,n_oc,n_oi,n_dom,z_noise,zb_noise,zd_noise);
 wire s_busy,s_done,s_err,s_ov;wire[11:0]s_oc;wire[7:0]s_oi;wire[1:0]s_dom;wire[31:0]s_g,s_a,s_r;
 mlkem_sample_ntt sntt(clk,rst_n,1'b0,256'd0,8'd0,8'd0,1'b0,272'd0,s_busy,s_done,s_err,s_ov,1'b0,s_oc,s_oi,s_dom,s_g,s_a,s_r,z_ntt,zb_ntt,zd_ntt);

 task seed_state;begin
  pair.out_valid=1;pair.coeff0=12'h123;pair.coeff1=12'h456;pair.error=1;
  cbd.busy=1;cbd.eta_reg=3;cbd.reservoir=64'h0123456789abcdef;cbd.bit_count=33;cbd.words_in=17;cbd.coeff_count=99;cbd.out_valid=1;cbd.out_coeff=12'h789;cbd.out_index=8'h55;cbd.error=1;
  parser.busy=1;parser.q0=12'habc;parser.q1=12'hdef;parser.qcount=2;parser.count=123;parser.groups_examined=32'h11111111;parser.candidates_accepted=32'h22222222;parser.candidates_rejected=32'h33333333;parser.error=1;
  noise.busy=1;noise.error=1;noise.p.seed_reg={8{32'h89abcdef}};noise.p.nonce_reg=8'hc3;noise.p.eta_reg=3;noise.p.word_index=7;noise.c.reservoir=64'hfedcba9876543210;noise.c.out_coeff=12'h777;
  sntt.busy=1;sntt.error=1;sntt.req_pending=1;sntt.x.input_reg={8{34'h2aaaaaaaa}};sntt.x.word_index=5;sntt.p.q0=12'h888;sntt.p.q1=12'h999;sntt.p.qcount=2;sntt.p.groups_examined=32'h44444444;
 end endtask
 task check_zero;begin
  check_value({pair.out_valid,pair.coeff0,pair.coeff1,pair.error}===0,"CBD pair payload");
  check_value({cbd.busy,cbd.eta_reg,cbd.reservoir,cbd.bit_count,cbd.words_in,cbd.coeff_count,cbd.out_valid,cbd.out_coeff,cbd.out_index,cbd.error}===0,"CBD reservoir");
  check_value({parser.busy,parser.q0,parser.q1,parser.qcount,parser.count,parser.groups_examined,parser.candidates_accepted,parser.candidates_rejected,parser.error}===0,"SampleNTT parser");
  check_value({noise.busy,noise.done,noise.error,noise.child_start,noise.child_zeroize_req,noise.prf_zeroized,noise.cbd_zeroized,noise.p.seed_reg,noise.p.nonce_reg,noise.p.eta_reg,noise.p.word_index,noise.c.reservoir,noise.c.out_coeff}===0,"noise hierarchy");
  check_value({sntt.busy,sntt.done,sntt.error,sntt.child_start,sntt.req_pending,sntt.child_zeroize_req,sntt.xof_zeroized,sntt.parser_zeroized,sntt.x.input_reg,sntt.x.word_index,sntt.p.q0,sntt.p.q1,sntt.p.qcount,sntt.p.groups_examined}===0,"SampleNTT hierarchy");
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst_n=1;@(negedge clk);seed_state();
  check_value(pair.coeff0!=0&&cbd.reservoir!=0&&parser.q0!=0&&noise.p.seed_reg!=0&&sntt.x.input_reg!=0,"all state populated");
  z_pair=1;z_cbd=1;z_parser=1;z_noise=1;z_ntt=1;@(negedge clk);
  check_value(zb_pair&&zb_cbd&&zb_parser&&zb_noise&&zb_ntt,"all busy");
  check_value(!(zd_pair||zd_cbd||zd_parser||zd_noise||zd_ntt),"no premature done");
  z_pair=0;z_cbd=0;z_parser=0;z_noise=0;z_ntt=0;
  while(seen_done!=5'h1f)@(negedge clk);check_zero();
  @(negedge clk);check_value(!(zd_pair||zd_cbd||zd_parser||zd_noise||zd_ntt),"done one cycle");
  // Reset interrupts parent cleanup and invalidates its completion.
  seed_state();z_noise=1;@(negedge clk);check_value(zb_noise,"noise scrub accepted");rst_n=0;z_noise=0;@(negedge clk);check_value(!zb_noise&&!zd_noise,"reset invalidates noise scrub");rst_n=1;@(negedge clk);z_noise=1;@(negedge clk);z_noise=0;while(!zd_noise)@(negedge clk);check_value(noise.p.seed_reg===0&&noise.c.reservoir===0,"noise scrub restarted");
  // Clean one-cycle CBD pair transaction after scrub.
  @(negedge clk);force pair.in_valid=1'b1;force pair.eta=2'd2;force pair.in_bits=12'h00f;force pair.out_ready=1'b1;@(negedge clk);release pair.in_valid;release pair.eta;release pair.in_bits;check_value(pair_ov&&pair_c0==0&&pair_c1==0,"clean restart oracle");release pair.out_ready;
  $display("PASS tb_m6_sampler_zeroize checks=%0d owner_types=5 prf_cbd_ack=PASS xof_parser_ack=PASS reset_interrupt=PASS clean_restart=PASS",checks);$finish;
 end
endmodule
