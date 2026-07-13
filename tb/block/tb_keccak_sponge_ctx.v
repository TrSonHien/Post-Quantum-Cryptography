`timescale 1ns/1ps
module tb_keccak_sponge_ctx;
reg clk=0,rst_n=0,init_valid=0,finalize_valid=0,absorb_valid=0,squeeze_req_valid=0,out_ready=0;reg[1:0]mode;reg[31:0]absorb_data,squeeze_len_bytes;reg[3:0]absorb_keep;
wire init_ready,finalize_ready,context_valid,absorb_phase,squeeze_phase,busy,done,error,absorb_ready,squeeze_req_ready,out_valid;wire[31:0]out_data;wire[3:0]out_keep;wire out_last;
reg[4095:0]message,expected;integer fd,rc,vmode,mlen,olen,vectors,byte_checks,requests,pos,n,j,watchdog,chunk,roundi;reg[1023:0]path;
always #5 clk=~clk;
keccak_sponge_ctx dut(.clk(clk),.rst_n(rst_n),.init_valid(init_valid),.init_ready(init_ready),.mode(mode),.finalize_valid(finalize_valid),.finalize_ready(finalize_ready),.context_valid(context_valid),.absorb_phase(absorb_phase),.squeeze_phase(squeeze_phase),.busy(busy),.done(done),.error(error),.absorb_valid(absorb_valid),.absorb_ready(absorb_ready),.absorb_data(absorb_data),.absorb_keep(absorb_keep),.squeeze_req_valid(squeeze_req_valid),.squeeze_req_ready(squeeze_req_ready),.squeeze_len_bytes(squeeze_len_bytes),.out_valid(out_valid),.out_ready(out_ready),.out_data(out_data),.out_keep(out_keep),.out_last(out_last));
task reset_dut;begin @(negedge clk);rst_n=0;init_valid=0;finalize_valid=0;absorb_valid=0;squeeze_req_valid=0;out_ready=0;@(posedge clk);#1;@(negedge clk);rst_n=1;end endtask
task init_ctx;input[1:0]m;begin while(!init_ready)@(posedge clk);@(negedge clk);mode=m;init_valid=1;@(posedge clk);#1;@(negedge clk);init_valid=0;if(!context_valid||!absorb_phase)$fatal(1,"init mode=%0d",m);end endtask
task send_absorb;input integer start;input integer count;begin absorb_data=0;for(j=0;j<count;j=j+1)absorb_data[8*j+:8]=message[8*(start+j)+:8];absorb_keep=(count==1)?1:(count==2)?3:(count==3)?7:15;absorb_valid=1;watchdog=0;while(!absorb_ready&&watchdog<20000)begin @(posedge clk);watchdog=watchdog+1;end if(watchdog>=20000)$fatal(1,"absorb watchdog");@(posedge clk);#1;@(negedge clk);absorb_valid=0;end endtask
task finalize_ctx;begin while(!finalize_ready)@(posedge clk);@(negedge clk);finalize_valid=1;@(posedge clk);#1;@(negedge clk);finalize_valid=0;watchdog=0;while(!squeeze_phase&&watchdog<20000)begin @(posedge clk);watchdog=watchdog+1;end if(watchdog>=20000)$fatal(1,"finalize watchdog owner=%0d",dut.perm_owner);end endtask
task squeeze_chunk;input integer count;input integer expected_start;integer got,k;begin
  while(!squeeze_req_ready)@(posedge clk);@(negedge clk);squeeze_len_bytes=count;squeeze_req_valid=1;@(posedge clk);#1;@(negedge clk);squeeze_req_valid=0;got=0;watchdog=0;
  while(got<count&&watchdog<30000)begin @(negedge clk);out_ready=((watchdog+requests)%4)!=0;@(posedge clk);watchdog=watchdog+1;if(out_valid&&out_ready)begin n=(out_keep==1)?1:(out_keep==3)?2:(out_keep==7)?3:(out_keep==15)?4:0;if(n==0)$fatal(1,"keep");for(k=0;k<n;k=k+1)begin byte_checks=byte_checks+1;if(out_data[8*k+:8]!==expected[8*(expected_start+got+k)+:8])$fatal(1,"incremental mode=%0d byte=%0d expected=%02x observed=%02x",vmode,expected_start+got+k,expected[8*(expected_start+got+k)+:8],out_data[8*k+:8]);end got=got+n;if(out_last!==(got==count))$fatal(1,"chunk last got=%0d count=%0d",got,count);end end
  if(watchdog>=30000)$fatal(1,"squeeze watchdog");@(negedge clk);out_ready=0;requests=requests+1;
end endtask
task pulse_illegal_absorb;begin @(negedge clk);absorb_data=0;absorb_keep=1;absorb_valid=1;@(posedge clk);#1;@(negedge clk);absorb_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"illegal absorb no error");end endtask
initial begin vectors=0;byte_checks=0;requests=0;mode=0;absorb_data=0;absorb_keep=0;squeeze_len_bytes=0;reset_dut();
 if(!$value$plusargs("VECTORS=%s",path))$fatal(1,"vectors");fd=$fopen(path,"r");if(fd==0)$fatal(1,"open");
 while(!$feof(fd))begin rc=$fscanf(fd,"%d %d %d %h %h\n",vmode,mlen,olen,message,expected);if(rc==5)begin
   init_ctx(vmode[1:0]);pos=0;while(pos<mlen)begin chunk=((pos+vectors)%4)+1;if(chunk>mlen-pos)chunk=mlen-pos;send_absorb(pos,chunk);pos=pos+chunk;end finalize_ctx();
   pos=0;if(vmode<2)begin squeeze_chunk(olen,0);pos=olen;end else while(pos<olen)begin chunk=((requests%7)+1);if(chunk>olen-pos)chunk=olen-pos;squeeze_chunk(chunk,pos);pos=pos+chunk;end
   vectors=vectors+1;
 end end $fclose(fd);
 if(vectors<64)$fatal(1,"vectors=%0d",vectors);
 // Phase/protocol errors.
 reset_dut();pulse_illegal_absorb();reset_dut();@(negedge clk);finalize_valid=1;@(posedge clk);#1;@(negedge clk);finalize_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"finalize before init");
 reset_dut();@(negedge clk);squeeze_req_valid=1;squeeze_len_bytes=1;@(posedge clk);#1;@(negedge clk);squeeze_req_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"squeeze before finalize");
 reset_dut();init_ctx(2);@(negedge clk);absorb_valid=1;absorb_keep=4'b0101;@(posedge clk);#1;@(negedge clk);absorb_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"invalid keep");
 reset_dut();init_ctx(2);finalize_ctx();pulse_illegal_absorb();
 reset_dut();init_ctx(2);finalize_ctx();@(negedge clk);finalize_valid=1;@(posedge clk);#1;@(negedge clk);finalize_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"double finalize");
 reset_dut();init_ctx(2);finalize_ctx();@(negedge clk);squeeze_req_valid=1;squeeze_len_bytes=0;@(posedge clk);#1;@(negedge clk);squeeze_req_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"zero squeeze");
 // Reset cancellation at every padding-permutation round and clean restart.
 for(roundi=0;roundi<24;roundi=roundi+1)begin reset_dut();init_ctx(2);@(negedge clk);finalize_valid=1;@(posedge clk);#1;@(negedge clk);finalize_valid=0;watchdog=0;while(!(dut.u_perm.busy&&dut.u_perm.round_index==roundi)&&watchdog<100)begin @(posedge clk);watchdog=watchdog+1;end if(watchdog>=100)$fatal(1,"round reset reach=%0d",roundi);reset_dut();repeat(2)begin @(posedge clk);#1;if(done||out_valid||context_valid)$fatal(1,"stale after reset round=%0d",roundi);end end
 // Reset stalled output then restart.
 reset_dut();init_ctx(2);finalize_ctx();while(!squeeze_req_ready)@(posedge clk);@(negedge clk);squeeze_len_bytes=8;squeeze_req_valid=1;@(posedge clk);#1;@(negedge clk);squeeze_req_valid=0;out_ready=0;while(!out_valid)@(posedge clk);reset_dut();if(out_valid||context_valid||done)$fatal(1,"reset stalled output");
 $display("PASS tb_keccak_sponge_ctx vectors=%0d byte_checks=%0d squeeze_requests=%0d reset_rounds=24 error_cases=7",vectors,byte_checks,requests);$finish;
end
endmodule
