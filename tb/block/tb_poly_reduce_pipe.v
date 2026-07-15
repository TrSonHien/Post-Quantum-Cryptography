`timescale 1ns/1ps
module tb_poly_reduce_pipe;
    initial if($test$plusargs("DEBUG_WAVES")) begin $dumpfile("sim/waves/tb_poly_reduce_pipe.vcd"); $dumpvars(0,tb_poly_reduce_pipe); end
    reg clk=0, rst_n=0, load_begin=0, load_we=0, start=0;
    reg result_req=0, result_release=0, zeroize_req=0;
    reg [1:0] load_domain=0;
    reg [7:0] load_idx=0, result_idx=0;
    reg [31:0] load_coeff=0;
    wire load_ready, busy, done, error, result_valid, result_complete;
    wire zeroize_busy,zeroize_done;
    wire [11:0] result_coeff;
    wire [1:0] result_domain;
    reg [31:0] inputs[0:8191];
    reg [11:0] expected[0:8191];
    integer v, i, checks=0, failures=0, cycles;
    string input_file, expected_file;

    poly_reduce_pipe dut(.*);
    always #5 clk=~clk;

    task apply_reset;
        begin
            rst_n=0; start=0; load_we=0; result_req=0;
            repeat(3) @(negedge clk);
            rst_n=1;
            repeat(2) @(negedge clk);
        end
    endtask

    task load_vector;
        input integer vector_number;
        input [1:0] vector_domain;
        begin
            load_domain=vector_domain; load_begin=1; @(negedge clk); load_begin=0;
            for(i=0;i<256;i=i+1) begin
                load_we=1; load_idx=i[7:0]; load_coeff=inputs[vector_number*256+i];
                @(negedge clk);
            end
            load_we=0;
        end
    endtask

    initial begin
        input_file="sim/outputs/poly_reduce_input.mem";
        expected_file="sim/outputs/poly_reduce_expected.mem";
        if ($value$plusargs("INPUT_FILE=%s",input_file)) begin end
        if ($value$plusargs("EXPECTED_FILE=%s",expected_file)) begin end
        $readmemh(input_file,inputs);
        $readmemh(expected_file,expected);
        apply_reset();
        for(v=0;v<32;v=v+1) begin
            load_vector(v,v[0]?2:1);
            start=1; @(negedge clk); start=0; cycles=0;
            while(!done && cycles<300) begin @(negedge clk); cycles=cycles+1; end
            if(!done) $fatal(1,"reduce watchdog");
            for(i=0;i<256;i=i+1) begin
                result_req=1; result_idx=i[7:0]; @(posedge clk); #1;
                checks=checks+1;
                if(!result_valid || result_coeff !== expected[v*256+i]) begin
                    $display("REDUCE_DIFF v=%0d i=%0d exp=%0d got=%0d",v,i,expected[v*256+i],result_coeff);
                    $fatal(1,"reduce mismatch");
                end
                @(negedge clk);
            end
            result_req=0; result_release=1; @(negedge clk); result_release=0;
        end
        apply_reset();
        load_domain=1; load_begin=1; @(negedge clk); load_begin=0;
        load_we=1; load_idx=0; load_coeff=32'hffff_ffff; @(negedge clk); load_we=0;
        start=1; @(negedge clk); start=0; checks=checks+1;
        if(!error || busy) failures=failures+1;
        apply_reset(); load_vector(0,1); start=1; @(negedge clk); start=0;
        repeat(20) @(negedge clk); apply_reset();
        load_vector(0,1); start=1; @(negedge clk); start=0;
        repeat(132) @(negedge clk); apply_reset();
        load_vector(1,1); start=1; @(negedge clk); start=0; cycles=0;
        while(!done && cycles<300) begin @(negedge clk); cycles=cycles+1; end
        if(!done) $fatal(1,"reduce restart watchdog");
        result_release=1;@(negedge clk);result_release=0;
        for(i=0;i<128;i=i+1)begin dut.even_mem[i]=32'h1000+i;dut.odd_mem[i]=32'h2000+i;dut.ws_r.bank_even[i]=12'h321;dut.ws_r.bank_odd[i]=12'h322;end
        dut.lane0.prod1=69'h12345;dut.lane0.a_d1=32'h23456;dut.lane1.prod2=33'h34567;dut.lane1.a_d2=32'h45678;
        zeroize_req=1;@(negedge clk);zeroize_req=0;cycles=0;
        while(!zeroize_done&&cycles<300)begin @(negedge clk);cycles=cycles+1;end
        if(!zeroize_done||zeroize_busy||cycles<129)$fatal(1,"reduce zeroize watchdog/premature done cycles=%0d",cycles);
        for(i=0;i<128;i=i+1)begin checks=checks+4;if(dut.even_mem[i]!==0||dut.odd_mem[i]!==0||dut.ws_r.bank_even[i]!==0||dut.ws_r.bank_odd[i]!==0)$fatal(1,"reduce scrub location i=%0d",i);end
        checks=checks+4;if(dut.lane0.prod1!==0||dut.lane0.a_d1!==0||dut.lane1.prod2!==0||dut.lane1.a_d2!==0)$fatal(1,"reduce lane scrub");
        load_vector(2,1);start=1;@(negedge clk);start=0;cycles=0;while(!done&&cycles<300)begin@(negedge clk);cycles=cycles+1;end
        if(!done||error)$fatal(1,"reduce clean restart after zeroize");
        $display("POLY_REDUCE vectors=32 checks=%0d cycles=%0d",checks,cycles);
        if(failures) $fatal(1,"reduce control failure");
        $display("PASS tb_poly_reduce_pipe");
        $finish;
    end
    initial begin repeat(50000) @(posedge clk); $fatal(1,"reduce global watchdog"); end
endmodule
