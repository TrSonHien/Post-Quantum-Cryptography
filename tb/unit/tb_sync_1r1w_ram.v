`timescale 1ns/1ps

module tb_sync_1r1w_ram;
    reg clk = 0;
    reg rst_n = 0;
    reg rd_en = 0;
    reg [6:0] rd_addr = 0;
    wire rd_valid;
    wire [11:0] rd_data;
    reg wr_en = 0;
    reg [6:0] wr_addr = 0;
    reg [11:0] wr_data = 0;
    reg [11:0] expected [0:127];
    integer i;
    integer seed = 32'h4d325241;
    integer pass_count = 0;
    integer fail_count = 0;

    always #5 clk = ~clk;

    sync_1r1w_ram dut (clk, rst_n, rd_en, rd_addr, rd_valid, rd_data,
                       wr_en, wr_addr, wr_data);

    task write_one(input [6:0] addr, input [11:0] data);
        begin
            @(negedge clk); wr_en = 1; wr_addr = addr; wr_data = data;
            @(posedge clk); #1;
            @(negedge clk); wr_en = 0;
            expected[addr] = data;
        end
    endtask

    task read_one(input [6:0] addr);
        begin
            @(negedge clk); rd_en = 1; rd_addr = addr;
            @(posedge clk); #1;
            if (!rd_valid || rd_data !== expected[addr]) begin
                $display("FAIL RAM addr=%0d valid=%b expected=%0d actual=%0d", addr, rd_valid, expected[addr], rd_data);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
            @(negedge clk); rd_en = 0;
            @(posedge clk); #1;
            if (rd_valid) begin
                $display("FAIL RAM rd_valid exceeded exact one-cycle response");
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1;

        for (i = 0; i < 128; i = i + 1)
            write_one(i[6:0], (i * 29 + 7) % 3329);
        for (i = 0; i < 128; i = i + 1)
            read_one(i[6:0]);

        for (i = 0; i < 96; i = i + 1) begin
            write_one($random(seed) & 7'h7f, $random(seed) & 12'hfff);
        end
        for (i = 0; i < 128; i = i + 1)
            read_one(i[6:0]);

        // Reset coincident with a pending request flushes valid; memory survives.
        @(negedge clk); rd_en = 1; rd_addr = 7'd37; rst_n = 0;
        @(posedge clk); #1;
        if (rd_valid) begin
            $display("FAIL RAM reset did not flush read valid"); fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;
        @(negedge clk); rd_en = 0; rst_n = 1;
        read_one(7'd37);

        $display("INFO tb_sync_1r1w_ram: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        if (fail_count == 0) $display("PASS tb_sync_1r1w_ram");
        else $fatal(1, "FAIL tb_sync_1r1w_ram");
        $finish;
    end
endmodule
