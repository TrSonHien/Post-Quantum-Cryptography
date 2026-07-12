`timescale 1ns/1ps

module tb_sync_1r1w_ram_collision;
    reg clk = 0, rst_n = 0, rd_en = 0, wr_en = 0;
    reg [6:0] rd_addr = 0, wr_addr = 0;
    reg [11:0] wr_data = 0;
    wire rd_valid;
    wire [11:0] rd_data;
    always #5 clk = ~clk;
    sync_1r1w_ram dut (clk, rst_n, rd_en, rd_addr, rd_valid, rd_data,
                       wr_en, wr_addr, wr_data);
    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1; rd_en = 1; wr_en = 1;
        rd_addr = 7'd19; wr_addr = 7'd19; wr_data = 12'd123;
        @(posedge clk); #2;
        $fatal(1, "FAIL collision assertion did not fire");
    end
endmodule
