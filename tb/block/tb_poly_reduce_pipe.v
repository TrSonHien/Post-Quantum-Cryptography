`timescale 1ns/1ps
module tb_poly_reduce_pipe;
    initial if($test$plusargs("DEBUG_WAVES")) begin $dumpfile("sim/waves/tb_poly_reduce_pipe.vcd"); $dumpvars(0,tb_poly_reduce_pipe); end
    reg clk=0, rst_n=0, load_begin=0, load_we=0, start=0;
    reg result_req=0, result_release=0;
    reg [1:0] load_domain=0;
    reg [7:0] load_idx=0, result_idx=0;
    reg [31:0] load_coeff=0;
    wire load_ready, busy, done, error, result_valid, result_complete;
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
        $display("POLY_REDUCE vectors=32 checks=%0d cycles=%0d",checks,cycles);
        if(failures) $fatal(1,"reduce control failure");
        $display("PASS tb_poly_reduce_pipe");
        $finish;
    end
    initial begin repeat(50000) @(posedge clk); $fatal(1,"reduce global watchdog"); end
endmodule
