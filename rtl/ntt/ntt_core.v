`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: ntt_core
// Description:
//   Forward NTT core for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c
//
// Function:
//   Performs in-place forward NTT on 256 polynomial coefficients.
//
// Architecture:
//   - 1 butterfly operation per cycle
//   - poly_buffer provides 2 asynchronous read ports and 2 synchronous write ports
//   - ntt_addr_gen generates addr_a, addr_b, and zeta_addr
//   - zetas_rom provides zetas[zeta_addr]
//   - butterfly_unit computes:
//
//       t     = fqmul(zeta, b)
//       out_a = a + t mod q
//       out_b = a - t mod q
//
// Interface convention:
//   Coefficients are unsigned canonical values:
//       0 <= coeff < KYBER_Q
//
// Notes:
//   - This is a verification-friendly first architecture.
//   - It is not yet pipelined for maximum timing performance.
//   - INTT final scaling is not handled here.
//   - Timing model:
//       * ntt_addr_gen presents a schedule after a clock edge.
//       * poly_buffer reads are asynchronous, so the butterfly sees those
//         operands during the cycle.
//       * poly_buffer writes are synchronous, so the butterfly result is written
//         on the next clock edge using the schedule that was stable before that
//         edge.
//       * The final butterfly write occurs on the same edge that raises done.
//   - Do not assert load_en in the same cycle as start or while busy is high.
// -----------------------------------------------------------------------------
/*
 * Module: ntt_core
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: NTT/INTT arithmetic leaf, scheduler, ROM, or transform controller.
 * Standard role: FIPS 203 Algorithms 9--12 support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: no explicit payload array; child/local combinational state only.
 * Submodules: butterfly_unit, ntt_addr_gen, poly_buffer, zetas_rom.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module ntt_core
    #(
        parameter ADDR_WIDTH = `KYBER_N_WIDTH,
        // 8 bits for 256 coefficients
        parameter DATA_WIDTH = `KYBER_Q_WIDTH // 12 bits for q=3329 coefficients
    )
    (
        input wire clk,
        input wire rst_n,

        // Control
        input wire start,
        output wire busy,
        output wire done,

        // Load input polynomial before start
        input wire load_en,
        input wire [ADDR_WIDTH - 1 : 0] load_addr,
        input wire [DATA_WIDTH - 1 : 0] load_data,

        // Read output polynomial after done
        input wire [ADDR_WIDTH - 1 : 0] read_addr,
        output wire [DATA_WIDTH - 1 : 0] read_data);

    // ------------------------------------------------
    // Address generator signals
    // ------------------------------------------------
    wire gen_valid;
    wire gen_done;
    wire gen_busy;

    wire [ADDR_WIDTH - 1 : 0] gen_addr_a;
    wire [ADDR_WIDTH - 1 : 0] gen_addr_b;
    wire [6 : 0] gen_zeta_addr;
    wire [ADDR_WIDTH - 1 : 0] gen_len;

    // Forward NTT only: mode = 0
    ntt_addr_gen u_ntt_addr_gen(
                         .clk(clk),
                         .rst_n(rst_n),
                         .start(start),
                         .mode(1'b0),

                         .valid(gen_valid),
                         .done(gen_done),
                         .busy(gen_busy),

                         .addr_a(gen_addr_a),
                         .addr_b(gen_addr_b),
                         .zeta_addr(gen_zeta_addr),
                         .len_out(gen_len));

    assign busy = gen_busy;
    assign done = gen_done;

    // ------------------------------------------------
    // Zeta ROM
    // ------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] zeta_raw;
    wire [DATA_WIDTH - 1 : 0] zeta;

    zetas_rom u_zetas_rom(
                      .inverse(1'b0),
                      .addr(gen_zeta_addr),
                      .zeta(zeta_raw));

    // zetas are positive and less than q, so DATA_WIDTH bits are enough.
    assign zeta = zeta_raw[DATA_WIDTH - 1 : 0];

    // ------------------------------------------------
    // Polynomial buffer
    // ------------------------------------------------
    wire [ADDR_WIDTH - 1 : 0] buf_rd_addr_a;
    wire [ADDR_WIDTH - 1 : 0] buf_rd_addr_b;
    wire [DATA_WIDTH - 1 : 0] buf_rd_data_a;
    wire [DATA_WIDTH - 1 : 0] buf_rd_data_b;

    wire buf_wr_en_a;
    wire buf_wr_en_b;
    wire [ADDR_WIDTH - 1 : 0] buf_wr_addr_a;
    wire [ADDR_WIDTH - 1 : 0] buf_wr_addr_b;
    wire [DATA_WIDTH - 1 : 0] buf_wr_data_a;
    wire [DATA_WIDTH - 1 : 0] buf_wr_data_b;

    // During NTT, read butterfly operands. When idle, expose read port A for
    // external result readback.
    assign buf_rd_addr_a = gen_busy ? gen_addr_a : read_addr;
    assign buf_rd_addr_b = gen_busy ? gen_addr_b : {ADDR_WIDTH{1'b0}};

    assign read_data = buf_rd_data_a;

    poly_buffer u_poly_buffer(
                        .clk(clk),

                        .rd_addr_a(buf_rd_addr_a),
                        .rd_data_a(buf_rd_data_a),

                        .rd_addr_b(buf_rd_addr_b),
                        .rd_data_b(buf_rd_data_b),

                        .wr_en_a(buf_wr_en_a),
                        .wr_addr_a(buf_wr_addr_a),
                        .wr_data_a(buf_wr_data_a),

                        .wr_en_b(buf_wr_en_b),
                        .wr_addr_b(buf_wr_addr_b),
                        .wr_data_b(buf_wr_data_b));

    // ------------------------------------------------
    // Forward butterfly
    // ------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] bf_a_out;
    wire [DATA_WIDTH - 1 : 0] bf_b_out;

    butterfly_unit u_butterfly_unit(
                           .a_in(buf_rd_data_a),
                           .b_in(buf_rd_data_b),
                           .zeta(zeta),

                           .a_out(bf_a_out),
                           .b_out(bf_b_out));

    // ------------------------------------------------------
    // Writeback mux
    // ------------------------------------------------------
    // If NTT is active, write butterfly outputs. If idle, allow external
    // loading through write port A.
    //
    // Do not assert load_en while busy/start is active
    // ------------------------------------------------------
    wire load_allowed;

    assign load_allowed = load_en && !gen_busy && !start;

    assign buf_wr_en_a = gen_valid || load_allowed;
    assign buf_wr_addr_a = gen_valid ? gen_addr_a : load_addr;
    assign buf_wr_data_a = gen_valid ? bf_a_out : load_data;

    assign buf_wr_en_b = gen_valid;
    assign buf_wr_addr_b = gen_addr_b;
    assign buf_wr_data_b = bf_b_out;
endmodule
