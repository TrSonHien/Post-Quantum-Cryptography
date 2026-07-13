`timescale 1ns/1ps
// OP: 0 add, 1 sub, 2 reduce, 3 NTT, 4 INTT. One shared polynomial engine.
module polyvec_elementwise_pipe #(parameter OP=0)(
 input wire clk,input wire rst_n,input wire load_begin,input wire load_operand,input wire[1:0]load_poly_idx,input wire[1:0]load_domain,
 input wire load_we,input wire[7:0]load_idx,input wire[11:0]load_coeff,output wire load_ready,
 input wire start,output reg busy,output reg done,output reg error,
 input wire result_req,input wire[1:0]result_poly_idx,input wire[7:0]result_idx,output wire result_valid,output wire[11:0]result_coeff,
 output wire[1:0]result_domain,output wire result_complete,input wire result_release);
 localparam BINARY=(OP<2),NORMAL=1,NTT=2;
 localparam[4:0]IDLE=0,BEGIN_A=1,READ_A=2,DRAIN_A=3,BEGIN_B=4,READ_B=5,DRAIN_B=6,START_CHILD=7,WAIT_CHILD=8,READ_CHILD=9,DRAIN_CHILD=10,RELEASE_CHILD=11,NEXT=12,PUBLISH=13,DONE=14;
 reg[4:0]state;reg[1:0]elem;reg[7:0]idx,idx_d,child_idx_d;reg result_available;
 wire[2:0]ac,bc,oc;wire avc,bvc,ovc,adc,bdc,odc;wire[1:0]ad,bd,od;wire ae,be,oe;
 wire accepted=start&&!busy&&!result_available&&avc&&adc&&(!BINARY||(bvc&&bdc&&bd==ad))&&((OP==3&&ad==NORMAL)||(OP==4&&ad==NTT)||(OP<3&&(ad==NORMAL||ad==NTT)));
 wire ar,br,aird,bird;wire[11:0]acoeff,bcoeff;assign ar=(state==READ_A);assign br=(state==READ_B);
 wire child_load_begin=(state==BEGIN_A)||(state==BEGIN_B);wire child_load_operand=(state==BEGIN_B);
 wire child_start=(state==START_CHILD);wire child_busy,child_done,child_error,child_load_ready;
 wire child_result_req=(state==READ_CHILD)||(state==DRAIN_CHILD);wire child_result_valid;wire[11:0]child_result_coeff;wire[1:0]child_result_domain;wire child_result_complete;
 wire child_release=(state==RELEASE_CHILD);wire output_write=child_result_valid;wire output_publish=(state==PUBLISH);wire source_release=(state==PUBLISH);
 wire[1:0]target_domain=(OP==3)?2'b10:(OP==4)?2'b01:ad;
 assign load_ready=!busy;assign result_domain=result_available?od:0;assign result_complete=result_available&&ovc;
 polyvec_workspace va(.clk(clk),.rst_n(rst_n),.load_begin(load_begin&&!load_operand),.load_poly_idx(load_poly_idx),.load_domain(load_domain),.load_we(load_we&&!load_operand),.load_poly_idx_we(load_poly_idx),.load_idx(load_idx),.load_coeff(load_coeff),.load_ready(),.acquire_internal(accepted),.init_internal(1'b0),.init_domain(2'b00),.publish_result(1'b0),.release_internal(source_release),.poly_complete(ac),.vector_complete(avc),.domain_consistent(adc),.vector_domain(ad),.error(ae),.result_req(1'b0),.result_poly_idx(2'b00),.result_idx(8'b0),.result_valid(),.result_coeff(),.int_rd_req(ar),.int_rd_poly_idx(elem),.int_rd_idx(idx),.int_rd_valid(aird),.int_rd_coeff(acoeff),.int_wr_en(1'b0),.int_wr_poly_idx(2'b00),.int_wr_idx(8'b0),.int_wr_coeff(12'b0));
 polyvec_workspace vb(.clk(clk),.rst_n(rst_n),.load_begin(load_begin&&load_operand),.load_poly_idx(load_poly_idx),.load_domain(load_domain),.load_we(load_we&&load_operand),.load_poly_idx_we(load_poly_idx),.load_idx(load_idx),.load_coeff(load_coeff),.load_ready(),.acquire_internal(accepted&&BINARY),.init_internal(1'b0),.init_domain(2'b00),.publish_result(1'b0),.release_internal(source_release&&BINARY),.poly_complete(bc),.vector_complete(bvc),.domain_consistent(bdc),.vector_domain(bd),.error(be),.result_req(1'b0),.result_poly_idx(2'b00),.result_idx(8'b0),.result_valid(),.result_coeff(),.int_rd_req(br),.int_rd_poly_idx(elem),.int_rd_idx(idx),.int_rd_valid(bird),.int_rd_coeff(bcoeff),.int_wr_en(1'b0),.int_wr_poly_idx(2'b00),.int_wr_idx(8'b0),.int_wr_coeff(12'b0));
 polyvec_workspace vo(.clk(clk),.rst_n(rst_n),.load_begin(1'b0),.load_poly_idx(2'b00),.load_domain(2'b00),.load_we(1'b0),.load_poly_idx_we(2'b00),.load_idx(8'b0),.load_coeff(12'b0),.load_ready(),.acquire_internal(1'b0),.init_internal(accepted),.init_domain(target_domain),.publish_result(output_publish),.release_internal(1'b0),.poly_complete(oc),.vector_complete(ovc),.domain_consistent(odc),.vector_domain(od),.error(oe),.result_req(result_req&&result_available),.result_poly_idx(result_poly_idx),.result_idx(result_idx),.result_valid(result_valid),.result_coeff(result_coeff),.int_rd_req(1'b0),.int_rd_poly_idx(2'b00),.int_rd_idx(8'b0),.int_rd_valid(),.int_rd_coeff(),.int_wr_en(output_write),.int_wr_poly_idx(elem),.int_wr_idx(child_idx_d),.int_wr_coeff(child_result_coeff));
 generate if(OP==0)begin:ga poly_add_pipe child(.clk(clk),.rst_n(rst_n),.load_begin(child_load_begin),.load_operand(child_load_operand),.load_domain(ad),.a_load_we(aird),.a_load_idx(idx_d),.a_load_coeff(acoeff),.b_load_we(bird),.b_load_idx(idx_d),.b_load_coeff(bcoeff),.load_ready(child_load_ready),.start(child_start),.busy(child_busy),.done(child_done),.error(child_error),.result_req(child_result_req),.result_idx(idx),.result_valid(child_result_valid),.result_coeff(child_result_coeff),.result_domain(child_result_domain),.result_complete(child_result_complete),.result_release(child_release));end
 else if(OP==1)begin:gs poly_sub_pipe child(.clk(clk),.rst_n(rst_n),.load_begin(child_load_begin),.load_operand(child_load_operand),.load_domain(ad),.a_load_we(aird),.a_load_idx(idx_d),.a_load_coeff(acoeff),.b_load_we(bird),.b_load_idx(idx_d),.b_load_coeff(bcoeff),.load_ready(child_load_ready),.start(child_start),.busy(child_busy),.done(child_done),.error(child_error),.result_req(child_result_req),.result_idx(idx),.result_valid(child_result_valid),.result_coeff(child_result_coeff),.result_domain(child_result_domain),.result_complete(child_result_complete),.result_release(child_release));end
 else if(OP==2)begin:gr poly_reduce_pipe child(.clk(clk),.rst_n(rst_n),.load_begin(child_load_begin),.load_domain(ad),.load_we(aird),.load_idx(idx_d),.load_coeff({20'd0,acoeff}),.load_ready(child_load_ready),.start(child_start),.busy(child_busy),.done(child_done),.error(child_error),.result_req(child_result_req),.result_idx(idx),.result_valid(child_result_valid),.result_coeff(child_result_coeff),.result_domain(child_result_domain),.result_complete(child_result_complete),.result_release(child_release));end
 else if(OP==3)begin:gn poly_ntt_pipe child(.clk(clk),.rst_n(rst_n),.load_begin(child_load_begin),.load_domain(ad),.load_we(aird),.load_idx(idx_d),.load_coeff(acoeff),.load_ready(child_load_ready),.start(child_start),.busy(child_busy),.done(child_done),.error(child_error),.result_req(child_result_req),.result_idx(idx),.result_valid(child_result_valid),.result_coeff(child_result_coeff),.result_domain(child_result_domain),.result_complete(child_result_complete),.result_release(child_release));end
 else begin:gi poly_intt_pipe child(.clk(clk),.rst_n(rst_n),.load_begin(child_load_begin),.load_domain(ad),.load_we(aird),.load_idx(idx_d),.load_coeff(acoeff),.load_ready(child_load_ready),.start(child_start),.busy(child_busy),.done(child_done),.error(child_error),.result_req(child_result_req),.result_idx(idx),.result_valid(child_result_valid),.result_coeff(child_result_coeff),.result_domain(child_result_domain),.result_complete(child_result_complete),.result_release(child_release));end endgenerate
 always@(posedge clk)begin
  if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;elem<=0;idx<=0;idx_d<=0;child_idx_d<=0;result_available<=0;end else begin done<=0;if(ar||br)idx_d<=idx;if(child_result_req)child_idx_d<=idx;
   if(ae||be||oe||child_error)error<=1;if(start&&!accepted)error<=1;if(busy&&(load_begin||load_we||result_req||result_release))error<=1;if(result_req&&!result_available)error<=1;if(result_release&&!busy)result_available<=0;
   case(state)
    IDLE:if(accepted)begin busy<=1;result_available<=0;elem<=0;state<=BEGIN_A;end
    BEGIN_A:begin idx<=0;state<=READ_A;end
    READ_A:if(idx==255)state<=DRAIN_A;else idx<=idx+1'b1;
    DRAIN_A:if(aird&&idx_d==255)state<=BINARY?BEGIN_B:START_CHILD;
    BEGIN_B:begin idx<=0;state<=READ_B;end
    READ_B:if(idx==255)state<=DRAIN_B;else idx<=idx+1'b1;
    DRAIN_B:if(bird&&idx_d==255)state<=START_CHILD;
    START_CHILD:state<=WAIT_CHILD;
    WAIT_CHILD:if(child_done)begin idx<=0;state<=READ_CHILD;end
    READ_CHILD:if(idx==255)state<=DRAIN_CHILD;else idx<=idx+1'b1;
    DRAIN_CHILD:if(child_result_valid&&child_idx_d==255)state<=RELEASE_CHILD;
    RELEASE_CHILD:state<=NEXT;
    NEXT:if(elem==2)state<=PUBLISH;else begin elem<=elem+1'b1;state<=BEGIN_A;end
    PUBLISH:state<=DONE;
    DONE:begin busy<=0;done<=1;result_available<=1;state<=IDLE;end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
