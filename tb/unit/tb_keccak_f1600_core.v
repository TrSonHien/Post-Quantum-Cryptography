`timescale 1ns/1ps
module tb_keccak_f1600_core;
    reg clk=0,rst_n=0,start=0;reg [1599:0] state_in;
    wire busy,done,error;wire [1599:0] state_out;
    reg [1599:0] expected;reg [1599:0] zero_expected;integer fd,rc,checks,failures,cycles,done_width,r;
    reg [1023:0] vector_path;
    always #5 clk=~clk;
    keccak_f1600_core dut(.clk(clk),.rst_n(rst_n),.start(start),.state_in(state_in),.busy(busy),.done(done),.error(error),.state_out(state_out));
    task reset_dut;begin @(negedge clk);rst_n=0;start=0;@(posedge clk);#1;@(negedge clk);rst_n=1;end endtask
    task run_one;begin
        @(negedge clk);start=1;@(posedge clk);#1;start=0;cycles=0;
        while(!done && cycles<30)begin @(posedge clk);#1;cycles=cycles+1;end
        if(!done)$fatal(1,"watchdog state=%0400h",state_in);
        if(cycles!=24)$fatal(1,"latency got=%0d expected=24",cycles);
        if(state_out!==expected)$fatal(1,"perm mismatch check=%0d expected=%0400h observed=%0400h",checks,expected,state_out);
        @(posedge clk);#1;if(done)$fatal(1,"done wider than one cycle");
    end endtask
    initial begin
        if($test$plusargs("DEBUG_WAVES"))begin $dumpfile("tb_keccak_f1600_core.vcd");$dumpvars(0,tb_keccak_f1600_core);end
        checks=0;failures=0;reset_dut();
        if(!$value$plusargs("VECTORS=%s",vector_path))$fatal(1,"missing +VECTORS");
        fd=$fopen(vector_path,"r");if(fd==0)$fatal(1,"cannot open vectors");
        while(!$feof(fd))begin rc=$fscanf(fd,"%h %h\n",state_in,expected);if(rc==2)begin checks=checks+1;if(checks==1)zero_expected=expected;run_one();end end
        $fclose(fd);if(checks<128)$fatal(1,"insufficient vectors");
        // Busy-start error and reset clearing.
        state_in=0;expected='hx;@(negedge clk);start=1;@(posedge clk);#1;start=0;
        repeat(3)@(posedge clk);@(negedge clk);start=1;@(posedge clk);#1;start=0;
        if(!error)$fatal(1,"start while busy did not error");reset_dut();if(error||busy||done)$fatal(1,"reset did not clear control");
        // Cancellation at every round position, followed by a clean restart.
        for(r=0;r<24;r=r+1)begin
            state_in=1600'h0123456789abcdef;@(negedge clk);start=1;@(posedge clk);#1;start=0;
            repeat(r+1)@(posedge clk);@(negedge clk);rst_n=0;@(posedge clk);#1;
            if(done||busy)$fatal(1,"reset cancellation failed round=%0d",r);
            @(negedge clk);rst_n=1;repeat(2)begin @(posedge clk);#1;if(done)$fatal(1,"stale done round=%0d",r);end
        end
        // Known zero-state result is part of vector 1; repeat restart explicitly.
        state_in=0;expected=zero_expected;run_one();
        $display("PASS tb_keccak_f1600_core vectors=%0d latency_cycles=24 reset_points=24",checks);$finish;
    end
endmodule
