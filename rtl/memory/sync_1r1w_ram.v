`timescale 1ns/1ps

// Generic synchronous 1-read/1-write memory. Read requests accepted at edge t
// produce rd_valid/rd_data during cycle t+1. Memory and rd_data are not reset.
module sync_1r1w_ram #(
    parameter DATA_WIDTH = 12,
    parameter ADDR_WIDTH = 7,
    parameter DEPTH = 128
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg                   rd_valid,
    output reg  [DATA_WIDTH-1:0] rd_data,
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= rd_en;
            if (rd_en)
                rd_data <= mem[rd_addr];
            if (wr_en)
                mem[wr_addr] <= wr_data;
`ifndef SYNTHESIS
            if (rd_en && wr_en && (rd_addr == wr_addr))
                $fatal(1, "SYNC_RAM_COLLISION: same-address read/write is illegal");
            if (rd_en && (rd_addr >= DEPTH))
                $fatal(1, "SYNC_RAM_RANGE: read address out of range");
            if (wr_en && (wr_addr >= DEPTH))
                $fatal(1, "SYNC_RAM_RANGE: write address out of range");
`endif
        end
    end

endmodule
