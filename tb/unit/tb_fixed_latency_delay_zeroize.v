`timescale 1ns/1ps
module tb_fixed_latency_delay_zeroize;
 reg clk=0,rst_n=0,in_valid=0,zeroize_req=0;reg[11:0]in_payload=0;reg[7:0]in_metadata=0;
 wire out_valid,zeroize_busy,zeroize_done;wire[11:0]out_payload;wire[7:0]out_metadata;
 integer i,checks=0,cycles=0,start_cycle,latency;
 always#5 clk=~clk;
 fixed_latency_delay #(.PAYLOAD_WIDTH(12),.METADATA_WIDTH(8),.LATENCY(4)) dut(
  .clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_payload(in_payload),
  .in_metadata(in_metadata),.out_valid(out_valid),.out_payload(out_payload),
  .out_metadata(out_metadata),.zeroize_req(zeroize_req),.zeroize_busy(zeroize_busy),
  .zeroize_done(zeroize_done));
 task tick;begin @(posedge clk);#1;cycles=cycles+1;end endtask
 task fill_nonzero;begin for(i=0;i<4;i=i+1)begin dut.payload_pipe[i]=12'(i+1);dut.metadata_pipe[i]=8'(i+9);end dut.valid_pipe=4'hf;end endtask
 initial begin
  tick;fill_nonzero;rst_n=1;tick;rst_n=0;tick;rst_n=1;tick;
  for(i=0;i<4;i=i+1)if(dut.payload_pipe[i]===0||dut.metadata_pipe[i]===0)$fatal(1,"reset erased delay stage %0d",i);checks=checks+8;
  fill_nonzero;start_cycle=cycles;zeroize_req=1;tick;zeroize_req=0;
  if(!zeroize_busy||out_valid)$fatal(1,"delay zeroize protocol failed");checks=checks+2;
  while(!zeroize_done)begin tick;if(cycles-start_cycle>10)$fatal(1,"delay scrub timeout");end
  latency=cycles-start_cycle;if(latency!=6)$fatal(1,"delay latency exp=6 got=%0d",latency);checks=checks+1;
  for(i=0;i<4;i=i+1)begin if(dut.payload_pipe[i]!==0||dut.metadata_pipe[i]!==0)$fatal(1,"delay stage %0d not zero",i);checks=checks+2;end
  if(dut.valid_pipe!==0||out_valid)$fatal(1,"delay valid metadata not invalid");checks=checks+2;
  tick;if(zeroize_done)$fatal(1,"delay done wider than one cycle");checks=checks+1;
  in_valid=1;in_payload=12'd1234;in_metadata=8'h5a;tick;in_valid=0;
  repeat(3)tick;
  if(!out_valid||out_payload!=12'd1234||out_metadata!=8'h5a)$fatal(1,"delay normal transaction after scrub failed");checks=checks+3;
  $display("PASS fixed_latency_delay_zeroize checks=%0d stages=4 latency=%0d",checks,latency);$finish;
 end
 initial begin #10000;$fatal(1,"watchdog");end
endmodule
