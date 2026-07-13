`timescale 1ns/1ps
module tb_kpke_matrix_row_sampler;
 reg clk=0,rst_n=0,start=0,out_ready=1;
 reg[255:0]rho;reg[1:0]row;reg transpose;
 wire busy,done,error,out_valid;wire[11:0]out_coeff;wire[7:0]out_index;
 wire[1:0]out_poly_index,out_domain;wire[7:0]sample_index0,sample_index1;wire[2:0]samples_started;
 integer fd,rc,v,e,i,got,checks=0,byte_checks=0,cycles,child_starts,stall_cycle=0,reset_elem;
 reg[11:0]exp[0:767];reg held_valid;reg[11:0]held_coeff;reg[7:0]held_index;reg[1:0]held_poly;
 string file;
 always#5 clk=~clk;
 kpke_matrix_row_sampler dut(clk,rst_n,start,rho,row,transpose,busy,done,error,
  out_valid,out_ready,out_coeff,out_index,out_poly_index,out_domain,
  sample_index0,sample_index1,samples_started);

 task launch_and_check;
  begin
   @(negedge clk);start=1;@(negedge clk);start=0;got=0;cycles=0;child_starts=0;
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>15000)$fatal(1,"watchdog v=%0d row=%0d tr=%0d state=%0d elem=%0d",v,row,transpose,dut.state,dut.element);end
   if(error||got!=768||samples_started!=3||child_starts!=3)$fatal(1,"status v=%0d row=%0d tr=%0d got=%0d samples=%0d starts=%0d error=%b",v,row,transpose,got,samples_started,child_starts,error);
  end
 endtask

 initial begin
  if(!$value$plusargs("VECTOR_FILE=%s",file))$fatal(1,"VECTOR_FILE");
  fd=$fopen(file,"r");repeat(3)@(negedge clk);rst_n=1;
  for(v=0;v<96;v=v+1)begin
   rc=$fscanf(fd,"%h %d %d\n",rho,row,transpose);
   for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp[i]);
   launch_and_check();
  end
  // Illegal start while busy is reported without corrupting the active row.
  rc=$fseek(fd,0,0);rc=$fscanf(fd,"%h %d %d\n",rho,row,transpose);
  for(i=0;i<768;i=i+1)rc=$fscanf(fd,"%h",exp[i]);
  @(negedge clk);start=1;@(negedge clk);start=0;got=0;repeat(20)@(negedge clk);start=1;@(negedge clk);start=0;
  while(!done)@(negedge clk);if(!error||got!=768)$fatal(1,"start-while-busy");
  // Reset once during each of the three child samples, then cleanly restart.
  for(reset_elem=0;reset_elem<3;reset_elem=reset_elem+1)begin
   rst_n=0;@(negedge clk);rst_n=1;@(negedge clk);start=1;@(negedge clk);start=0;got=0;
   wait(dut.element==reset_elem && dut.state==2);repeat(30)@(negedge clk);rst_n=0;@(negedge clk);
   if(busy||done||out_valid)$fatal(1,"reset cancel elem=%0d",reset_elem);
   rst_n=1;launch_and_check();
  end
  $display("PASS tb_kpke_matrix_row_sampler vectors=96 coeff_checks=%0d sample_input_byte_checks=%0d reset_elements=3 start_busy=PASS backpressure=PASS",checks,byte_checks);$finish;
 end

 always@(negedge clk)if(rst_n)begin stall_cycle=stall_cycle+1;out_ready=(stall_cycle%11)!=5;end
 always@(posedge clk)begin
  if(!rst_n)held_valid<=0;else begin
   if(dut.child_start)begin
    child_starts=child_starts+1;
    if(sample_index0!==(transpose?{6'd0,row}:{6'd0,dut.element})||sample_index1!==(transpose?{6'd0,dut.element}:{6'd0,row}))
      $fatal(1,"matrix index row=%0d elem=%0d tr=%0d i0=%0d i1=%0d",row,dut.element,transpose,sample_index0,sample_index1);
    byte_checks=byte_checks+34;
   end
   if(held_valid&&(!out_valid||out_coeff!==held_coeff||out_index!==held_index||out_poly_index!==held_poly))$fatal(1,"stalled output changed");
   held_valid=out_valid&&!out_ready;if(out_valid&&!out_ready)begin held_coeff=out_coeff;held_index=out_index;held_poly=out_poly_index;end
   if(out_valid&&out_ready)begin
    if(got>=768||out_poly_index!==got/256||out_index!==got%256||out_coeff!==exp[got]||out_domain!=2'b10)
      $fatal(1,"coeff v=%0d row=%0d tr=%0d elem=%0d idx=%0d exp=%0d got=%0d i0=%0d i1=%0d",v,row,transpose,out_poly_index,out_index,exp[got],out_coeff,sample_index0,sample_index1);
    got=got+1;checks=checks+1;
   end
  end
 end
endmodule
