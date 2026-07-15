`timescale 1ns/1ps

module poly_basemul_pipe(
 input wire clk,input wire rst_n,input wire load_begin,input wire load_operand,input wire[1:0]load_domain,
 input wire a_load_we,input wire[7:0]a_load_idx,input wire[11:0]a_load_coeff,
 input wire b_load_we,input wire[7:0]b_load_idx,input wire[11:0]b_load_coeff,output wire load_ready,
 input wire start,output reg busy,output reg done,output reg error,
 input wire result_req,input wire[7:0]result_idx,output wire result_valid,output wire[11:0]result_coeff,
 output wire[1:0]result_domain,output wire result_complete,input wire result_release,
 input wire zeroize_req,output reg zeroize_busy,output reg zeroize_done);
 localparam[1:0]INVALID=0,NTT=2; localparam[2:0]IDLE=0,ISSUE=1,DRAIN=2,PUBLISH=3,DONE=4;
 localparam integer BASECASE_LATENCY=9;
 reg[2:0]state;reg[6:0]issue_pair;reg result_available;reg[11:0]gamma_d;reg[6:0]meta_pair_d;
 reg child_zeroize_req;reg[4:0]child_done_seen;wire[4:0]child_zeroize_busy,child_zeroize_done;
 wire ac,bc,rc;wire[1:0]ad,bd,rd,ao,bo,ro;wire ae,be,re;
 wire pair_req;wire av,bv;wire[11:0]a0,a1,b0,b1;
 wire[6:0]zaddr=7'd64+issue_pair[6:1];wire zneg=issue_pair[0];wire[11:0]zeta_mont,zeta_signed;
 wire[11:0]gamma_math;wire bc_valid;wire[11:0]c0,c1;wire meta_valid;wire[6:0]write_pair;wire[0:0]unused;
 wire start_ok=!busy&&!result_available&&ac&&bc&&ad==NTT&&bd==NTT;
 wire accepted;wire publish;wire source_release;
 assign pair_req=(state==ISSUE);assign accepted=start&&start_ok;
 assign publish=(state==PUBLISH);assign source_release=(state==PUBLISH);
 assign load_ready=!busy&&!zeroize_busy;assign result_domain=result_available?rd:INVALID;assign result_complete=result_available&&rc;
 zetas_rom zr(.inverse(1'b0),.addr(zaddr),.zeta(zeta_mont));
 assign zeta_signed=zneg?(zeta_mont==0?0:12'd3329-zeta_mont):zeta_mont;
 // ROM values are gamma*R. Montgomery multiplying by one removes R exactly.
 mod_mul gamma_convert(.a(zeta_signed),.b(12'd1),.c(gamma_math));
 poly_workspace wa(.clk(clk),.rst_n(rst_n),.load_begin(load_begin&&!load_operand),.load_domain(load_domain),.load_we(a_load_we),.load_idx(a_load_idx),.load_coeff(a_load_coeff),.load_ready(),.acquire_internal(accepted),.init_internal(1'b0),.init_domain(2'b0),.publish_result(1'b0),.release_internal(source_release),.owner(ao),.complete(ac),.domain(ad),.error(ae),.result_req(1'b0),.result_idx(8'b0),.result_valid(),.result_coeff(),.int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),.int_pair_rd_req(pair_req),.int_pair_rd_idx(issue_pair),.int_pair_rd_valid(av),.int_pair_rd0(a0),.int_pair_rd1(a1),.int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),.int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0),.zeroize_req(child_zeroize_req),.zeroize_busy(child_zeroize_busy[0]),.zeroize_done(child_zeroize_done[0]));
 poly_workspace wb(.clk(clk),.rst_n(rst_n),.load_begin(load_begin&&load_operand),.load_domain(load_domain),.load_we(b_load_we),.load_idx(b_load_idx),.load_coeff(b_load_coeff),.load_ready(),.acquire_internal(accepted),.init_internal(1'b0),.init_domain(2'b0),.publish_result(1'b0),.release_internal(source_release),.owner(bo),.complete(bc),.domain(bd),.error(be),.result_req(1'b0),.result_idx(8'b0),.result_valid(),.result_coeff(),.int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),.int_pair_rd_req(pair_req),.int_pair_rd_idx(issue_pair),.int_pair_rd_valid(bv),.int_pair_rd0(b0),.int_pair_rd1(b1),.int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),.int_pair_wr_en(1'b0),.int_pair_wr_idx(7'b0),.int_pair_wr0(12'b0),.int_pair_wr1(12'b0),.zeroize_req(child_zeroize_req),.zeroize_busy(child_zeroize_busy[1]),.zeroize_done(child_zeroize_done[1]));
 poly_workspace wr(.clk(clk),.rst_n(rst_n),.load_begin(1'b0),.load_domain(2'b0),.load_we(1'b0),.load_idx(8'b0),.load_coeff(12'b0),.load_ready(),.acquire_internal(1'b0),.init_internal(accepted),.init_domain(NTT),.publish_result(publish),.release_internal(1'b0),.owner(ro),.complete(rc),.domain(rd),.error(re),.result_req(result_req&&result_available),.result_idx(result_idx),.result_valid(result_valid),.result_coeff(result_coeff),.int_rd_req(1'b0),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),.int_pair_rd_req(1'b0),.int_pair_rd_idx(7'b0),.int_pair_rd_valid(),.int_pair_rd0(),.int_pair_rd1(),.int_wr_en(1'b0),.int_wr_idx(8'b0),.int_wr_coeff(12'b0),.int_pair_wr_en(bc_valid&&meta_valid),.int_pair_wr_idx(write_pair),.int_pair_wr0(c0),.int_pair_wr1(c1),.zeroize_req(child_zeroize_req),.zeroize_busy(child_zeroize_busy[2]),.zeroize_done(child_zeroize_done[2]));
 basecase_mul_pipe bm(.clk(clk),.rst_n(rst_n),.in_valid(av&&bv&&!zeroize_busy),.a0(a0),.a1(a1),.b0(b0),.b1(b1),.gamma(gamma_d),.out_valid(bc_valid),.c0(c0),.c1(c1),.zeroize_req(child_zeroize_req),.zeroize_busy(child_zeroize_busy[3]),.zeroize_done(child_zeroize_done[3]));
 fixed_latency_delay #(.PAYLOAD_WIDTH(1),.METADATA_WIDTH(7),.LATENCY(BASECASE_LATENCY)) md(.clk(clk),.rst_n(rst_n),.in_valid(av&&bv&&!zeroize_busy),.in_payload(1'b0),.in_metadata(meta_pair_d),.out_valid(meta_valid),.out_payload(unused),.out_metadata(write_pair),.zeroize_req(child_zeroize_req),.zeroize_busy(child_zeroize_busy[4]),.zeroize_done(child_zeroize_done[4]));
 always @(posedge clk)begin child_zeroize_req<=0;zeroize_done<=0;
  if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;issue_pair<=0;result_available<=0;gamma_d<=0;meta_pair_d<=0;zeroize_busy<=0;zeroize_done<=0;child_zeroize_req<=0;child_done_seen<=0;end
  else if((zeroize_req===1'b1)&&!zeroize_busy)begin state<=IDLE;busy<=0;done<=0;error<=0;issue_pair<=0;result_available<=0;gamma_d<=0;meta_pair_d<=0;zeroize_busy<=1;child_zeroize_req<=1;child_done_seen<=0;end
  else if(zeroize_busy)begin state<=IDLE;busy<=0;done<=0;error<=0;issue_pair<=0;result_available<=0;gamma_d<=0;meta_pair_d<=0;child_zeroize_req<=1;child_done_seen<=child_done_seen|child_zeroize_done;if(&(child_done_seen|child_zeroize_done))begin zeroize_busy<=0;zeroize_done<=1;child_zeroize_req<=0;child_done_seen<=0;end end
  else begin
   done<=0;if(pair_req)begin gamma_d<=gamma_math;meta_pair_d<=issue_pair;end
   if(ae||be||re)error<=1;if(start&&!start_ok)error<=1;
   if(busy&&(load_begin||a_load_we||b_load_we||result_req||result_release))error<=1;
   if(result_req&&!result_available)error<=1;if(result_release&&!busy)result_available<=0;
   if(bc_valid!=meta_valid)begin error<=1;end
   case(state)
    IDLE:if(accepted)begin busy<=1;result_available<=0;issue_pair<=0;state<=ISSUE;end
    ISSUE:if(issue_pair==127)state<=DRAIN;else issue_pair<=issue_pair+1'b1;
    DRAIN:if(bc_valid&&meta_valid&&write_pair==127)state<=PUBLISH;
    PUBLISH:state<=DONE;
    DONE:begin busy<=0;done<=1;result_available<=1;state<=IDLE;end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
