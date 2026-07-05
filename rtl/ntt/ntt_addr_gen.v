`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: ntt_addr_gen
// Description:
//   Address schedule generator for Kyber forward NTT and inverse NTT.
//
// It generates one butterfly address pair per clock cycle:
//
//   addr_a = j
//   addr_b = j + len
//   zeta_addr = current zeta index
//
// Forward NTT reference:
//
//   k = 1;
//   for(len = 128; len >= 2; len >>= 1)
//     for(start = 0; start < 256; start = j + len) {
//       zeta = zetas[k++];
//       for(j = start; j < start + len; ++j)
//         butterfly(r[j], r[j+len], zeta);
//     }
//
// Inverse NTT reference:
//
//   k = 0;
//   for(len = 2; len <= 128; len <<= 1)
//     for(start = 0; start < 256; start = j + len) {
//       zeta = zetas_inv[k++];
//       for(j = start; j < start + len; ++j)
//         inverse_butterfly(r[j], r[j+len], zeta);
//     }
//
// Notes:
//   - This module only generates the 896 butterfly operations.
//   - INTT final scaling by zetas_inv[127] is NOT generated here.
//   - On a start pulse, the first valid schedule appears immediately after the
//     capturing posedge. Testbenches should sample the outputs after that
//     posedge, not after an extra cycle.
//   - done pulses for one cycle after the final valid schedule.
// -----------------------------------------------------------------------------

module ntt_addr_gen #(
    parameter ADDR_WIDTH = `KYBER_N_WIDTH,
    parameter ZETA_WIDTH = 7
)(
    input wire clk,
    input wire rst_n,

    input wire start,
    input wire mode,    // 0: forward NTT, 1: inverse NTT

    output wire valid,
    output reg  done,
    output reg  busy,

    output wire [ADDR_WIDTH-1:0] addr_a,
    output wire [ADDR_WIDTH-1:0] addr_b,
    output wire [ZETA_WIDTH-1:0] zeta_addr,
    output wire [ADDR_WIDTH-1:0] len_out
);

    localparam [8:0] N = 9'd256;

    // Latched mode while generator is running 
    reg mode_reg;

    // Current loop variables
    reg [ADDR_WIDTH-1:0] len_reg;
    reg [ADDR_WIDTH-1:0] start_reg;
    reg [ADDR_WIDTH-1:0] j_reg;
    reg [ZETA_WIDTH-1:0] zeta_reg;

    // 9-bit calculations are needed because start + 2*len can become 256.
    wire [8:0] group_last_j;
    wire [8:0] next_start;
    wire       at_last_j_in_group;
    wire       has_next_group;
    wire       at_final_stage;

    assign group_last_j = {1'b0, start_reg} + {1'b0, len_reg} - 9'd1;
    assign next_start   = {1'b0, start_reg} + ({1'b0, len_reg} << 1);

    assign at_last_j_in_group = ({1'b0, j_reg} == group_last_j);
    assign has_next_group     = (next_start < N);

    assign at_final_stage = (!mode_reg && (len_reg == 8'd2)) || (mode_reg && (len_reg == 8'd128));

    assign valid     = busy;
    assign addr_a    = j_reg;
    assign addr_b    = j_reg + len_reg;
    assign zeta_addr = zeta_reg;
    assign len_out   = len_reg;
  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_reg   <= 1'b0;
            len_reg    <= {ADDR_WIDTH{1'b0}};
            start_reg  <= {ADDR_WIDTH{1'b0}};
            j_reg      <= {ADDR_WIDTH{1'b0}};
            zeta_reg   <= {ZETA_WIDTH{1'b0}};
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                mode_reg <= mode;
                busy     <= 1'b1;

                start_reg <= {ADDR_WIDTH{1'b0}};
                j_reg     <= {ADDR_WIDTH{1'b0}};

                if (!mode) begin
                    // Forward NTT starts at len=128 and zetas[1]
                    len_reg  <= 8'd128;
                    zeta_reg <= 7'd1;
                end else begin
                    // Inverse NTT starts at len=2 and zetas_inv[0]
                    len_reg  <= 8'd2;
                    zeta_reg <= 7'd0;
                end

            end else if (busy) begin
                if (!at_last_j_in_group) begin
                   // Continue inside current group
                   j_reg <= j_reg + 1'b1;

                end else begin
                   // Current group finished
                   if (has_next_group) begin
                       // Move to next group in same stage
                       start_reg <= next_start[ADDR_WIDTH-1:0];
                       j_reg     <= next_start[ADDR_WIDTH-1:0];
                       zeta_reg  <= zeta_reg + 1'b1;

                   end else begin
                       // Current stage finished
                       if (at_final_stage) begin
                           // All butterfly stages finished 
                           busy <= 1'b0;
                           done <= 1'b1;

                       end else begin
                           // Move to next stage
                           start_reg <= {ADDR_WIDTH{1'b0}};
                           j_reg     <= {ADDR_WIDTH{1'b0}};
                           zeta_reg  <= zeta_reg + 1'b1;

                           if (!mode_reg)  
                               len_reg <= len_reg >> 1;  // /2
                           else 
                               len_reg <= len_reg << 1;  // *2
                        end
                    end
                end
            end
        end
    end

endmodule
