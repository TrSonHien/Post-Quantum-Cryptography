`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: poly_buffer
// Description:
//   Simple polynomial coefficient buffer for Kyber / ML-KEM.
//
// Capacity:
//   256 coefficients, each coefficient is canonical unsigned:
//       0 <= coeff < KYBER_Q
//
// Purpose:
//   Used by ntt_core.v and intt_core.v to store r[256].
//
// Initial architecture:
//   - 2 asynchronous read ports
//   - 2 synchronous write ports
//
// Notes:
//   - This is a verification-friendly register-file version.
//   - Later, for ASIC/PPA, this can be replaced by SRAM/banked memory.
//   - There is no reset or memory initialization here. The owner must load all
//     256 coefficients before starting an NTT/INTT operation.
//   - If both write ports target the same address in the same clock, port B
//     wins because its nonblocking assignment appears later. NTT scheduling
//     should never generate equal addr_a/addr_b pairs.
// -----------------------------------------------------------------------------

module poly_buffer # (
    parameter ADDR_WIDTH = `KYBER_N_WIDTH,
    parameter DATA_WIDTH = `KYBER_Q_WIDTH,
    parameter DEPTH      = `KYBER_N
)(
    input wire clk,

    // Read port A
    input  wire [ADDR_WIDTH-1:0] rd_addr_a,
    output wire [DATA_WIDTH-1:0] rd_data_a,

    // Read port B
    input  wire [ADDR_WIDTH-1:0] rd_addr_b,
    output wire [DATA_WIDTH-1:0] rd_data_b,

    // Write port A
    input wire                  wr_en_a,
    input wire [ADDR_WIDTH-1:0] wr_addr_a,
    input wire [DATA_WIDTH-1:0] wr_data_a,
    
    // Write port B
    input wire                  wr_en_b,
    input wire [ADDR_WIDTH-1:0] wr_addr_b,
    input wire [DATA_WIDTH-1:0] wr_data_b
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Asynchronous reads
    assign rd_data_a = mem[rd_addr_a];
    assign rd_data_b = mem[rd_addr_b];
    
    // Synchronous writes
    always @(posedge clk) begin
        if (wr_en_a) begin
            mem[wr_addr_a] <= wr_data_a;
        end

        if (wr_en_b) begin
            mem[wr_addr_b] <= wr_data_b;
        end
     end
    
endmodule
