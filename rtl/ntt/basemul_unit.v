`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: basemul_unit
// Description:
//   Sequential resource-optimized base multiplication unit for Kyber / ML-KEM.
//
// Reference:
//   kyber768/ntt.c
//
// C reference:
//
//   r[0]  = fqmul(a[1], b[1]);
//   r[0]  = fqmul(r[0], zeta);
//   r[0] += fqmul(a[0], b[0]);
//
//   r[1]  = fqmul(a[0], b[1]);
//   r[1] += fqmul(a[1], b[0]);
//
// RTL equation:
//
//   t0 = mod_mul(a1, b1)
//   t1 = mod_mul(t0, zeta)
//   t2 = mod_mul(a0, b0)
//   r0 = mod_add(t1, t2)
//
//   t3 = mod_mul(a0, b1)
//   t4 = mod_mul(a1, b0)
//   r1 = mod_add(t3, t4)
//
// Architecture:
//   - 1 shared mod_mul
//   - 1 shared mod_add
//   - FSM controlled multi-cycle operation
//
// Datapath convention:
//   All inputs and outputs are canonical unsigned coefficients:
//       0 <= coeff < KYBER_Q
//
// Handshake:
//   - Assert start for at least 1 cycle when busy=0.
//   - Inputs are latched when start is accepted.
//   - done pulses for 1 cycle when r0/r1 are valid.
// -----------------------------------------------------------------------------

module basemul_unit #(
    parameter WIDTH = `KYBER_Q_WIDTH
)(
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    output wire busy,
    output wire done,

    input  wire [WIDTH-1:0] a0,
    input  wire [WIDTH-1:0] a1,
    input  wire [WIDTH-1:0] b0,
    input  wire [WIDTH-1:0] b1,
    input  wire [WIDTH-1:0] zeta,

    output wire [WIDTH-1:0] r0,
    output wire [WIDTH-1:0] r1
);
    
    //-----------------------------------------------------------------------------
    // FSM states
    //-----------------------------------------------------------------------------
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_MUL_A1B1    = 3'd1;
    localparam [2:0] ST_MUL_TO_ZETA = 3'd2;
    localparam [2:0] ST_MUL_A0B0    = 3'd3;
    localparam [2:0] ST_ADD_R0      = 3'd4;
    localparam [2:0] ST_MUL_A0B1    = 3'd5;
    localparam [2:0] ST_MUL_A1B0    = 3'd6;
    localparam [2:0] ST_ADD_R1      = 3'd7;

    reg [2:0] state;

    //-----------------------------------------------------------------------------
    // Latched inputs
    //-----------------------------------------------------------------------------
    reg [WIDTH-1:0] a0_reg;
    reg [WIDTH-1:0] a1_reg;
    reg [WIDTH-1:0] b0_reg;
    reg [WIDTH-1:0] b1_reg;
    reg [WIDTH-1:0] zeta_reg;

    //-----------------------------------------------------------------------------
    // Tempotary registers
    //-----------------------------------------------------------------------------
    reg [WIDTH-1:0] t0_reg;  // fqmul(a1, b1)
    reg [WIDTH-1:0] t1_reg;  // fqmul(a0, zeta)
    reg [WIDTH-1:0] t2_reg;  // fqmul(a0, b0)
    reg [WIDTH-1:0] t3_reg;  // fqmul(a0, b1)
    reg [WIDTH-1:0] t4_reg;  // fqmul(a1, b0)

    reg [WIDTH-1:0] r0_reg;
    reg [WIDTH-1:0] r1_reg;

    reg done_reg;

    assign busy = (state != ST_IDLE);
    assign done = done_reg;

    assign r0   = r0_reg;
    assign r1   = r1_reg;

    //-----------------------------------------------------------------------------
    // Shared mod_mul operand mux
    //-----------------------------------------------------------------------------
    reg  [WIDTH-1:0] mul_a;
    reg  [WIDTH-1:0] mul_b;
    wire [WIDTH-1:0] mul_out;

    always @(*) begin
        case (state)
            ST_MUL_A1B1: begin
                mul_a = a1_reg;
                mul_b = b1_reg;
            end

            ST_MUL_TO_ZETA: begin
                mul_a = t0_reg;
                mul_b = zeta_reg;
            end

            ST_MUL_A0B0: begin
                mul_a = a0_reg;
                mul_b = b0_reg;
            end

            ST_MUL_A0B1: begin
                mul_a = a0_reg;
                mul_b = b1_reg;
            end

            ST_MUL_A1B0: begin
                mul_a = a1_reg;
                mul_b = b0_reg;
            end

            default: begin
                mul_a = {WIDTH{1'b0}};
                mul_b = {WIDTH{1'b0}};
            end
        endcase
    end

    mod_mul u_mod_mul (
        .a (mul_a),
        .b (mul_b),
        .c (mul_out)
    );

    //-----------------------------------------------------------------------------
    // Shared mod_add operand mux
    //-----------------------------------------------------------------------------
    reg [WIDTH-1:0] add_a;
    reg [WIDTH-1:0] add_b;
    wire [WIDTH-1:0] add_out;

    always @(*) begin
        case (state)
            ST_ADD_R0: begin
                add_a = t1_reg;
                add_b = t2_reg;
            end

            ST_ADD_R1: begin
                add_a = t3_reg;
                add_b = t4_reg;
            end

            default: begin
                add_a = {WIDTH{1'b0}};
                add_b = {WIDTH{1'b0}};
            end
        endcase
    end

    mod_add u_mod_add (
        .a (add_a),
        .b (add_b),
        .c (add_out)
    );
    
    //-----------------------------------------------------------------------------
    // FSM sequential logic
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= ST_IDLE;

            a0_reg   <= {WIDTH{1'b0}};
            a1_reg   <= {WIDTH{1'b0}};
            b0_reg   <= {WIDTH{1'b0}};
            b1_reg   <= {WIDTH{1'b0}};
            zeta_reg <= {WIDTH{1'b0}};
                
            t0_reg   <= {WIDTH{1'b0}};
            t1_reg   <= {WIDTH{1'b0}};
            t2_reg   <= {WIDTH{1'b0}};
            t3_reg   <= {WIDTH{1'b0}};
            t4_reg   <= {WIDTH{1'b0}};

            r0_reg   <= {WIDTH{1'b0}};
            r1_reg   <= {WIDTH{1'b0}};

            done_reg <= 1'b0;
        end else begin
            done_reg <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        a0_reg   <= a0;  
                        a1_reg   <= a1;
                        b0_reg   <= b0;
                        b1_reg   <= b1;
                        zeta_reg <= zeta;

                        state <= ST_MUL_A1B1;
                    end
                end

                ST_MUL_A1B1: begin
                    t0_reg <= mul_out;
                    state  <= ST_MUL_TO_ZETA;
                end

                ST_MUL_TO_ZETA: begin
                    t1_reg <= mul_out;
                    state  <= ST_MUL_A0B0;
                end

                ST_MUL_A0B0: begin
                    t2_reg <= mul_out;
                    state  <= ST_ADD_R0;
                end

                ST_ADD_R0: begin
                    r0_reg <= add_out;
                    state  <= ST_MUL_A0B1;
                end

                ST_MUL_A0B1: begin
                    t3_reg <= mul_out;
                    state  <= ST_MUL_A1B0;
                end

                ST_MUL_A1B0: begin
                    t4_reg <= mul_out;
                    state  <= ST_ADD_R1;
                end

                ST_ADD_R1: begin
                    r1_reg   <= add_out;
                    done_reg <= 1'b1;
                    state    <= ST_IDLE;
                end

                default: begin
                    state    <= ST_IDLE;
                    done_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule
