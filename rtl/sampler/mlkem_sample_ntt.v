`timescale 1ns/1ps
module mlkem_sample_ntt(
 input wire clk,input wire rst_n,input wire start,input wire[255:0]seed,input wire[7:0]index0,input wire[7:0]index1,
 input wire use_generic_input,input wire[271:0]generic_input,
 output reg busy,output reg done,output reg error,
 output wire out_valid,input wire out_ready,output wire[11:0]out_coeff,output wire[7:0]out_index,output wire[1:0]out_domain,
 output wire[31:0]groups_requested,output wire[31:0]candidates_accepted,output wire[31:0]candidates_rejected);
 reg child_start,req_pending;wire xi_ready,xreq_ready,xov,xlast,xctx,xbusy,xdone,xerr;wire[31:0]xdata;wire[3:0]xkeep;wire pbusy,pdone,perr,pready;wire[31:0]gexam;
 wire issue_req=busy&&xctx&&!req_pending&&pready;
 mlkem_xof x(clk,rst_n,child_start,xi_ready,seed,index0,index1,use_generic_input,generic_input,issue_req,xreq_ready,32'd3,xov,pready,xdata,xkeep,xlast,xctx,xbusy,xdone,xerr);
 sample_ntt_parser p(clk,rst_n,child_start,pbusy,pdone,perr,xov,pready,xdata[23:0],out_valid,out_ready,out_coeff,out_index,out_domain,gexam,candidates_accepted,candidates_rejected);
 assign groups_requested=gexam;
 always@(posedge clk)begin child_start<=0;done<=0;if(!rst_n)begin busy<=0;error<=0;req_pending<=0;end
  else if(start)begin if(busy)error<=1;else begin busy<=1;error<=0;req_pending<=0;child_start<=1;end end
  else if(busy)begin if(xerr||perr)begin error<=1;busy<=0;end if(issue_req&&xreq_ready)req_pending<=1;if(xov&&pready)begin if(xkeep!=4'b0111||!xlast)begin error<=1;busy<=0;end req_pending<=0;end if(pdone)begin busy<=0;done<=1;req_pending<=0;end end end
endmodule
