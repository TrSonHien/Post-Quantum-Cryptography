`timescale 1ns/1ps

module tb_ntt_pingpong_banks;
    reg clk=0, rst_n=0, swap_roles=0;
    wire role_select;
    reg src_rd_en=0;
    reg [7:0] src_index0=0, src_index1=0;
    reg [2:0] src_pair_bit=0, src_addr_bit=0;
    reg src_xor_layout=0;
    wire src_rd_valid;
    wire [11:0] src_data0, src_data1;
    reg dst_wr_en=0;
    reg [7:0] dst_index0=0, dst_index1=0;
    reg [2:0] dst_pair_bit=0, dst_addr_bit=0;
    reg dst_xor_layout=0;
    reg [11:0] dst_data0=0, dst_data1=0;
    reg [7:0] map_index=0;
    reg [2:0] map_pair_bit=0, map_addr_bit=0;
    reg map_xor=0;
    wire map_bank;
    wire [6:0] map_addr;
    integer pass_count=0, fail_count=0;
    integer i, s, p, r;
    integer fwd [0:6];
    integer inv [0:6];

    always #5 clk=~clk;
    ntt_bank_map map_dut(map_index,map_pair_bit,map_addr_bit,map_xor,map_bank,map_addr);
    ntt_pingpong_banks dut(
        clk,rst_n,swap_roles,role_select,
        src_rd_en,src_index0,src_index1,src_pair_bit,src_addr_bit,src_xor_layout,
        src_rd_valid,src_data0,src_data1,
        dst_wr_en,dst_index0,dst_index1,dst_pair_bit,dst_addr_bit,dst_xor_layout,
        dst_data0,dst_data1
    );

    function [6:0] remove_bit(input [7:0] value, input integer bit_index);
        integer a,b;
        begin
            remove_bit=0; b=0;
            for(a=0;a<8;a=a+1) if(a!=bit_index) begin
                remove_bit[b]=value[a]; b=b+1;
            end
        end
    endfunction

    task check_map(input integer current_bit, input integer next_bit);
        reg expected_bank;
        begin
            for(i=0;i<256;i=i+1) begin
                map_index=i; map_pair_bit=current_bit; map_addr_bit=next_bit; map_xor=1; #1;
                expected_bank=((i>>current_bit)&1)^((i>>next_bit)&1);
                if(map_bank!==expected_bank || map_addr!==remove_bit(i,next_bit)) begin
                    $display("FAIL map p=%0d r=%0d i=%0d",current_bit,next_bit,i); fail_count=fail_count+1;
                end else pass_count=pass_count+1;
            end
            for(i=0;i<256;i=i+1) if(((i>>current_bit)&1)==0) begin
                map_index=i; #1; p=map_bank;
                map_index=i^(1<<current_bit); #1;
                if(p==map_bank) begin $display("FAIL map collision stage p=%0d r=%0d i=%0d",current_bit,next_bit,i); fail_count=fail_count+1; end
                else pass_count=pass_count+1;
            end
        end
    endtask

    task write_pair(input [7:0] idx0,input [7:0] idx1,input [2:0] pb,input [2:0] ab,input xl,input integer addend);
        begin
            @(negedge clk); dst_wr_en=1; dst_index0=idx0; dst_index1=idx1;
            dst_pair_bit=pb; dst_addr_bit=ab; dst_xor_layout=xl;
            dst_data0=(idx0+addend)%3329; dst_data1=(idx1+addend)%3329;
            @(posedge clk); #1; @(negedge clk); dst_wr_en=0;
        end
    endtask

    task read_pair(input [7:0] idx0,input [7:0] idx1,input [2:0] pb,input [2:0] ab,input xl,input integer addend);
        begin
            @(negedge clk); src_rd_en=1; src_index0=idx0; src_index1=idx1;
            src_pair_bit=pb; src_addr_bit=ab; src_xor_layout=xl;
            @(posedge clk); #1;
            if(!src_rd_valid || src_data0!==(idx0+addend)%3329 || src_data1!==(idx1+addend)%3329) begin
                $display("FAIL pingpong idx=%0d/%0d valid=%b data=%0d/%0d",idx0,idx1,src_rd_valid,src_data0,src_data1); fail_count=fail_count+1;
            end else pass_count=pass_count+1;
            @(negedge clk); src_rd_en=0;
        end
    endtask

    task swap_once;
        begin
            @(negedge clk); swap_roles=1;
            @(posedge clk); #1;
            @(negedge clk); swap_roles=0;
        end
    endtask

    initial begin
        fwd[0]=7;fwd[1]=6;fwd[2]=5;fwd[3]=4;fwd[4]=3;fwd[5]=2;fwd[6]=1;
        inv[0]=1;inv[1]=2;inv[2]=3;inv[3]=4;inv[4]=5;inv[5]=6;inv[6]=7;
        repeat(2) @(posedge clk); @(negedge clk); rst_n=1;
        for(s=0;s<6;s=s+1) check_map(fwd[s],fwd[s+1]);
        for(s=0;s<6;s=s+1) check_map(inv[s],inv[s+1]);

        // Load destination set B in first-stage layout, swap, then read source B.
        for(i=0;i<128;i=i+1) write_pair(i,i+128,7,7,0,100);
        swap_once;
        if(role_select!==1) begin $display("FAIL first role swap"); fail_count=fail_count+1; end else pass_count=pass_count+1;
        for(i=0;i<128;i=i+1) read_pair(i,i+128,7,7,0,100);
        @(posedge clk); #1;

        // Write next-stage layout into A, swap, and read distance-64 pairs.
        for(i=0;i<128;i=i+1) write_pair(i,i+128,7,6,1,200);
        swap_once;
        if(role_select!==0) begin $display("FAIL second role swap"); fail_count=fail_count+1; end else pass_count=pass_count+1;
        for(i=0;i<64;i=i+1) begin
            read_pair(i,i+64,7,6,1,200);
            read_pair(i+128,i+192,7,6,1,200);
        end

        $display("INFO tb_ntt_pingpong_banks: pass_count=%0d fail_count=%0d",pass_count,fail_count);
        if(fail_count==0) $display("PASS tb_ntt_pingpong_banks"); else $fatal(1,"FAIL tb_ntt_pingpong_banks");
        $finish;
    end
endmodule
