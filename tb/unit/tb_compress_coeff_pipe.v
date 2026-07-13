`timescale 1ns/1ps
module tb_compress_coeff_pipe #(parameter integer D=10);
 reg clk=0,rst_n=0,iv=0;reg[11:0]x;wire ov,err;wire[11:0]y;integer fd,rc,dv,checks=0,cycle=0;reg[11:0]xi,ex;reg[11:0]q[0:7];string file;always#5 clk=~clk;
 compress_coeff_pipe #(.D(D)) dut(clk,rst_n,iv,x,ov,y,err);
 initial begin if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  while(!$feof(fd))begin rc=$fscanf(fd,"%d %h %h\n",dv,xi,ex);if(rc==3&&dv==D)begin @(negedge clk);iv=1;x=xi;q[cycle%8]=ex;cycle=cycle+1;end end
  @(negedge clk);iv=0;repeat(6)@(negedge clk);if(checks!=(3329))$fatal(1,"count %0d",checks);if(err)$fatal(1,"error");
  $display("PASS tb_compress_coeff_pipe D=%0d checks=%0d latency=2 ii=1",D,checks);$finish;end
 always@(posedge clk)if(rst_n&&ov)begin if(y!==q[checks%8])$fatal(1,"D=%0d idx=%0d exp=%0d got=%0d",D,checks,q[checks%8],y);checks=checks+1;end
endmodule
