`timescale 1ns/1ps
// One-child serialized K=3 codec. ENCODE=1 selects coefficient-to-byte flow.
module polyvec_codec_pipe #(parameter integer D=12,parameter integer ENCODE=1,parameter integer COMPRESS=0)(
 input wire clk,input wire rst_n,input wire start,input wire[1:0] domain,
 output reg busy,output reg done,output reg error,
 input wire coeff_in_valid,output wire coeff_in_ready,input wire[11:0] coeff_in,
 input wire byte_in_valid,output wire byte_in_ready,input wire[31:0] byte_in_data,input wire[3:0] byte_in_keep,input wire byte_in_last,
 output wire byte_out_valid,input wire byte_out_ready,output wire[31:0] byte_out_data,output wire[3:0] byte_out_keep,output wire byte_out_last,
 output wire coeff_out_valid,input wire coeff_out_ready,output wire[11:0] coeff_out,output wire[7:0] coeff_out_index,output wire[1:0] coeff_out_domain,
 output reg[1:0] poly_index,output reg noncanonical_seen);
 reg child_start;reg[7:0]word_count;
 wire cbusy,cdone,cerr,ce_ir,ce_ov,ce_last,cd_ir,cd_ov,cd_nc;wire[31:0]ce_data;wire[3:0]ce_keep;wire[11:0]cd_coeff;wire[7:0]cd_idx;wire[1:0]cd_domain;
 generate if(ENCODE)begin:ge
  if(COMPRESS) poly_compress_encode_pipe #(.D(D))c(clk,rst_n,child_start,domain,cbusy,cdone,cerr,coeff_in_valid&&busy,ce_ir,coeff_in,ce_ov,byte_out_ready,ce_data,ce_keep,ce_last);
  else poly_encode12_pipe c(clk,rst_n,child_start,domain,cbusy,cdone,cerr,coeff_in_valid&&busy,ce_ir,coeff_in,ce_ov,byte_out_ready,ce_data,ce_keep,ce_last);
 end else begin:gd
  if(COMPRESS) poly_decode_decompress_pipe #(.D(D))c(clk,rst_n,child_start,cbusy,cdone,cerr,byte_in_valid&&busy,cd_ir,byte_in_data,byte_in_keep,(word_count==8*D-1),cd_ov,coeff_out_ready,cd_coeff,cd_idx,cd_domain);
  else poly_decode12_pipe c(clk,rst_n,child_start,domain,cbusy,cdone,cerr,byte_in_valid&&busy,cd_ir,byte_in_data,byte_in_keep,(word_count==8*D-1),cd_ov,coeff_out_ready,cd_coeff,cd_idx,cd_domain,cd_nc);
 end endgenerate
 assign coeff_in_ready=ENCODE&&busy&&ce_ir;assign byte_in_ready=!ENCODE&&busy&&cd_ir;
 assign byte_out_valid=ENCODE&&ce_ov;assign byte_out_data=ce_data;assign byte_out_keep=ce_keep;assign byte_out_last=ce_last&&(poly_index==2);
 assign coeff_out_valid=!ENCODE&&cd_ov;assign coeff_out=cd_coeff;assign coeff_out_index=cd_idx;assign coeff_out_domain=cd_domain;
 always@(posedge clk)begin child_start<=0;done<=0;if(!rst_n)begin busy<=0;error<=0;poly_index<=0;word_count<=0;noncanonical_seen<=0;end
  else if(start)begin if(busy)error<=1;else begin busy<=1;error<=0;poly_index<=0;word_count<=0;noncanonical_seen<=0;child_start<=1;end end
  else if(busy)begin if(cerr)begin error<=1;busy<=0;end
   if(!ENCODE&&byte_in_valid&&byte_in_ready)begin if(byte_in_keep!=4'hf||byte_in_last!=((poly_index==2)&&(word_count==8*D-1)))begin error<=1;busy<=0;end else if(word_count==8*D-1)word_count<=0;else word_count<=word_count+1;end
   if(!ENCODE&&cd_nc)noncanonical_seen<=1;
   if(cdone)begin if(poly_index==2)begin busy<=0;done<=1;end else begin poly_index<=poly_index+1;child_start<=1;end end
  end end
endmodule
