`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: intt_core
// Description:
//   Inverse NTT core for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c
//
// Function:
//   Performs in-place inverse NTT on 256 polynomial coefficients.
//
// Inverse NTT reference:
//
//   k = 0;
//   for (len = 2; len <= 128; len <<= 1) {
//       for (start = 0; start < 256; start = j + len) {
//           zeta = zetas_inv[k++];
//           for (j = start; j < start + len; j++) {
//               t = r[j];
//               r[j] = barrett_reduce(t + r[j + len]);
//               r[j + len] = t - r[j + len];
//               r[j + len] = fqmul(zeta, r[j + len]);
//           }
//       }
//   }
//
//   for (j = 0; j < 256; j++)
//       r[j] = fqmul(r[j], zetas_inv[127]);
//
// RTL convention:
//   All external coefficient values are canonical unsigned:
//       0 <= coeff < KYBER_Q
//
// Architecture:
//   - 1 inverse butterfly per cycle during RUN phase
//   - 1 coefficient scaling per cycle during SCALE phase
//   - Shared mod_mul for both inverse butterfly and final scaling
//   - poly_buffer is used as in-place storage for r[256]
//
// Notes:
//   - Core done is asserted only after final scaling is complete.
//   - ntt_addr_gen done only means inverse butterfly schedule is finished.
// -----------------------------------------------------------------------------
/*
 * Module: intt_core
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: NTT/INTT arithmetic leaf, scheduler, ROM, or transform controller.
 * Standard role: FIPS 203 Algorithms 9--12 support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mod_add, mod_mul, mod_sub, ntt_addr_gen, poly_buffer, zetas_rom.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module intt_core
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

        // Load input polynomial before start
        input wire load_en,
        input wire [ADDR_WIDTH - 1 : 0] load_addr,
        input wire [DATA_WIDTH - 1 : 0] load_data,

        // Read output polynomial after done
        input wire [ADDR_WIDTH - 1 : 0] read_addr,
        output wire [DATA_WIDTH - 1 : 0] read_data);

    // -----------------------------------------------------------------------------
    // State machine
    // -----------------------------------------------------------------------------
    localparam [1 : 0] ST_IDLE = 2'd0;
    localparam [1 : 0] ST_RUN = 2'd1;
    localparam [1 : 0] ST_SCALE = 2'd2;

    reg [1 : 0] state;
    reg [ADDR_WIDTH - 1 : 0] scale_idx;
    reg done_reg;

    wire addr_start;

    // -----------------------------------------------------------------------------
    // Address generator signals
    // -----------------------------------------------------------------------------
    wire gen_valid;
    wire gen_done;
    wire gen_busy;

    wire [ADDR_WIDTH - 1 : 0] gen_addr_a;
    wire [ADDR_WIDTH - 1 : 0] gen_addr_b;
    wire [6 : 0] gen_zeta_addr;
    wire [ADDR_WIDTH - 1 : 0] gen_len;

    assign addr_start = start && (state == ST_IDLE);
    assign done = done_reg;
    assign busy = (state != ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            scale_idx <= {ADDR_WIDTH{1'b0}};
            done_reg <= 1'b0;
        end else begin
            done_reg <= 1'b0;

            case (state)
                ST_IDLE: begin
                    scale_idx <= {ADDR_WIDTH{1'b0}};

                    if (start) begin
                        state <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    // gen_done means the 896 inverse butterfly schedules
                    // have completed. The final butterfly write has already
                    // happened on the edge that produced gen_done
                    if (gen_done) begin
                        state <= ST_SCALE;
                        scale_idx <= {ADDR_WIDTH{1'b0}};
                    end
                end

                ST_SCALE: begin
                    // One final-scale write happens per cycle.
                    // When scale_idx == 255, the current edge writes the last
                    // coefficient, then core returns to IDLE and pulses done.
                    if (scale_idx == 8'd255) begin
                        state <= ST_IDLE;
                        scale_idx <= {ADDR_WIDTH{1'b0}};
                        done_reg <= 1'b1;
                    end else begin
                        scale_idx <= scale_idx + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    scale_idx <= {ADDR_WIDTH{1'b0}};
                    done_reg <= 1'b0;
                end
            endcase
        end
    end

    // -----------------------------------------------------------------------------
    // Address generator: inverse mode
    // -----------------------------------------------------------------------------
    ntt_addr_gen u_ntt_addr_gen(
                         .clk(clk),
                         .rst_n(rst_n),
                         .start(addr_start),
                         .mode(1'b1),
                         // inverse NTT mode

                         .valid(gen_valid),
                         .done(gen_done),
                         .busy(gen_busy),

                         .addr_a(gen_addr_a),
                         .addr_b(gen_addr_b),
                         .zeta_addr(gen_zeta_addr),
                         .len_out(gen_len));

    // -----------------------------------------------------------------------------
    // Zeta ROM: inverse table
    // -----------------------------------------------------------------------------
    wire [6 : 0] zeta_addr_mux;
    wire [DATA_WIDTH - 1 : 0] zeta;

    // During RUN:
    // use zetas_inv[gen_zeta_addr]
    //
    // During SCALE:
    // use zetas_inv[127]
    assign zeta_addr_mux = (state == ST_SCALE) ? 7'd127 : gen_zeta_addr;

    zetas_rom u_zetas_rom(
                      .inverse(1'b1),
                      .addr(zeta_addr_mux),
                      .zeta(zeta));

    // -----------------------------------------------------------------------------
    // Polynomial buffer
    // -----------------------------------------------------------------------------
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

    // Read address selection:
    //
    // RUN:
    //  read r[j] and r[j+len]
    //
    // SCALE:
    //  read r[scale_idx]
    //
    // IDLE:
    //  expose read_addr for external readback
    assign buf_rd_addr_a = (state == ST_RUN) ? gen_addr_a : (state == ST_SCALE) ? scale_idx
                                                                                : read_addr;

    assign buf_rd_addr_b = (state == ST_RUN) ? gen_addr_b : {ADDR_WIDTH{1'b0}};

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

    // -----------------------------------------------------------------------------
    // Shared inverse butterfly / scale datapath
    // -----------------------------------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] sum;
    wire [DATA_WIDTH - 1 : 0] diff;

    wire [DATA_WIDTH - 1 : 0] mul_in_a;
    wire [DATA_WIDTH - 1 : 0] mul_in_b;
    wire [DATA_WIDTH - 1 : 0] mul_out;

    // Inverse butterfly
    // sum  = a + b mod q
    // diff = a - b mod q
    mod_add u_mod_add(
                    .a(buf_rd_data_a),
                    .b(buf_rd_data_b),
                    .c(sum));

    mod_sub u_mod_sub(
                    .a(buf_rd_data_a),
                    .b(buf_rd_data_b),
                    .c(diff));

    // Share mod_mul:
    //
    // RUN phase:
    //  mul_out = mod_mul(zeta, diff)
    //
    // SCALE phase:
    //  mul_out = mod_mul(zetas_inv[127], r[scale_idx])
    assign mul_in_a = zeta;
    assign mul_in_b = (state == ST_SCALE) ? buf_rd_data_a : diff;

    mod_mul u_mod_mul(
                    .a(mul_in_a),
                    .b(mul_in_b),
                    .c(mul_out));

    // -----------------------------------------------------------------------------
    // Writeback mux
    // -----------------------------------------------------------------------------
    wire load_allowed;

    assign load_allowed = load_en && (state == ST_IDLE) && !start;

    // Write port A
    //
    // RUN:
    //  r[j] = sum
    //
    // SCALE:
    //  r[scale_idx] = mul_out
    //
    // IDLE:
    //  external load through load interface
    assign buf_wr_en_a = ((state == ST_RUN) && gen_valid) || (state == ST_SCALE) || load_allowed;

    assign buf_wr_addr_a = (state == ST_RUN) ? gen_addr_a : (state == ST_SCALE) ? scale_idx
                                                                                : load_addr;

    assign buf_wr_data_a = (state == ST_RUN) ? sum : (state == ST_SCALE) ? mul_out
                                                                         : load_data;

    // Write port B is only used during inverse butterfly RUN phase:
    //
    //  r[j+len] = mod_mul(zeta, diff)
    assign buf_wr_en_b = (state == ST_RUN) && gen_valid;
    assign buf_wr_addr_b = gen_addr_b;
    assign buf_wr_data_b = mul_out;
endmodule
