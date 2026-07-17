`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: poly_basemul_montgomery
// Description:
//   Polynomial multiplication in NTT domain for Kyber / ML-KEM.
//
// Reference:
//   kyber768/poly.c: poly_basemul_montgomery()
//
// C reference:
//
//   for (i = 0; i < KYBER_N/4; i++) {
//       basemul(&r->coeffs[4*i],
//               &a->coeffs[4*i],
//               &b->coeffs[4*i],
//               zetas[64+i]);
//
//       basemul(&r->coeffs[4*i+2],
//               &a->coeffs[4*i+2],
//               &b->coeffs[4*i+2],
//               -zetas[64+i]);
//   }
//
// RTL behavior:
//   - Load polynomial A into internal A buffer.
//   - Load polynomial B into internal B buffer.
//   - On start, generate 128 basemul operations.
//   - Feed one basemul operation per cycle into pipelined basemul_unit.
//   - Delay output write addresses to match basemul pipeline latency.
//   - Write resulting polynomial R into internal R buffer.
//   - Read R through r_read_addr/r_read_data after done.
//
// Architecture:
//   - 3 poly_buffer instances:
//       A buffer
//       B buffer
//       R buffer
//   - 1 poly_basemul_addr_gen
//   - 1 zetas_rom
//   - 1 pipelined basemul_unit
//
// Assumptions:
//   - basemul_unit has 3-cycle valid latency.
//   - basemul_unit has no backpressure.
//   - Current basemul_unit interface:
//
//       in_valid
//       a0, a1, b0, b1, zeta
//       out_valid
//       r0, r1
//
// Datapath convention:
//   All coefficients are unsigned canonical:
//       0 <= coeff < KYBER_Q
//
// Notes:
//   - This module implements the poly-level part of FIPS 203 MultiplyNTTs.
//   - zeta_neg = 1 means use KYBER_Q - zeta, i.e. canonical form of -zeta.
//   - done is asserted only after the final basemul output has been written
//     into the R buffer.
//   - Do not assert a_load_en or b_load_en in the same cycle as start.
// -----------------------------------------------------------------------------
/*
 * Module: poly_basemul_montgomery
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: basemul_unit, poly_basemul_addr_gen, poly_buffer, zetas_rom.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module poly_basemul_montgomery
    #(
        parameter ADDR_WIDTH = `KYBER_N_WIDTH,
        parameter DATA_WIDTH = `KYBER_Q_WIDTH)
    (
        input wire clk,
        input wire rst_n,

        // Control
        input wire start,
        output wire busy,
        output wire done,

        // Load polynomial A before start
        input wire a_load_en,
        input wire [ADDR_WIDTH - 1 : 0] a_load_addr,
        input wire [DATA_WIDTH - 1 : 0] a_load_data,

        // Load polynomial B before start
        input wire b_load_en,
        input wire [ADDR_WIDTH - 1 : 0] b_load_addr,
        input wire [DATA_WIDTH - 1 : 0] b_load_data,

        // Read result polynomial R after done
        input wire [ADDR_WIDTH - 1 : 0] r_read_addr,
        output wire [DATA_WIDTH - 1 : 0] r_read_data);

    // -----------------------------------------------------------------------------
    // Local constants
    // -----------------------------------------------------------------------------
    localparam ST_IDLE = 1'b0;
    localparam ST_RUN = 1'b1;

    localparam [DATA_WIDTH - 1 : 0] Q = `KYBER_Q;

    // -----------------------------------------------------------------------------
    // Internal state
    // -----------------------------------------------------------------------------
    reg state;
    reg done_reg;

    assign busy = (state != ST_IDLE);
    assign done = done_reg;

    wire start_accepted;
    assign start_accepted = start && (state == ST_IDLE);

    // -----------------------------------------------------------------------------
    // Address generator
    // -----------------------------------------------------------------------------
    wire gen_valid;
    wire gen_busy;
    wire gen_done;

    wire [ADDR_WIDTH - 1 : 0] gen_a_addr0;
    wire [ADDR_WIDTH - 1 : 0] gen_a_addr1;
    wire [ADDR_WIDTH - 1 : 0] gen_b_addr0;
    wire [ADDR_WIDTH - 1 : 0] gen_b_addr1;
    wire [ADDR_WIDTH - 1 : 0] gen_r_addr0;
    wire [ADDR_WIDTH - 1 : 0] gen_r_addr1;

    wire [6 : 0] gen_zeta_addr;
    wire gen_zeta_neg;
    wire [6 : 0] gen_op_index;

    poly_basemul_addr_gen u_poly_basemul_addr_gen(
                                  .clk(clk),
                                  .rst_n(rst_n),
                                  .start(start_accepted),

                                  .valid(gen_valid),
                                  .busy(gen_busy),
                                  .done(gen_done),

                                  .a_addr0(gen_a_addr0),
                                  .a_addr1(gen_a_addr1),
                                  .b_addr0(gen_b_addr0),
                                  .b_addr1(gen_b_addr1),
                                  .r_addr0(gen_r_addr0),
                                  .r_addr1(gen_r_addr1),

                                  .zeta_addr(gen_zeta_addr),
                                  .zeta_neg(gen_zeta_neg),

                                  .op_index(gen_op_index));

    // -----------------------------------------------------------------------------
    // Zeta ROM and sign handling
    // -----------------------------------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] zeta_raw;
    wire [DATA_WIDTH - 1 : 0] zeta_used;

    zetas_rom u_zetas_rom(
                      .inverse(1'b0),
                      .addr(gen_zeta_addr),
                      .zeta(zeta_raw));

    // Canonical form of -zeta is q - zeta
    //
    // For poly_basemul_montgomery, zeta_addr is 64..127, and those zetas are
    // nonzero. The zero check is kept for robustness
    assign zeta_used = gen_zeta_neg ? ((zeta_raw == {DATA_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : (Q - zeta_raw)) : zeta_raw;

    // -----------------------------------------------------------------------------
    // Polynomial A buffer
    // -----------------------------------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] a_rd_data0;
    wire [DATA_WIDTH - 1 : 0] a_rd_data1;

    wire a_load_allowed;
    assign a_load_allowed = a_load_en && (state == ST_IDLE) && !start;

    poly_buffer u_a_buffer(
                        .clk(clk),

                        .rd_addr_a(gen_a_addr0),
                        .rd_data_a(a_rd_data0),

                        .rd_addr_b(gen_a_addr1),
                        .rd_data_b(a_rd_data1),

                        .wr_en_a(a_load_allowed),
                        .wr_addr_a(a_load_addr),
                        .wr_data_a(a_load_data),

                        .wr_en_b(1'b0),
                        .wr_addr_b({ADDR_WIDTH{1'b0}}),
                        .wr_data_b({DATA_WIDTH{1'b0}}));

    // -----------------------------------------------------------------------------
    // Polynomial B buffer
    // -----------------------------------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] b_rd_data0;
    wire [DATA_WIDTH - 1 : 0] b_rd_data1;

    wire b_load_allowed;
    assign b_load_allowed = b_load_en && (state == ST_IDLE) && !start;

    poly_buffer u_b_buffer(
                        .clk(clk),

                        .rd_addr_a(gen_b_addr0),
                        .rd_data_a(b_rd_data0),

                        .rd_addr_b(gen_b_addr1),
                        .rd_data_b(b_rd_data1),

                        .wr_en_a(b_load_allowed),
                        .wr_addr_a(b_load_addr),
                        .wr_data_a(b_load_data),

                        .wr_en_b(1'b0),
                        .wr_addr_b({ADDR_WIDTH{1'b0}}),
                        .wr_data_b({DATA_WIDTH{1'b0}}));

    // -----------------------------------------------------------------------------
    // Pipelined basemul unit
    // -----------------------------------------------------------------------------
    wire basemul_in_valid;
    wire basemul_out_valid;

    wire [DATA_WIDTH - 1 : 0] basemul_r0;
    wire [DATA_WIDTH - 1 : 0] basemul_r1;

    assign basemul_in_valid = gen_valid && (state == ST_RUN);

    basemul_unit u_basemul_unit(
                         .clk(clk),
                         .rst_n(rst_n),

                         .in_valid(basemul_in_valid),

                         .a0(a_rd_data0),
                         .a1(a_rd_data1),
                         .b0(b_rd_data0),
                         .b1(b_rd_data1),
                         .zeta(zeta_used),

                         .out_valid(basemul_out_valid),
                         .r0(basemul_r0),
                         .r1(basemul_r1));

    // -----------------------------------------------------------------------------
    // Delay write addresses to match basemul_unit 3-cycle valid latency
    // -----------------------------------------------------------------------------
    reg [ADDR_WIDTH - 1 : 0] r_addr0_d0;
    reg [ADDR_WIDTH - 1 : 0] r_addr0_d1;
    reg [ADDR_WIDTH - 1 : 0] r_addr0_d2;

    reg [ADDR_WIDTH - 1 : 0] r_addr1_d0;
    reg [ADDR_WIDTH - 1 : 0] r_addr1_d1;
    reg [ADDR_WIDTH - 1 : 0] r_addr1_d2;

    reg last_d0;
    reg last_d1;
    reg last_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_addr0_d0 <= {ADDR_WIDTH{1'b0}};
            r_addr0_d1 <= {ADDR_WIDTH{1'b0}};
            r_addr0_d2 <= {ADDR_WIDTH{1'b0}};

            r_addr1_d0 <= {ADDR_WIDTH{1'b0}};
            r_addr1_d1 <= {ADDR_WIDTH{1'b0}};
            r_addr1_d2 <= {ADDR_WIDTH{1'b0}};

            last_d0 <= 1'b0;
            last_d1 <= 1'b0;
            last_d2 <= 1'b0;
        end else begin
            r_addr0_d0 <= gen_r_addr0;
            r_addr0_d1 <= r_addr0_d0;
            r_addr0_d2 <= r_addr0_d1;

            r_addr1_d0 <= gen_r_addr1;
            r_addr1_d1 <= r_addr1_d0;
            r_addr1_d2 <= r_addr1_d1;

            last_d0 <= basemul_in_valid && (gen_op_index == 7'd127);
            last_d1 <= last_d0;
            last_d2 <= last_d1;
        end
    end

    // -----------------------------------------------------------------------------
    // Result write control
    // -----------------------------------------------------------------------------
    wire r_write_valid;
    wire r_write_last;

    assign r_write_valid = basemul_out_valid;
    assign r_write_last = last_d2;

    // -----------------------------------------------------------------------------
    // Polynomial R buffer
    // -----------------------------------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] unused_r_rd_data_b;

    poly_buffer u_r_buffer(
                        .clk(clk),

                        // Enternal readback
                        .rd_addr_a(r_read_addr),
                        .rd_data_a(r_read_data),

                        .rd_addr_b({ADDR_WIDTH{1'b0}}),
                        .rd_data_b(unused_r_rd_data_b),

                        // Write r0 to delayed r_addr0
                        .wr_en_a(r_write_valid),
                        .wr_addr_a(r_addr0_d2),
                        .wr_data_a(basemul_r0),

                        // Write r1 to delayed r_addr1
                        .wr_en_b(r_write_valid),
                        .wr_addr_b(r_addr1_d2),
                        .wr_data_b(basemul_r1));

    // -----------------------------------------------------------------------------
    // Main FSM
    // -----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            done_reg <= 1'b0;
        end else begin
            done_reg <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    // r_write_valid/r_write_last are high during the cycle
                    // before the final synchronous R-buffer write edge
                    // Therefore, the transition below occurs on the same edge
                    // that writes the last basemul result into R buffer
                    if (r_write_valid && r_write_last) begin
                        state <= ST_IDLE;
                        done_reg <= 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done_reg <= 1'b0;
                end
            endcase
        end
    end
endmodule
