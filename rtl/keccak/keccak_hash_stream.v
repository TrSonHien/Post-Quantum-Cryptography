`timescale 1ns/1ps

module keccak_hash_stream (
    input wire clk,input wire rst_n,
    input wire cmd_valid,output wire cmd_ready,input wire [1:0] mode,
    input wire [31:0] msg_len_bytes,input wire [31:0] out_len_bytes,
    input wire in_valid,output wire in_ready,input wire [31:0] in_data,
    input wire [3:0] in_keep,input wire in_last,
    output wire out_valid,input wire out_ready,output wire [31:0] out_data,
    output wire [3:0] out_keep,output wire out_last,
    output reg busy,output reg done,output reg error
);
    localparam IDLE=3'd0,INIT=3'd1,INPUT=3'd2,FINAL=3'd3,
               WAIT_SQ=3'd4,REQ_SQ=3'd5,OUTPUT=3'd6;
    reg [2:0] state;reg input_grace;
    reg [1:0] mode_reg;reg [31:0] msg_remaining,out_len_reg;
    wire ci_ready,cf_ready,ca_ready,cs_ready,cv,cap,csp,cbusy,cdone,cerror;
    wire cov;wire [31:0] cod;wire [3:0] cok;wire col;
    wire ci_valid=(state==INIT);wire cf_valid=(state==FINAL);
    wire cs_valid=(state==REQ_SQ);
    wire [2:0] expected_count=(msg_remaining>=4)?3'd4:msg_remaining[2:0];
    wire [3:0] expected_keep=(expected_count==1)?4'b0001:(expected_count==2)?4'b0011:(expected_count==3)?4'b0111:4'b1111;
    wire expected_last=(msg_remaining<=4);
    wire input_ok=(in_keep==expected_keep)&&(in_last==expected_last);
    wire ca_valid=(state==INPUT)&&in_valid&&input_ok;
    assign cmd_ready=(state==IDLE);
    assign in_ready=(state==INPUT)&&ca_ready;
    assign out_valid=(state==OUTPUT)&&cov;assign out_data=cod;assign out_keep=cok;assign out_last=col;

    keccak_sponge_ctx u_ctx(
      .clk(clk),.rst_n(rst_n),.init_valid(ci_valid),.init_ready(ci_ready),.mode(mode_reg),
      .finalize_valid(cf_valid),.finalize_ready(cf_ready),.context_valid(cv),
      .absorb_phase(cap),.squeeze_phase(csp),.busy(cbusy),.done(cdone),.error(cerror),
      .absorb_valid(ca_valid),.absorb_ready(ca_ready),.absorb_data(in_data),.absorb_keep(in_keep),
      .squeeze_req_valid(cs_valid),.squeeze_req_ready(cs_ready),.squeeze_len_bytes(out_len_reg),
      .out_valid(cov),.out_ready((state==OUTPUT)&&out_ready),.out_data(cod),.out_keep(cok),.out_last(col));

    always @(posedge clk) begin
      if(!rst_n)begin state<=IDLE;busy<=0;done<=0;error<=0;mode_reg<=0;msg_remaining<=0;out_len_reg<=0;input_grace<=0;end
      else begin
        if(input_grace)input_grace<=0;
        done<=0;if(cerror)begin error<=1;`ifdef M5_DEBUG $display("HASH_ERR ctx");`endif end
        if(cmd_valid&&busy)begin error<=1;`ifdef M5_DEBUG $display("HASH_ERR cmd_busy");`endif end
        if(in_valid&&busy&&state>=FINAL&&!input_grace)begin error<=1;`ifdef M5_DEBUG $display("HASH_ERR extra state=%0d",state);`endif end
        case(state)
          IDLE:if(cmd_valid)begin
            if((mode==0&&out_len_bytes!=32)||(mode==1&&out_len_bytes!=64)||
               (mode>=2&&out_len_bytes==0))begin error<=1;busy<=0;end
            else begin mode_reg<=mode;msg_remaining<=msg_len_bytes;out_len_reg<=out_len_bytes;busy<=1;error<=0;input_grace<=0;state<=INIT;end
          end
          INIT:if(ci_ready)state<=(msg_remaining==0)?FINAL:INPUT;
          INPUT:if(in_valid&&in_ready)begin
            if(!input_ok)begin error<=1;`ifdef M5_DEBUG $display("HASH_ERR input expected=%b/%b got=%b/%b rem=%0d",expected_keep,expected_last,in_keep,in_last,msg_remaining);`endif busy<=0;state<=IDLE;end
            else begin msg_remaining<=msg_remaining-expected_count;if(expected_last)begin state<=FINAL;input_grace<=1;end end
          end
          FINAL:if(cf_ready)state<=WAIT_SQ;
          WAIT_SQ:if(csp)state<=REQ_SQ;
          REQ_SQ:if(cs_ready)state<=OUTPUT;
          OUTPUT:if(cov&&out_ready&&col)begin busy<=0;done<=1;state<=IDLE;end
          default:begin error<=1;busy<=0;state<=IDLE;end
        endcase
      end
    end
endmodule
