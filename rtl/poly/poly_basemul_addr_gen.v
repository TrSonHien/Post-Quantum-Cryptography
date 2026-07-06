`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: poly_basemul_addr_gen
// Description:
//   Address schedule generator for Kyber poly_basemul_montgomery.
//
// Reference:
//   kyber768/poly.c
//
// C behavior:
//
//   for (i = 0; i < KYBER_N/4; i++) {
//       basemul(&r[4*i],   &a[4*i],   &b[4*i],   zetas[64+i]);
//       basemul(&r[4*i+2], &a[4*i+2], &b[4*i+2], -zetas[64+i]);
//   }
//
// This module generates 128 basemul operations:
//
//   op_idx = 0..127
//
// For even op_idx:
//   use coefficients 4*i, 4*i+1
//   use +zetas[64+i]
//
// For odd op_idx:
//   use coefficients 4*i+2, 4*i+3
//   use -zetas[64+i]
//
// Notes:
//   - This module only generates addresses and zeta control.
//   - It does not access memory.
//   - It does not perform basemul.
// -----------------------------------------------------------------------------

module poly_basemul_addr_gen #(
    parameter ADDR_WIDTH = `KYBER_N_WIDTH
)(
    input  wire clk,
    input  wire rst_n,

    input  wire start,

    output wire valid,
    output reg  busy,
    output reg  done,

    output wire [ADDR_WIDTH-1:0] a_addr0,
    output wire [ADDR_WIDTH-1:0] a_addr1,
    output wire [ADDR_WIDTH-1:0] b_addr0,
    output wire [ADDR_WIDTH-1:0] b_addr1,
    output wire [ADDR_WIDTH-1:0] r_addr0,
    output wire [ADDR_WIDTH-1:0] r_addr1,

    output wire [6:0] zeta_addr,
    output wire       zeta_neg,

    output wire [6:0] op_index
);

    localparam [6:0] LAST_OP = 7'd127;

    reg [6:0] op_reg;

    wire [5:0]            group_i;
    wire                  is_odd;
    wire [ADDR_WIDTH-1:0] base_addr;

    assign valid    = busy;
    assign op_index = op_reg;

    assign group_i = op_reg[6:1];
    assign is_odd  = op_reg[0];

    // base_addr = 4 * group_i
    assign base_addr = {group_i, 2'b0};

    assign a_addr0 = is_odd ? (base_addr + 8'd2) : base_addr;
    assign a_addr1 = is_odd ? (base_addr + 8'd3) : (base_addr + 8'd1);

    assign b_addr0 = a_addr0;
    assign b_addr1 = a_addr1;

    assign r_addr0 = a_addr0;
    assign r_addr1 = a_addr1;

    assign zeta_addr = 7'd64 + group_i;
    assign zeta_neg  = is_odd;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_reg <= 7'd0;
            busy   <= 1'b0;
            done   <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                op_reg <= 7'd0;
                busy   <= 1'b1;
            end else if (busy) begin
                if (op_reg == LAST_OP) begin
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    op_reg <= 7'b0;
                end else begin
                    op_reg <= op_reg + 1'b1;
                end
            end
        end
    end

endmodule
