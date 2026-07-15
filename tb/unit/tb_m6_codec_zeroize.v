`timescale 1ns/1ps
module tb_m6_codec_zeroize;
 reg clk=0,rst_n=0;
 reg z_bits=0,z_bytes=0,z_comp=0,z_decomp=0,z_enc=0,z_dec=0,z_fmt=0,z_pv=0;
 wire zb_bits,zd_bits,zb_bytes,zd_bytes,zb_comp,zd_comp,zb_decomp,zd_decomp;
 wire zb_enc,zd_enc,zb_dec,zd_dec,zb_fmt,zd_fmt,zb_pv,zd_pv;
 integer checks=0,done_pulses=0;
 reg[7:0]seen_done=0;
 always #5 clk=~clk;
 always @(posedge clk) if(!rst_n)seen_done<=0;else seen_done<=seen_done|{zd_pv,zd_fmt,zd_dec,zd_enc,zd_decomp,zd_comp,zd_bytes,zd_bits};

 wire b_ir,b_ov; wire[7:0]b_out;
 bits_to_bytes_pipe bits(clk,rst_n,1'b0,b_ir,8'd0,b_ov,1'b0,b_out,z_bits,zb_bits,zd_bits);
 wire by_ir,by_ov; wire[7:0]by_out;
 bytes_to_bits_pipe bytes(clk,rst_n,1'b0,by_ir,8'd0,by_ov,1'b0,by_out,z_bytes,zb_bytes,zd_bytes);
 wire c_ov,c_err; wire[11:0]c_out;
 compress_coeff_pipe #(.D(10)) comp(clk,rst_n,1'b0,12'd0,c_ov,c_out,c_err,z_comp,zb_comp,zd_comp);
 wire d_ov,d_err; wire[11:0]d_out;
 decompress_coeff_pipe #(.D(10)) decomp(clk,rst_n,1'b0,12'd0,d_ov,d_out,d_err,z_decomp,zb_decomp,zd_decomp);
 reg enc_start=0; wire enc_busy,enc_done,enc_err,enc_ir,enc_ov; wire[31:0]enc_od;wire[3:0]enc_ok;wire enc_last;
 byte_encode_poly_pipe #(.D(12)) enc(clk,rst_n,enc_start,enc_busy,enc_done,enc_err,1'b0,enc_ir,12'd0,enc_ov,1'b0,enc_od,enc_ok,enc_last,z_enc,zb_enc,zd_enc);
 reg dec_start=0; wire dec_busy,dec_done,dec_err,dec_ir,dec_ov;wire[11:0]dec_val;wire[7:0]dec_idx;wire dec_nc;
 byte_decode_poly_pipe #(.D(12)) dec(clk,rst_n,dec_start,dec_busy,dec_done,dec_err,1'b0,dec_ir,32'd0,4'hf,1'b0,dec_ov,1'b0,dec_val,dec_idx,dec_nc,z_dec,zb_dec,zd_dec);
 reg fmt_start=0; wire fmt_busy,fmt_done,fmt_err,fmt_ir,fmt_ov;wire[31:0]fmt_od;wire[3:0]fmt_ok;wire fmt_last,fmt_seg;
 kpke_format_pipe #(.WORDS(4),.SPLIT_WORDS(2)) fmt(clk,rst_n,fmt_start,fmt_busy,fmt_done,fmt_err,1'b0,fmt_ir,32'd0,4'hf,1'b0,fmt_ov,1'b0,fmt_od,fmt_ok,fmt_last,fmt_seg,z_fmt,zb_fmt,zd_fmt);
 reg pv_start=0;wire pv_busy,pv_done,pv_err,pv_cir,pv_bir,pv_bov,pv_cov;wire[31:0]pv_bd;wire[3:0]pv_bk;wire pv_bl;wire[11:0]pv_co;wire[7:0]pv_ci;wire[1:0]pv_cd,pv_pi;wire pv_nc;
 polyvec_codec_pipe #(.D(12),.ENCODE(1),.COMPRESS(0)) pv(clk,rst_n,pv_start,2'b10,pv_busy,pv_done,pv_err,1'b0,pv_cir,12'd0,1'b0,pv_bir,32'd0,4'hf,1'b0,pv_bov,1'b0,pv_bd,pv_bk,pv_bl,pv_cov,1'b0,pv_co,pv_ci,pv_cd,pv_pi,pv_nc,z_pv,zb_pv,zd_pv);

 task check_value; input condition; input[255:0]label; begin checks=checks+1;if(!condition)$fatal(1,"codec zeroize check failed: %0s",label);end endtask
 task seed_state; begin
  bits.out_valid=1;bits.out_byte=8'h81;
  bytes.out_valid=1;bytes.out_bits=8'h42;
  comp.valid_s1=1;comp.numer_s1=23'h12345;comp.product_s1=36'h123456789;comp.range_s1=1;comp.out_valid=1;comp.out_value=12'h456;comp.error=1;
  decomp.valid_s1=1;decomp.numer_s1=24'h654321;decomp.range_s1=1;decomp.out_valid=1;decomp.out_coeff=12'h789;decomp.error=1;
  enc.busy=1;enc.reservoir=64'h0123456789abcdef;enc.bit_count=17;enc.accepted=9'h101;enc.emitted=8'h55;enc.rtmp=64'hfedcba9876543210;enc.ctmp=9;enc.ovtmp=1;enc.odtmp=32'hdeadbeef;enc.oltmp=1;enc.out_valid=1;enc.out_data=32'h12345678;enc.out_keep=4'hf;enc.out_last=1;enc.error=1;
  dec.busy=1;dec.reservoir=64'h89abcdef01234567;dec.bit_count=19;dec.words_in=8'h33;dec.values_out=9'h122;dec.rtmp=64'h76543210fedcba98;dec.ctmp=7;dec.ovtmp=1;dec.rawtmp=12'habc;dec.out_valid=1;dec.out_value=12'h321;dec.out_index=8'h77;dec.noncanonical_seen=1;dec.error=1;
  fmt.busy=1;fmt.count=10'h155;fmt.out_valid=1;fmt.out_data=32'hcafebabe;fmt.out_keep=4'hf;fmt.out_last=1;fmt.segment=1;fmt.error=1;
  pv.busy=1;pv.poly_index=2;pv.word_count=8'h5a;pv.noncanonical_seen=1;pv.error=1;pv.child_start=1;
 end endtask
 task check_zero; begin
  check_value(bits.out_valid===0&&bits.out_byte===0,"bits payload");
  check_value(bytes.out_valid===0&&bytes.out_bits===0,"bytes payload");
  check_value({comp.valid_s1,comp.numer_s1,comp.product_s1,comp.range_s1,comp.out_valid,comp.out_value,comp.error}===0,"compress stages");
  check_value({decomp.valid_s1,decomp.numer_s1,decomp.range_s1,decomp.out_valid,decomp.out_coeff,decomp.error}===0,"decompress stages");
  check_value({enc.busy,enc.reservoir,enc.bit_count,enc.accepted,enc.emitted,enc.rtmp,enc.ctmp,enc.ovtmp,enc.odtmp,enc.oltmp,enc.out_valid,enc.out_data,enc.out_keep,enc.out_last,enc.error}===0,"encode reservoir and output");
  check_value({dec.busy,dec.reservoir,dec.bit_count,dec.words_in,dec.values_out,dec.rtmp,dec.ctmp,dec.ovtmp,dec.rawtmp,dec.out_valid,dec.out_value,dec.out_index,dec.noncanonical_seen,dec.error}===0,"decode reservoir and output");
  check_value({fmt.busy,fmt.count,fmt.out_valid,fmt.out_data,fmt.out_keep,fmt.out_last,fmt.segment,fmt.error}===0,"format payload");
  check_value({pv.busy,pv.poly_index,pv.word_count,pv.noncanonical_seen,pv.error,pv.child_start}===0,"polyvec parent");
 end endtask

 initial begin
  repeat(3)@(negedge clk);rst_n=1;@(negedge clk);seed_state();
  check_value(bits.out_byte!=0&&enc.reservoir!=0&&dec.reservoir!=0&&pv.word_count!=0,"state populated");
  z_bits=1;z_bytes=1;z_comp=1;z_decomp=1;z_enc=1;z_dec=1;z_fmt=1;z_pv=1;
  @(negedge clk);check_value(zb_bits&&zb_bytes&&zb_comp&&zb_decomp&&zb_enc&&zb_dec&&zb_fmt&&zb_pv,"busy asserted");
  check_value(!(zd_bits||zd_bytes||zd_comp||zd_decomp||zd_enc||zd_dec||zd_fmt||zd_pv),"no premature done");
  z_bits=0;z_bytes=0;z_comp=0;z_decomp=0;z_enc=0;z_dec=0;z_fmt=0;z_pv=0;
  while(seen_done!=8'hff)@(negedge clk);
  done_pulses=done_pulses+1;check_zero();
  @(negedge clk);check_value(!(zd_bits||zd_bytes||zd_comp||zd_decomp||zd_enc||zd_dec||zd_fmt||zd_pv),"done one cycle");
  // Repeated scrub must have the same bounded two-cycle primitive behavior.
  z_enc=1;@(negedge clk);z_enc=0;check_value(zb_enc&&!zd_enc,"repeat busy");while(!zd_enc)@(negedge clk);check_value(enc.reservoir===0,"repeat zero");
  // Interrupt a scrub with reset; completion must be invalidated, then a fresh request succeeds.
  seed_state();z_dec=1;@(negedge clk);rst_n=0;z_dec=0;@(negedge clk);check_value(!zb_dec&&!zd_dec,"reset invalidates completion");rst_n=1;@(negedge clk);z_dec=1;@(negedge clk);z_dec=0;while(!zd_dec)@(negedge clk);check_value(dec.reservoir===0,"restart scrub from zero");
  // Clean ordinary transaction immediately after scrub.
  @(negedge clk);force bits.in_bits=8'h3c;force bits.in_valid=1'b1;force bits.out_ready=1'b1;@(negedge clk);release bits.in_valid;release bits.in_bits;check_value(b_ov&&b_out==8'h3c,"clean restart oracle");release bits.out_ready;
  $display("PASS tb_m6_codec_zeroize checks=%0d state_owner_types=8 fixed_primitive_cycles=2 child_propagation=PASS reset_interrupt=PASS clean_restart=PASS",checks);$finish;
 end
endmodule
