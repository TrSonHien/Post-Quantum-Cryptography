`timescale 1ns/1ps
module tb_poly_transform_pipe #(
    parameter IS_INVERSE=0,
    parameter VECTOR_FILE="sim/outputs/poly_ntt.mem"
);
    initial if($test$plusargs("DEBUG_WAVES")) begin
        $dumpfile(IS_INVERSE?"sim/waves/tb_poly_intt_pipe.vcd":"sim/waves/tb_poly_ntt_pipe.vcd");
        $dumpvars(0,tb_poly_transform_pipe);
    end
    reg clk=0, rst_n=0, load_begin=0, load_we=0, start=0;
    reg result_req=0, result_release=0;
    reg [1:0] load_domain=0;
    reg [7:0] load_idx=0, result_idx=0;
    reg [11:0] load_coeff=0;
    wire load_ready, busy, done, error, result_valid, result_complete;
    wire [11:0] result_coeff;
    wire [1:0] result_domain;
    reg [11:0] mem[0:16383];
    integer vec, i, checks=0, failures=0, cycles, measured_cycles=0;
    integer base;
    string vector_file;

    generate
        if(IS_INVERSE) begin : gen_inverse
            poly_intt_pipe dut(.*);
        end else begin : gen_forward
            poly_ntt_pipe dut(.*);
        end
    endgenerate
    always #5 clk=~clk;
    always @(posedge clk) if(rst_n && busy && (result_complete || result_domain!=0))
        $fatal(1,"result metadata published before adapter completion");

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
        begin
            base=vector_number*512;
            load_domain=IS_INVERSE?2:1;
            load_begin=1; @(negedge clk); load_begin=0;
            for(i=0;i<256;i=i+1) begin
                load_we=1; load_idx=i[7:0]; load_coeff=mem[base+i];
                @(negedge clk);
            end
            load_we=0;
        end
    endtask

    task run_and_check;
        input integer vector_number;
        begin
            base=vector_number*512;
            start=1; @(negedge clk); start=0; cycles=0;
            while(!done && cycles<2200) begin @(negedge clk); cycles=cycles+1; end
            if(!done) $fatal(1,"transform watchdog");
            if(measured_cycles==0) measured_cycles=cycles;
            else if(cycles!=measured_cycles) $fatal(1,"nonconstant transform cycles");
            if(!result_complete || result_domain!=(IS_INVERSE?1:2))
                $fatal(1,"bad published metadata");
            for(i=0;i<256;i=i+1) begin
                result_req=1; result_idx=i[7:0]; @(posedge clk); #1;
                checks=checks+1;
                if(!result_valid || result_coeff!==mem[base+256+i]) begin
                    $display("TRANSFORM_DIFF inverse=%0d vec=%0d idx=%0d exp=%0d got=%0d",
                             IS_INVERSE,vector_number,i,mem[base+256+i],result_coeff);
                    $fatal(1,"transform mismatch");
                end
                @(negedge clk);
            end
            result_req=0; result_release=1; @(negedge clk); result_release=0;
        end
    endtask

    initial begin
        vector_file=VECTOR_FILE;
        if($value$plusargs("VECTOR_FILE=%s",vector_file)) begin end
        $readmemh(vector_file,mem);
        apply_reset();
        for(vec=0;vec<32;vec=vec+1) begin load_vector(vec); run_and_check(vec); end

        load_vector(0); start=1; @(negedge clk); start=0; cycles=0;
        while(!done && cycles<2200) begin @(negedge clk); cycles=cycles+1; end
        if(!done) $fatal(1,"overwrite setup watchdog");
        load_vector(1); start=1; @(negedge clk); start=0; checks=checks+1;
        if(!error || busy) failures=failures+1;
        apply_reset();

        load_domain=IS_INVERSE?1:2; load_begin=1; @(negedge clk); load_begin=0;
        for(i=0;i<256;i=i+1) begin load_we=1; load_idx=i[7:0]; load_coeff=0; @(negedge clk); end
        load_we=0; start=1; @(negedge clk); start=0; checks=checks+1;
        if(!error || busy) failures=failures+1;

        apply_reset(); load_domain=IS_INVERSE?2:1; load_begin=1; @(negedge clk); load_begin=0;
        for(i=0;i<16;i=i+1) begin load_we=1; load_idx=i[7:0]; load_coeff=0; @(negedge clk); end
        load_we=0; start=1; @(negedge clk); start=0; checks=checks+1;
        if(!error || busy) failures=failures+1;

        apply_reset(); load_vector(0); start=1; @(negedge clk); start=0;
        repeat(20) @(negedge clk); start=1; load_we=1; result_req=1;
        @(negedge clk); start=0; load_we=0; result_req=0;
        if(!error) failures=failures+1;
        apply_reset(); load_vector(0); start=1; @(negedge clk); start=0;
        repeat(300) @(negedge clk);
        apply_reset(); load_vector(0); start=1; @(negedge clk); start=0;
        if(IS_INVERSE) repeat(1400) @(negedge clk); else repeat(1250) @(negedge clk);
        apply_reset(); load_vector(1); run_and_check(1);
        $display("POLY_TRANSFORM inverse=%0d vectors=32 comparisons=8192 checks=%0d cycles=%0d",
                 IS_INVERSE,checks,measured_cycles);
        if(failures) $fatal(1,"control failures");
        $display("PASS tb_poly_transform_pipe");
        $finish;
    end
    initial begin repeat(200000) @(posedge clk); $fatal(1,"transform global watchdog"); end
endmodule
