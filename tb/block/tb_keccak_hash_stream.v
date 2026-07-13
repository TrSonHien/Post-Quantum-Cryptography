`timescale 1ns/1ps
module tb_keccak_hash_stream;
wire clk,rst_n,cmd_valid,cmd_ready;wire[1:0]mode;wire[31:0]mlen,olen;wire iv,ir;wire[31:0]id;wire[3:0]ik;wire il,ov,orr;wire[31:0]od;wire[3:0]ok;wire ol,busy,done,error;
keccak_stream_test_driver #(.FILTER_MODE(-1)) driver(.clk(clk),.rst_n(rst_n),.cmd_valid(cmd_valid),.cmd_ready(cmd_ready),.mode(mode),.msg_len_bytes(mlen),.out_len_bytes(olen),.in_valid(iv),.in_ready(ir),.in_data(id),.in_keep(ik),.in_last(il),.out_valid(ov),.out_ready(orr),.out_data(od),.out_keep(ok),.out_last(ol),.busy(busy),.done(done),.error(error));
keccak_hash_stream dut(.clk(clk),.rst_n(rst_n),.cmd_valid(cmd_valid),.cmd_ready(cmd_ready),.mode(mode),.msg_len_bytes(mlen),.out_len_bytes(olen),.in_valid(iv),.in_ready(ir),.in_data(id),.in_keep(ik),.in_last(il),.out_valid(ov),.out_ready(orr),.out_data(od),.out_keep(ok),.out_last(ol),.busy(busy),.done(done),.error(error));
endmodule
