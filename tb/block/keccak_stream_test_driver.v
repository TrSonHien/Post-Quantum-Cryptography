`timescale 1ns/1ps
module keccak_stream_test_driver #(
    parameter integer FILTER_MODE=-1,
    parameter integer RUN_ERROR_TESTS=1
)(
    output reg clk,output reg rst_n,output reg cmd_valid,input wire cmd_ready,
    output reg [1:0] mode,output reg [31:0] msg_len_bytes,output reg [31:0] out_len_bytes,
    output reg in_valid,input wire in_ready,output reg [31:0] in_data,
    output reg [3:0] in_keep,output reg in_last,input wire out_valid,
    output reg out_ready,input wire [31:0] out_data,input wire [3:0] out_keep,
    input wire out_last,input wire busy,input wire done,input wire error
);
    reg [4095:0] message;reg [4095:0] expected;
    reg [31:0] held_data;reg [3:0] held_keep;reg held_last;
    reg stalled;integer fd,rc,vmode,mlen,olen,vectors,byte_checks,pos,n,j,cycles,watchdog,total_cycles;
    reg [1023:0] path;
    always #5 clk=~clk;
    always @(posedge clk)cycles<=cycles+1;
    task reset_dut;begin rst_n=0;cmd_valid=0;in_valid=0;out_ready=0;repeat(2)@(posedge clk);@(negedge clk);rst_n=1;end endtask
    task run_vector;begin
        while(!cmd_ready)@(posedge clk);@(negedge clk);mode=vmode[1:0];msg_len_bytes=mlen;out_len_bytes=olen;cmd_valid=1;
        @(posedge clk);#1;@(negedge clk);cmd_valid=0;
        pos=0;
        while(pos<mlen)begin
            if(((pos/4)+vectors)%4==0)@(posedge clk);
            n=((mlen-pos)>=4)?4:(mlen-pos);in_data=0;
            for(j=0;j<n;j=j+1)in_data[8*j +:8]=message[8*(pos+j) +:8];
            in_keep=(n==1)?4'b0001:(n==2)?4'b0011:(n==3)?4'b0111:4'b1111;in_last=(pos+n==mlen);in_valid=1;watchdog=0;
            while(!in_ready&&watchdog<20000)begin @(posedge clk);watchdog=watchdog+1;end
            if(watchdog>=20000)$fatal(1,"input watchdog mode=%0d pos=%0d",vmode,pos);
            @(posedge clk);#1;pos=pos+n;@(negedge clk);in_valid=0;
        end
        pos=0;watchdog=0;stalled=0;
        while(pos<olen&&watchdog<40000)begin
            @(negedge clk);out_ready=((watchdog+vectors)%5)!=0;
            @(posedge clk);watchdog=watchdog+1;
            if(out_valid&&!out_ready)begin
                if(stalled&&(out_data!==held_data||out_keep!==held_keep||out_last!==held_last))$fatal(1,"backpressure stability mode=%0d pos=%0d",vmode,pos);
                held_data=out_data;held_keep=out_keep;held_last=out_last;stalled=1;
            end else stalled=0;
            if(out_valid&&out_ready)begin
                n=(out_keep==1)?1:(out_keep==3)?2:(out_keep==7)?3:(out_keep==15)?4:0;
                if(n==0)$fatal(1,"invalid out_keep %b",out_keep);
                for(j=0;j<n;j=j+1)begin
                    byte_checks=byte_checks+1;if(out_data[8*j +:8]!==expected[8*(pos+j) +:8])$fatal(1,"digest mode=%0d vector=%0d byte=%0d expected=%02x observed=%02x",vmode,vectors,pos+j,expected[8*(pos+j)+:8],out_data[8*j+:8]);
                end
                pos=pos+n;if(out_last!==(pos==olen))$fatal(1,"out_last mode=%0d pos=%0d len=%0d",vmode,pos,olen);
                #1;if(out_last&&!done)$fatal(1,"done missing on final handshake mode=%0d",vmode);
            end
        end
        if(watchdog>=40000)$fatal(1,"output watchdog mode=%0d pos=%0d/%0d",vmode,pos,olen);
        @(negedge clk);out_ready=0;@(posedge clk);#1;if(done)$fatal(1,"done width mode=%0d",vmode);if(error)$fatal(1,"unexpected error mode=%0d vector=%0d mlen=%0d olen=%0d",vmode,vectors,mlen,olen);
        vectors=vectors+1;
    end endtask
    task pulse_cmd;input integer md;input integer lm;input integer lo;begin
        while(!cmd_ready)@(posedge clk);@(negedge clk);mode=md[1:0];msg_len_bytes=lm;out_len_bytes=lo;cmd_valid=1;@(posedge clk);#1;@(negedge clk);cmd_valid=0;
    end endtask
    task invalid_beat;input[3:0]k;input l;begin
        while(!in_ready)@(posedge clk);@(negedge clk);in_data=32'h03020100;in_keep=k;in_last=l;in_valid=1;@(posedge clk);#1;@(negedge clk);in_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"malformed stream k=%b last=%b",k,l);
    end endtask
    task error_tests;begin
        reset_dut();pulse_cmd(0,0,31);@(posedge clk);#1;if(!error)$fatal(1,"fixed output length");
        reset_dut();pulse_cmd(2,0,0);@(posedge clk);#1;if(!error)$fatal(1,"zero shake output");
        reset_dut();pulse_cmd(0,8,32);invalid_beat(4'b1111,1'b1);
        reset_dut();pulse_cmd(0,4,32);invalid_beat(4'b1111,1'b0);
        reset_dut();pulse_cmd(0,4,32);invalid_beat(4'b0111,1'b1);
        reset_dut();pulse_cmd(2,0,8);@(negedge clk);cmd_valid=1;@(posedge clk);#1;@(negedge clk);cmd_valid=0;@(posedge clk);#1;if(!error)$fatal(1,"command while busy");
        reset_dut();pulse_cmd(0,4,32);while(!in_ready)@(posedge clk);@(negedge clk);in_data=0;in_keep=15;in_last=1;in_valid=1;@(posedge clk);#1;@(negedge clk);in_valid=0;repeat(2)@(posedge clk);@(negedge clk);in_valid=1;@(posedge clk);#1;@(negedge clk);in_valid=0;if(!error)$fatal(1,"extra input");
        reset_dut();pulse_cmd(2,200,16);repeat(5)@(posedge clk);reset_dut();repeat(2)begin @(posedge clk);#1;if(out_valid||done||busy)$fatal(1,"stale after stream reset");end
    end endtask
    initial begin
        clk=0;cycles=0;vectors=0;byte_checks=0;cmd_valid=0;in_valid=0;out_ready=0;mode=0;msg_len_bytes=0;out_len_bytes=0;in_data=0;in_keep=0;in_last=0;reset_dut();
        if(!$value$plusargs("VECTORS=%s",path))$fatal(1,"missing vectors");fd=$fopen(path,"r");if(fd==0)$fatal(1,"open vectors");
        while(!$feof(fd))begin rc=$fscanf(fd,"%d %d %d %h %h\n",vmode,mlen,olen,message,expected);if(rc==5&&(FILTER_MODE<0||vmode==FILTER_MODE))run_vector();end
        $fclose(fd);if(vectors<64)$fatal(1,"vector minimum got=%0d",vectors);if(RUN_ERROR_TESTS)error_tests();
        $display("PASS keccak_stream mode_filter=%0d vectors=%0d byte_checks=%0d cycles=%0d",FILTER_MODE,vectors,byte_checks,cycles);$finish;
    end
endmodule
