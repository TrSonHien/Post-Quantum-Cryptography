`timescale 1ns/1ps
module tb_poly_workspace;
  initial if($test$plusargs("DEBUG_WAVES"))begin $dumpfile("sim/waves/tb_poly_workspace.vcd");$dumpvars(0,tb_poly_workspace);end
  reg clk=0,rst_n=0,load_begin=0,load_we=0,acquire_internal=0,init_internal=0;
  reg publish_result=0,release_internal=0,result_req=0,int_rd_req=0,int_pair_rd_req=0;
  reg int_wr_en=0,int_pair_wr_en=0; reg[1:0]load_domain=0,init_domain=0;
  reg zeroize_req=0;
  reg[7:0]load_idx=0,result_idx=0,int_rd_idx=0,int_wr_idx=0;
  reg[6:0]int_pair_rd_idx=0,int_pair_wr_idx=0; reg[11:0]load_coeff=0,int_wr_coeff=0,int_pair_wr0=0,int_pair_wr1=0;
  wire load_ready,complete,error,result_valid,int_rd_valid,int_pair_rd_valid; wire[1:0]owner,domain;
  wire zeroize_busy,zeroize_done;
  wire[11:0]result_coeff,int_rd_coeff,int_pair_rd0,int_pair_rd1;
  integer checks=0,failures=0,i;
  poly_workspace dut(.*); always #5 clk=~clk;
  task reset; begin rst_n=0;repeat(3)@(negedge clk);rst_n=1;repeat(2)@(negedge clk);end endtask
  task begin_load(input[1:0]d);begin load_domain=d;load_begin=1;@(negedge clk);load_begin=0;end endtask
  task put(input[7:0]idx,input[11:0]v);begin load_we=1;load_idx=idx;load_coeff=v;@(negedge clk);load_we=0;end endtask
  task check(input cond,input[255:0]msg);begin checks=checks+1;if(!cond)begin failures=failures+1;$display("FAIL %0s",msg);end end endtask
  initial begin
    reset(); check(owner==0&&!complete&&domain==0&&!error,"reset metadata");
    begin_load(1); for(i=0;i<256;i=i+1)put(i[7:0],i%3329); check(complete&&domain==1,"sequential complete");
    put(8'd7,12'd1234); check(complete,"duplicate overwrite stays complete");
    acquire_internal=1;@(negedge clk);acquire_internal=0;check(owner==1,"acquire");
    int_pair_rd_req=1;int_pair_rd_idx=3;@(posedge clk);#1;check(int_pair_rd_valid&&int_pair_rd0==6&&int_pair_rd1==1234,"pair synchronous read");@(negedge clk);int_pair_rd_req=0;
    release_internal=1;@(negedge clk);release_internal=0;check(owner==2,"release");
    result_req=1;result_idx=7;@(posedge clk);#1;check(result_valid&&result_coeff==1234,"result synchronous read");@(negedge clk);result_req=0;
    for(i=0;i<256;i=i+1)begin result_req=1;result_idx=i;@(posedge clk);#1;check(result_valid&&result_coeff==(i==7?1234:i%3329),"sequential logical mapping");@(negedge clk);end result_req=0;
    begin_load(2);for(i=255;i>=0;i=i-1)put(i[7:0],(3328-i)%3329);check(complete&&domain==2,"arbitrary load");
    acquire_internal=1;@(negedge clk);acquire_internal=0;release_internal=1;@(negedge clk);release_internal=0;
    for(i=0;i<256;i=i+1)begin result_req=1;result_idx=i;@(posedge clk);#1;check(result_valid&&result_coeff==(3328-i)%3329,"arbitrary logical mapping");@(negedge clk);end result_req=0;
    begin_load(1);for(i=0;i<256;i=i+1)put(i[7:0],(i*7)%3329);acquire_internal=1;@(negedge clk);acquire_internal=0;
    result_req=1;@(negedge clk);result_req=0;check(error,"external access while internal");
    reset();check(!complete&&domain==0&&!result_valid,"reset clears metadata valid");
    check(dut.bank_odd[3]==12'd49,"reset preserves payload");
    begin_load(1);for(i=0;i<256;i=i+1)put(i[7:0],(i*7)%3329);check(complete,"reuse after reset");
    $display("WORKSPACE_CHECKS=%0d FAILURES=%0d",checks,failures);if(failures)$fatal(1,"workspace failed");$display("PASS tb_poly_workspace");$finish;
  end
  initial begin repeat(5000)@(posedge clk);$fatal(1,"workspace watchdog");end
endmodule
