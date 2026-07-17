`timescale 1ns / 1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: poly_add
// Description:
//   Coefficient-wise modular addition of two Kyber polynomials.
//
// Mathematical operation:
//
//   r[i] = (a[i] + b[i]) mod KYBER_Q
//   for i = 0..KYBER_N-1
//
// C reference:
//   kyber768/poly.c: poly_add()
//
// Important difference from the C reference:
//   The C implementation performs lazy signed addition and reduces later.
//   This RTL follows the project-wide canonical coefficient convention and
//   therefore applies modular reduction immediately through mod_add.
//
// Architecture:
//   - Internal polynomial A buffer
//   - Internal polynomial B buffer
//   - Internal result R buffer
//   - Two coefficients processed per cycle
//   - Two parallel mod_add instances
//
// Performance:
//   - Processing cycles: KYBER_N / 2 = 128 cycles
//   - Throughput: 2 coefficients per cycle
//
// Interface convention:
//   - All coefficients are unsigned and canonical:
//       0 <= coefficient < KYBER_Q
//   - A and B must be loaded before start.
//   - start should be a one-cycle pulse.
//   - done is a one-cycle pulse.
//   - done is asserted on the same edge that writes the final coefficient pair.
//   - Internal memories are not cleared by reset.
// -----------------------------------------------------------------------------
/*
 * Module: poly_add
 * Status: LEGACY_OR_SUPERSEDED
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: mod_add, poly_buffer.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module poly_add
    #(
        parameter ADDR_WIDTH = `KYBER_N_WIDTH,
        parameter DATA_WIDTH = `KYBER_Q_WIDTH)
    (
        input wire clk,
        input wire rst_n,

        input wire start,
        output wire busy,
        output reg done,

        input wire a_load_en,
        input wire [ADDR_WIDTH - 1 : 0] a_load_addr,
        input wire [DATA_WIDTH - 1 : 0] a_load_data,

        input wire b_load_en,
        input wire [ADDR_WIDTH - 1 : 0] b_load_addr,
        input wire [DATA_WIDTH - 1 : 0] b_load_data,

        input wire [ADDR_WIDTH - 1 : 0] r_read_addr,
        output wire [DATA_WIDTH - 1 : 0] r_read_data);
    localparam ST_IDLE = 1'b0;
    localparam ST_RUN = 1'b1;

    localparam [ADDR_WIDTH - 1 : 0] LAST_BASE_ADDR = `KYBER_N - 2;

    reg [ADDR_WIDTH - 1 : 0] coeff_base;
    reg state;

    assign busy = (state == ST_RUN);

    wire start_accepted;
    assign start_accepted = start && (state == ST_IDLE);

    // -----------------------------------------------------
    // Current coeff addr
    // -----------------------------------------------------
    wire [ADDR_WIDTH - 1 : 0] coeff_addr0;
    wire [ADDR_WIDTH - 1 : 0] coeff_addr1;

    assign coeff_addr0 = coeff_base;
    assign coeff_addr1 = coeff_base + 1'b1;

    // -----------------------------------------------------
    // Loading is allowed only while idle
    // -----------------------------------------------------
    wire a_load_allowed;
    wire b_load_allowed;

    assign a_load_allowed = a_load_en && (state == ST_IDLE) && !start_accepted;
    assign b_load_allowed = b_load_en && (state == ST_IDLE) && !start_accepted;

    // -----------------------------------------------------
    // Polynimial A buffer
    // -----------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] a_coeff0;
    wire [DATA_WIDTH - 1 : 0] a_coeff1;

    poly_buffer u_a_buffer(
                        .clk(clk),

                        .rd_addr_a(coeff_addr0),
                        .rd_data_a(a_coeff0),

                        .rd_addr_b(coeff_addr1),
                        .rd_data_b(a_coeff1),

                        .wr_en_a(a_load_allowed),
                        .wr_addr_a(a_load_addr),
                        .wr_data_a(a_load_data),

                        .wr_en_b(1'b0),
                        .wr_addr_b({ADDR_WIDTH{1'b0}}),
                        .wr_data_b({DATA_WIDTH{1'b0}}));

    // -----------------------------------------------------
    // Polynimial B buffer
    // -----------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] b_coeff0;
    wire [DATA_WIDTH - 1 : 0] b_coeff1;

    poly_buffer u_b_buffer(
                        .clk(clk),

                        .rd_addr_a(coeff_addr0),
                        .rd_data_a(b_coeff0),

                        .rd_addr_b(coeff_addr1),
                        .rd_data_b(b_coeff1),

                        .wr_en_a(b_load_allowed),
                        .wr_addr_a(b_load_addr),
                        .wr_data_a(b_load_data),

                        .wr_en_b(1'b0),
                        .wr_addr_b({ADDR_WIDTH{1'b0}}),
                        .wr_data_b({DATA_WIDTH{1'b0}}));

    // -----------------------------------------------------
    // Two parallel modular additions
    // -----------------------------------------------------
    wire [DATA_WIDTH - 1 : 0] add_result0;
    wire [DATA_WIDTH - 1 : 0] add_result1;

    mod_add u_a_add(
                    .a(a_coeff0),
                    .b(b_coeff0),
                    .c(add_result0));

    mod_add u_b_add(
                    .a(a_coeff1),
                    .b(b_coeff1),
                    .c(add_result1));

    // -----------------------------------------------------
    // Polynomial R buffer
    // -----------------------------------------------------
    wire result_write_en;
    wire [DATA_WIDTH - 1 : 0] unused_r_read_data_b;

    assign result_write_en = (state == ST_RUN);

    poly_buffer u_r_buffer(
                        .clk(clk),

                        .rd_addr_a(r_read_addr),
                        .rd_data_a(r_read_data),

                        .rd_addr_b({ADDR_WIDTH{1'b0}}),
                        .rd_data_b(unused_r_read_data_b),

                        .wr_en_a(result_write_en),
                        .wr_addr_a(coeff_addr0),
                        .wr_data_a(add_result0),

                        .wr_en_b(result_write_en),
                        .wr_addr_b(coeff_addr1),
                        .wr_data_b(add_result1));

    // -----------------------------------------------------
    // Main control FSM
    // -----------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            coeff_base <= {ADDR_WIDTH{1'b0}};
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    coeff_base <= {ADDR_WIDTH{1'b0}};

                    if (start_accepted) begin
                        state <= ST_RUN;
                        coeff_base <= {ADDR_WIDTH{1'b0}};
                    end
                end

                ST_RUN: begin
                    if (coeff_base == LAST_BASE_ADDR) begin
                        state <= ST_IDLE;
                        coeff_base <= {ADDR_WIDTH{1'b0}};
                        done <= 1'b1;
                    end else begin
                        coeff_base <= coeff_base + 2;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    coeff_base <= {ADDR_WIDTH{1'b0}};
                    done <= 1'b0;
                end
            endcase
        end
    end
endmodule
