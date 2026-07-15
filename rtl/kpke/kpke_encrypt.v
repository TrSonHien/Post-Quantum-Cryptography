`timescale 1ns/1ps
// Deterministic FIPS 203 Algorithm 14. Input stream is ekPKE || m || r.
module kpke_encrypt(
 input wire clk,rst_n,input wire cmd_valid,output wire cmd_ready,
 input wire in_valid,output wire in_ready,input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,output wire[3:0]out_keep,output wire out_last,
 output reg busy,done,error,output reg noncanonical_seen,output reg[31:0]cycle_count,
 output reg[3:0]sample_ntt_operations,noise_operations,polyvec_ntt_operations,dot_operations,intt_operations,poly_add_operations,message_operations,
 input wire zeroize,output reg zeroize_busy,output reg zeroize_done
);
 localparam NORMAL=1,NTT=2;
 localparam[6:0]IDLE=0,INPUT=1,DEC_START=2,DEC_FEED=3,DEC_WAIT=4,
 NY_START=5,NY_WAIT=6,NE_START=7,NE_WAIT=8,E2_START=9,E2_WAIT=10,
 N_BEGIN=11,N_LOAD=12,N_START=13,N_WAIT=14,N_READ=15,N_DRAIN=16,N_RELEASE=17,
 M_START=18,M_WAIT=19,B_BEGIN=20,B_LOAD=21,B_START=22,B_WAIT=23,B_READ=24,B_DRAIN=25,B_RELEASE=26,
 I_BEGIN=27,I_LOAD=28,I_START=29,I_WAIT=30,I_READ=31,I_DRAIN=32,I_RELEASE=33,
 A_BEGIN=34,A_LOAD=35,A_START=36,A_WAIT=37,A_READ=38,A_DRAIN=39,A_RELEASE=40,
 MSG_START=41,MSG_FEED=42,MSG_WAIT=43,PACKU_START=44,PACKU_FEED=45,PACKU_WAIT=46,PACKV_START=47,PACKV_FEED=48,PACKV_WAIT=49,OUTPUT=50,SCRUB=52,WAIT_CHILD_ZERO=53;
 reg[6:0]state;reg[7:0]ek[0:1183],m[0:31],r[0:31],rho[0:31],c[0:1087];
 reg[11:0]t_hat[0:767],y[0:767],e1[0:767],e2[0:255],y_hat[0:767],a_row[0:767],dot[0:255],product[0:255],u[0:767],mu[0:255],temp[0:255],v[0:255];
 reg[9:0]word_count,linear,linear_d,out_word,pack_word;reg[7:0]idx;reg[1:0]elem,row;reg operand,vbranch,add_second;integer j;
 reg[10:0]scrub_addr;wire zeroize_req=(zeroize===1'b1);reg[10:0]child_zeroize_req,child_zeroized;wire[10:0]child_zeroize_busy,child_zeroize_done;
 wire dec_start,dec_busy,dec_done,dec_error,dec_in_ready,dec_valid,dec_nc;wire[11:0]dec_coeff;wire[7:0]dec_idx;wire[1:0]dec_domain,dec_poly;
 wire nv_start,nv_busy,nv_done,nv_error,nv_valid;wire[11:0]nv_coeff;wire[7:0]nv_idx,nv_nonce,nv_next;wire[1:0]nv_poly,nv_domain;wire[2:0]nv_samples;
 wire e2_start,e2_busy,e2_done,e2_error,e2_valid;wire[11:0]e2_coeff;wire[7:0]e2_idx;wire[1:0]e2_domain;
 wire n_begin,n_we,n_lr,n_start,n_busy,n_done,n_error,n_rv,n_rr,n_complete;wire[11:0]n_rc;wire[1:0]n_rd;
 wire mat_start,mat_busy,mat_done,mat_error,mat_valid;wire[11:0]mat_coeff;wire[7:0]mat_idx,mi0,mi1;wire[1:0]mat_poly,mat_domain;wire[2:0]mat_samples;
 wire b_begin,b_we,b_lr,b_start,b_busy,b_done,b_error,b_rv,b_complete;wire[11:0]b_rc,b_lc;wire[1:0]b_rd;
 wire i_begin,i_we,i_lr,i_start,i_busy,i_done,i_error,i_rv,i_complete;wire[11:0]i_rc;wire[1:0]i_rd;
 wire a_begin,a_lr,a_start,a_busy,a_done,a_error,a_rv,a_complete;wire[11:0]a0,a1,a_rc;wire[1:0]a_rd;
 wire msg_start,msg_busy,msg_done,msg_error,msg_in_ready,msg_valid;wire[11:0]msg_coeff;wire[7:0]msg_idx;wire[1:0]msg_domain;
 wire pu_start,pu_busy,pu_done,pu_error,pu_in_ready,pu_valid;wire[31:0]pu_data;wire[3:0]pu_keep;wire pu_last;wire[1:0]pu_poly;
 wire pv_start,pv_busy,pv_done,pv_error,pv_in_ready,pv_valid;wire[31:0]pv_data;wire[3:0]pv_keep;wire pv_last;
 wire[255:0]r_packed={r[31],r[30],r[29],r[28],r[27],r[26],r[25],r[24],r[23],r[22],r[21],r[20],r[19],r[18],r[17],r[16],r[15],r[14],r[13],r[12],r[11],r[10],r[9],r[8],r[7],r[6],r[5],r[4],r[3],r[2],r[1],r[0]};
 wire[255:0]rho_packed={rho[31],rho[30],rho[29],rho[28],rho[27],rho[26],rho[25],rho[24],rho[23],rho[22],rho[21],rho[20],rho[19],rho[18],rho[17],rho[16],rho[15],rho[14],rho[13],rho[12],rho[11],rho[10],rho[9],rho[8],rho[7],rho[6],rho[5],rho[4],rho[3],rho[2],rho[1],rho[0]};
 assign cmd_ready=state==IDLE;assign in_ready=state==INPUT;assign out_valid=state==OUTPUT;assign out_keep=4'hf;assign out_last=state==OUTPUT&&out_word==271;assign out_data={c[out_word*4+3],c[out_word*4+2],c[out_word*4+1],c[out_word*4]};
 assign dec_start=state==DEC_START;
 polyvec_decode12_pipe dec(clk,rst_n,dec_start,NTT,dec_busy,dec_done,dec_error,state==DEC_FEED,dec_in_ready,{ek[word_count*4+3],ek[word_count*4+2],ek[word_count*4+1],ek[word_count*4]},4'hf,word_count==287,dec_valid,1'b1,dec_coeff,dec_idx,dec_domain,dec_poly,dec_nc,child_zeroize_req[0],child_zeroize_busy[0],child_zeroize_done[0]);
 assign nv_start=state==NY_START||state==NE_START;
 kpke_noise_vector_sampler nv(clk,rst_n,nv_start,r_packed,(state==NE_START||state==NE_WAIT)?8'd3:8'd0,2'd2,nv_busy,nv_done,nv_error,nv_valid,1'b1,nv_coeff,nv_idx,nv_poly,nv_domain,nv_nonce,nv_next,nv_samples,child_zeroize_req[1],child_zeroize_busy[1],child_zeroize_done[1]);
 assign e2_start=state==E2_START;
 mlkem_noise_sampler e2s(clk,rst_n,e2_start,r_packed,8'd6,2'd2,e2_busy,e2_done,e2_error,e2_valid,1'b1,e2_coeff,e2_idx,e2_domain,child_zeroize_req[2],child_zeroize_busy[2],child_zeroize_done[2]);
 assign n_begin=state==N_BEGIN;assign n_we=state==N_LOAD;assign n_start=state==N_START;assign n_rr=state==N_READ;
 polyvec_ntt_pipe pn(clk,rst_n,n_begin,1'b0,elem,NORMAL,n_we,idx,y[{elem,idx}],n_lr,n_start,n_busy,n_done,n_error,n_rr,elem,idx,n_rv,n_rc,n_rd,n_complete,state==N_RELEASE,child_zeroize_req[3],child_zeroize_busy[3],child_zeroize_done[3]);
 assign mat_start=state==M_START;
 kpke_matrix_row_sampler mr(clk,rst_n,mat_start,rho_packed,row,1'b1,mat_busy,mat_done,mat_error,mat_valid,1'b1,mat_coeff,mat_idx,mat_poly,mat_domain,mi0,mi1,mat_samples,child_zeroize_req[4],child_zeroize_busy[4],child_zeroize_done[4]);
 assign b_begin=state==B_BEGIN;assign b_we=state==B_LOAD;assign b_start=state==B_START;
 assign b_lc=operand?y_hat[{elem,idx}]:(vbranch?t_hat[{elem,idx}]:a_row[{elem,idx}]);
 polyvec_basemul_acc_pipe ba(clk,rst_n,b_begin,operand,elem,NTT,b_we,idx,b_lc,b_lr,b_start,b_busy,b_done,b_error,state==B_READ,idx,b_rv,b_rc,b_rd,b_complete,state==B_RELEASE,child_zeroize_req[5],child_zeroize_busy[5],child_zeroize_done[5]);
 assign i_begin=state==I_BEGIN;assign i_we=state==I_LOAD;assign i_start=state==I_START;
 poly_intt_pipe pi(clk,rst_n,i_begin,NTT,i_we,idx,dot[idx],i_lr,i_start,i_busy,i_done,i_error,state==I_READ,idx,i_rv,i_rc,i_rd,i_complete,state==I_RELEASE,child_zeroize_req[6],child_zeroize_busy[6],child_zeroize_done[6]);
 assign a_begin=state==A_BEGIN;assign a_start=state==A_START;
 assign a0=add_second?temp[idx]:product[idx];assign a1=vbranch?(add_second?mu[idx]:e2[idx]):e1[{row,idx}];
 poly_add_pipe pa(clk,rst_n,a_begin,operand,NORMAL,state==A_LOAD&&!operand,idx,a0,state==A_LOAD&&operand,idx,a1,a_lr,a_start,a_busy,a_done,a_error,state==A_READ,idx,a_rv,a_rc,a_rd,a_complete,state==A_RELEASE,child_zeroize_req[7],child_zeroize_busy[7],child_zeroize_done[7]);
 assign msg_start=state==MSG_START;
 message_to_poly_pipe mp(clk,rst_n,msg_start,msg_busy,msg_done,msg_error,state==MSG_FEED,msg_in_ready,{m[word_count*4+3],m[word_count*4+2],m[word_count*4+1],m[word_count*4]},4'hf,word_count==7,msg_valid,1'b1,msg_coeff,msg_idx,msg_domain,child_zeroize_req[8],child_zeroize_busy[8],child_zeroize_done[8]);
 assign pu_start=state==PACKU_START;
 polyvec_compress_encode10_pipe pcu(clk,rst_n,pu_start,NORMAL,pu_busy,pu_done,pu_error,state==PACKU_FEED,pu_in_ready,u[linear],pu_valid,1'b1,pu_data,pu_keep,pu_last,pu_poly,child_zeroize_req[9],child_zeroize_busy[9],child_zeroize_done[9]);
 assign pv_start=state==PACKV_START;
 poly_compress_encode_pipe #(.D(4)) pcv(clk,rst_n,pv_start,NORMAL,pv_busy,pv_done,pv_error,state==PACKV_FEED,pv_in_ready,v[idx],pv_valid,1'b1,pv_data,pv_keep,pv_last,child_zeroize_req[10],child_zeroize_busy[10],child_zeroize_done[10]);
 always@(posedge clk)begin
  if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;noncanonical_seen<=0;cycle_count<=0;word_count<=0;linear<=0;linear_d<=0;idx<=0;elem<=0;row<=0;operand<=0;vbranch<=0;add_second<=0;out_word<=0;pack_word<=0;sample_ntt_operations<=0;noise_operations<=0;polyvec_ntt_operations<=0;dot_operations<=0;intt_operations<=0;poly_add_operations<=0;message_operations<=0;scrub_addr<=0;child_zeroize_req<=0;child_zeroized<=0;zeroize_busy<=0;zeroize_done<=0;
  end else begin
   done<=0;zeroize_done<=0;if(busy)cycle_count<=cycle_count+1;if(cmd_valid&&!cmd_ready&&!zeroize_req)error<=1;if(in_valid&&!in_ready&&!zeroize_busy)error<=1;if(dec_error||nv_error||e2_error||n_error||mat_error||b_error||i_error||a_error||msg_error||pu_error||pv_error)error<=1;if(dec_nc)noncanonical_seen<=1;
   if(dec_valid)t_hat[{dec_poly,dec_idx}]<=dec_coeff;if(nv_valid)begin if(state==NY_WAIT)y[{nv_poly,nv_idx}]<=nv_coeff;else e1[{nv_poly,nv_idx}]<=nv_coeff;end if(e2_valid)e2[e2_idx]<=e2_coeff;
   if(n_rr)linear_d<={elem,idx};if(n_rv)y_hat[linear_d]<=n_rc;if(mat_valid)a_row[{mat_poly,mat_idx}]<=mat_coeff;
   if(state==B_READ)linear_d<={2'b0,idx};if(b_rv)dot[linear_d[7:0]]<=b_rc;if(state==I_READ)linear_d<={2'b0,idx};if(i_rv)product[linear_d[7:0]]<=i_rc;
   if(state==A_READ)linear_d<={2'b0,idx};if(a_rv)begin if(vbranch)begin if(add_second)v[linear_d[7:0]]<=a_rc;else temp[linear_d[7:0]]<=a_rc;end else u[{row,linear_d[7:0]}]<=a_rc;end
   if(msg_valid)mu[msg_idx]<=msg_coeff;
   if(pu_valid)begin c[pack_word*4]<=pu_data[7:0];c[pack_word*4+1]<=pu_data[15:8];c[pack_word*4+2]<=pu_data[23:16];c[pack_word*4+3]<=pu_data[31:24];pack_word<=pack_word+1'b1;end
   if(pv_valid)begin c[(240+pack_word)*4]<=pv_data[7:0];c[(240+pack_word)*4+1]<=pv_data[15:8];c[(240+pack_word)*4+2]<=pv_data[23:16];c[(240+pack_word)*4+3]<=pv_data[31:24];pack_word<=pack_word+1'b1;end
   if(zeroize_busy)begin child_zeroized<=child_zeroized|child_zeroize_done;child_zeroize_req<=child_zeroize_req&~child_zeroize_done;end
   if(zeroize_req&&!zeroize_busy)begin state<=SCRUB;busy<=1;done<=0;error<=0;noncanonical_seen<=0;zeroize_busy<=1;child_zeroize_req<=11'h7ff;child_zeroized<=0;scrub_addr<=0;end
   else case(state)
    IDLE:if(cmd_valid)begin busy<=1;error<=0;noncanonical_seen<=0;cycle_count<=0;word_count<=0;sample_ntt_operations<=0;noise_operations<=0;polyvec_ntt_operations<=0;dot_operations<=0;intt_operations<=0;poly_add_operations<=0;message_operations<=0;state<=INPUT;end
    INPUT:if(in_valid)begin if(in_keep!=4'hf||in_last!=(word_count==311))begin error<=1;busy<=0;state<=IDLE;end else begin if(word_count<296)begin ek[word_count*4]<=in_data[7:0];ek[word_count*4+1]<=in_data[15:8];ek[word_count*4+2]<=in_data[23:16];ek[word_count*4+3]<=in_data[31:24];end else if(word_count<304)begin m[(word_count-296)*4]<=in_data[7:0];m[(word_count-296)*4+1]<=in_data[15:8];m[(word_count-296)*4+2]<=in_data[23:16];m[(word_count-296)*4+3]<=in_data[31:24];end else begin r[(word_count-304)*4]<=in_data[7:0];r[(word_count-304)*4+1]<=in_data[15:8];r[(word_count-304)*4+2]<=in_data[23:16];r[(word_count-304)*4+3]<=in_data[31:24];end if(word_count==311)begin for(j=0;j<32;j=j+1)rho[j]<=ek[1152+j];state<=DEC_START;end else word_count<=word_count+1'b1;end end
    DEC_START:begin word_count<=0;state<=DEC_FEED;end DEC_FEED:if(dec_in_ready)begin if(word_count==287)state<=DEC_WAIT;else word_count<=word_count+1'b1;end DEC_WAIT:if(dec_done)state<=NY_START;
    NY_START:begin noise_operations<=noise_operations+3;state<=NY_WAIT;end NY_WAIT:if(nv_done)state<=NE_START;NE_START:begin noise_operations<=noise_operations+3;state<=NE_WAIT;end NE_WAIT:if(nv_done)state<=E2_START;E2_START:begin noise_operations<=noise_operations+1;state<=E2_WAIT;end E2_WAIT:if(e2_done)begin elem<=0;idx<=0;state<=N_BEGIN;end
    N_BEGIN:begin idx<=0;state<=N_LOAD;end N_LOAD:if(n_lr)begin if(idx==255)begin if(elem==2)state<=N_START;else begin elem<=elem+1'b1;state<=N_BEGIN;end end else idx<=idx+1'b1;end N_START:begin polyvec_ntt_operations<=polyvec_ntt_operations+1;state<=N_WAIT;end N_WAIT:if(n_done)begin elem<=0;idx<=0;state<=N_READ;end N_READ:if(idx==255)state<=N_DRAIN;else idx<=idx+1'b1;N_DRAIN:if(n_rv&&linear_d[7:0]==255)begin if(elem==2)state<=N_RELEASE;else begin elem<=elem+1'b1;idx<=0;state<=N_READ;end end N_RELEASE:begin row<=0;vbranch<=0;state<=M_START;end
    M_START:begin sample_ntt_operations<=sample_ntt_operations+3;state<=M_WAIT;end M_WAIT:if(mat_done)begin operand<=0;elem<=0;idx<=0;state<=B_BEGIN;end
    B_BEGIN:begin idx<=0;state<=B_LOAD;end B_LOAD:if(b_lr)begin if(idx==255)begin if(elem==2)begin if(!operand)begin operand<=1;elem<=0;state<=B_BEGIN;end else state<=B_START;end else begin elem<=elem+1'b1;state<=B_BEGIN;end end else idx<=idx+1'b1;end B_START:begin dot_operations<=dot_operations+1;state<=B_WAIT;end B_WAIT:if(b_done)begin idx<=0;state<=B_READ;end B_READ:if(idx==255)state<=B_DRAIN;else idx<=idx+1'b1;B_DRAIN:if(b_rv&&linear_d[7:0]==255)state<=B_RELEASE;B_RELEASE:begin idx<=0;state<=I_BEGIN;end
    I_BEGIN:begin idx<=0;state<=I_LOAD;end I_LOAD:if(i_lr)begin if(idx==255)state<=I_START;else idx<=idx+1'b1;end I_START:begin intt_operations<=intt_operations+1;state<=I_WAIT;end I_WAIT:if(i_done)begin idx<=0;state<=I_READ;end I_READ:if(idx==255)state<=I_DRAIN;else idx<=idx+1'b1;I_DRAIN:if(i_rv&&linear_d[7:0]==255)state<=I_RELEASE;I_RELEASE:begin operand<=0;add_second<=0;idx<=0;state<=A_BEGIN;end
    A_BEGIN:begin idx<=0;state<=A_LOAD;end A_LOAD:if(a_lr)begin if(idx==255)begin if(!operand)begin operand<=1;state<=A_BEGIN;end else state<=A_START;end else idx<=idx+1'b1;end A_START:begin poly_add_operations<=poly_add_operations+1;state<=A_WAIT;end A_WAIT:if(a_done)begin idx<=0;state<=A_READ;end A_READ:if(idx==255)state<=A_DRAIN;else idx<=idx+1'b1;A_DRAIN:if(a_rv&&linear_d[7:0]==255)state<=A_RELEASE;
    A_RELEASE:if(!vbranch)begin if(row==2)state<=MSG_START;else begin row<=row+1'b1;state<=M_START;end end else if(!add_second)begin add_second<=1;operand<=0;state<=A_BEGIN;end else state<=PACKU_START;
    MSG_START:begin word_count<=0;message_operations<=message_operations+1;state<=MSG_FEED;end MSG_FEED:if(msg_in_ready)begin if(word_count==7)state<=MSG_WAIT;else word_count<=word_count+1'b1;end MSG_WAIT:if(msg_done)begin vbranch<=1;operand<=0;elem<=0;idx<=0;state<=B_BEGIN;end
    PACKU_START:begin linear<=0;pack_word<=0;state<=PACKU_FEED;end PACKU_FEED:if(pu_in_ready)begin if(linear==767)state<=PACKU_WAIT;else linear<=linear+1'b1;end PACKU_WAIT:if(pu_done)begin pack_word<=0;idx<=0;state<=PACKV_START;end
    PACKV_START:begin idx<=0;state<=PACKV_FEED;end PACKV_FEED:if(pv_in_ready)begin if(idx==255)state<=PACKV_WAIT;else idx<=idx+1'b1;end PACKV_WAIT:if(pv_done)begin out_word<=0;state<=OUTPUT;end
    OUTPUT:if(out_valid&&out_ready)begin if(out_word==271)begin busy<=0;done<=1;state<=IDLE;end else out_word<=out_word+1'b1;end
    SCRUB:begin
     if(scrub_addr<32)begin m[scrub_addr]<=0;r[scrub_addr]<=0;rho[scrub_addr]<=0;end
     if(scrub_addr<1184)ek[scrub_addr]<=0;if(scrub_addr<1088)c[scrub_addr]<=0;
     if(scrub_addr<768)begin t_hat[scrub_addr]<=0;y[scrub_addr]<=0;e1[scrub_addr]<=0;y_hat[scrub_addr]<=0;a_row[scrub_addr]<=0;u[scrub_addr]<=0;end
     if(scrub_addr<256)begin e2[scrub_addr]<=0;dot[scrub_addr]<=0;product[scrub_addr]<=0;mu[scrub_addr]<=0;temp[scrub_addr]<=0;v[scrub_addr]<=0;end
     if(scrub_addr==1183)begin scrub_addr<=0;state<=WAIT_CHILD_ZERO;end else scrub_addr<=scrub_addr+1'b1;
    end
    WAIT_CHILD_ZERO:begin
     word_count<=0;linear<=0;linear_d<=0;idx<=0;elem<=0;row<=0;operand<=0;vbranch<=0;add_second<=0;out_word<=0;pack_word<=0;cycle_count<=0;
     sample_ntt_operations<=0;noise_operations<=0;polyvec_ntt_operations<=0;dot_operations<=0;intt_operations<=0;poly_add_operations<=0;message_operations<=0;
     if(&(child_zeroized|child_zeroize_done))begin child_zeroize_req<=0;child_zeroized<=0;zeroize_busy<=0;zeroize_done<=1;busy<=0;state<=IDLE;end
    end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
