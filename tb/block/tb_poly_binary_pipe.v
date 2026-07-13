`timescale 1ns/1ps
module tb_poly_binary_pipe #(parameter OP_SUB=0,parameter VECTOR_FILE="sim/outputs/poly_add.mem");
 initial if($test$plusargs("DEBUG_WAVES"))begin $dumpfile(OP_SUB?"sim/waves/tb_poly_sub_pipe.vcd":"sim/waves/tb_poly_add_pipe.vcd");$dumpvars(0,tb_poly_binary_pipe);end
 reg clk=0,rst_n=0,load_begin=0,load_operand=0,a_load_we=0,b_load_we=0,start=0,result_req=0,result_release=0;
 reg[1:0]load_domain=0;reg[7:0]a_load_idx=0,b_load_idx=0,result_idx=0;reg[11:0]a_load_coeff=0,b_load_coeff=0;
 wire load_ready,busy,done,error,result_valid,result_complete;wire[11:0]result_coeff;wire[1:0]result_domain;
 reg[11:0]mem[0:24575];integer vec,i,checks=0,failures=0,cycles;reg[1:0]d;string vector_file;
 generate if(OP_SUB) poly_sub_pipe dut(.*); else poly_add_pipe dut(.*); endgenerate
 always #5 clk=~clk;
 task reset;begin rst_n=0;start=0;a_load_we=0;b_load_we=0;result_req=0;repeat(3)@(negedge clk);rst_n=1;repeat(2)@(negedge clk);end endtask
 task begin_operand(input op,input[1:0]dom);begin load_operand=op;load_domain=dom;load_begin=1;@(negedge clk);load_begin=0;end endtask
 task load_vec(input integer v,input[1:0]dom);integer base;begin base=v*768;begin_operand(0,dom);for(i=0;i<256;i=i+1)begin a_load_we=1;a_load_idx=i;a_load_coeff=mem[base+i];@(negedge clk);end a_load_we=0;begin_operand(1,dom);for(i=0;i<256;i=i+1)begin b_load_we=1;b_load_idx=i;b_load_coeff=mem[base+256+i];@(negedge clk);end b_load_we=0;end endtask
 task run_check(input integer v);integer base;begin base=v*768;start=1;@(negedge clk);start=0;cycles=0;while(!done&&cycles<300)begin@(negedge clk);cycles=cycles+1;end if(!done)$fatal(1,"binary watchdog");if(!result_complete||result_domain!=d)failures=failures+1;for(i=0;i<256;i=i+1)begin result_req=1;result_idx=i;@(posedge clk);#1;checks=checks+1;if(!result_valid||result_coeff!==mem[base+512+i])begin failures=failures+1;$display("FIRST_DIFF op=%0d vec=%0d idx=%0d exp=%0d got=%0d",OP_SUB,v,i,mem[base+512+i],result_coeff);$fatal(1,"binary mismatch");end @(negedge clk);end result_req=0;result_release=1;@(negedge clk);result_release=0;end endtask
 initial begin vector_file=VECTOR_FILE;if($value$plusargs("VECTOR_FILE=%s",vector_file))begin end $readmemh(vector_file,mem);reset();
  for(vec=0;vec<32;vec=vec+1)begin d=(vec[0]?2:1);load_vec(vec,d);run_check(vec);end
  begin_operand(0,1);begin_operand(1,2);start=1;@(negedge clk);start=0;checks=checks+1;if(!error||busy)failures=failures+1;
  reset();load_vec(0,1);start=1;@(negedge clk);start=0;repeat(20)@(negedge clk);reset();
  load_vec(0,1);start=1;@(negedge clk);start=0;repeat(130)@(negedge clk);reset();
  d=1;load_vec(1,1);run_check(1);
  $display("POLY_BINARY op_sub=%0d vectors=33 checks=%0d cycles=%0d",OP_SUB,checks,cycles);if(failures)$fatal(1,"binary failures=%0d",failures);$display("PASS tb_poly_binary_pipe");$finish;end
 initial begin repeat(50000)@(posedge clk);$fatal(1,"binary global watchdog");end
endmodule
