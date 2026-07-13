`timescale 1ns/1ps
module tb_poly_ntt_intt_roundtrip;
 initial if($test$plusargs("DEBUG_WAVES"))begin $dumpfile("sim/waves/tb_poly_ntt_intt_roundtrip.vcd");$dumpvars(0,tb_poly_ntt_intt_roundtrip);end
 reg clk=0,rst_n=0;
 reg f_load_begin=0,f_load_we=0,f_start=0,f_result_req=0,f_result_release=0;reg[1:0]f_load_domain=1;reg[7:0]f_load_idx=0,f_result_idx=0;reg[11:0]f_load_coeff=0;
 wire f_load_ready,f_busy,f_done,f_error,f_result_valid,f_result_complete;wire[11:0]f_result_coeff;wire[1:0]f_result_domain;
 reg i_load_begin=0,i_load_we=0,i_start=0,i_result_req=0,i_result_release=0;reg[1:0]i_load_domain=2;reg[7:0]i_load_idx=0,i_result_idx=0;reg[11:0]i_load_coeff=0;
 wire i_load_ready,i_busy,i_done,i_error,i_result_valid,i_result_complete;wire[11:0]i_result_coeff;wire[1:0]i_result_domain;
 reg[11:0]mem[0:23039];integer v,j,checks=0,fc,ic;string vector_file;
 poly_ntt_pipe fwd(.clk(clk),.rst_n(rst_n),.load_begin(f_load_begin),.load_domain(f_load_domain),.load_we(f_load_we),.load_idx(f_load_idx),.load_coeff(f_load_coeff),.load_ready(f_load_ready),.start(f_start),.busy(f_busy),.done(f_done),.error(f_error),.result_req(f_result_req),.result_idx(f_result_idx),.result_valid(f_result_valid),.result_coeff(f_result_coeff),.result_domain(f_result_domain),.result_complete(f_result_complete),.result_release(f_result_release));
 poly_intt_pipe inv(.clk(clk),.rst_n(rst_n),.load_begin(i_load_begin),.load_domain(i_load_domain),.load_we(i_load_we),.load_idx(i_load_idx),.load_coeff(i_load_coeff),.load_ready(i_load_ready),.start(i_start),.busy(i_busy),.done(i_done),.error(i_error),.result_req(i_result_req),.result_idx(i_result_idx),.result_valid(i_result_valid),.result_coeff(i_result_coeff),.result_domain(i_result_domain),.result_complete(i_result_complete),.result_release(i_result_release));
 always #5 clk=~clk;
 task wait_f;begin fc=0;while(!f_done&&fc<2200)begin@(negedge clk);fc=fc+1;end if(!f_done)$fatal(1,"fwd timeout");end endtask
 task wait_i;begin ic=0;while(!i_done&&ic<2400)begin@(negedge clk);ic=ic+1;end if(!i_done)$fatal(1,"inv timeout");end endtask
 initial begin vector_file="sim/outputs/poly_roundtrip.mem";if($value$plusargs("VECTOR_FILE=%s",vector_file))begin end $readmemh(vector_file,mem);rst_n=0;repeat(3)@(negedge clk);rst_n=1;repeat(2)@(negedge clk);
  for(v=0;v<30;v=v+1)begin
   f_load_begin=1;@(negedge clk);f_load_begin=0;for(j=0;j<256;j=j+1)begin f_load_we=1;f_load_idx=j;f_load_coeff=mem[v*768+j];@(negedge clk);end f_load_we=0;f_start=1;@(negedge clk);f_start=0;wait_f();
   i_load_begin=1;@(negedge clk);i_load_begin=0;for(j=0;j<256;j=j+1)begin f_result_req=1;f_result_idx=j;@(posedge clk);#1;if(!f_result_valid||f_result_coeff!==mem[v*768+256+j])$fatal(1,"roundtrip intermediate mismatch v=%0d i=%0d",v,j);checks=checks+1;@(negedge clk);i_load_we=1;i_load_idx=j;i_load_coeff=f_result_coeff;@(posedge clk);#1;i_load_we=0;end f_result_req=0;@(negedge clk);f_result_release=1;@(negedge clk);f_result_release=0;
   i_start=1;@(negedge clk);i_start=0;wait_i();for(j=0;j<256;j=j+1)begin i_result_req=1;i_result_idx=j;@(posedge clk);#1;if(!i_result_valid||i_result_coeff!==mem[v*768+512+j])$fatal(1,"roundtrip final mismatch v=%0d i=%0d",v,j);checks=checks+1;@(negedge clk);end i_result_req=0;i_result_release=1;@(negedge clk);i_result_release=0;
  end
  $display("POLY_ROUNDTRIP vectors=30 forward_comparisons=7680 final_comparisons=7680 fwd_cycles=%0d inv_cycles=%0d",fc,ic);$display("PASS tb_poly_ntt_intt_roundtrip");$finish;end
 initial begin repeat(400000)@(posedge clk);$fatal(1,"roundtrip global watchdog");end
endmodule
