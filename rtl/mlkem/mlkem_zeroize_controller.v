`timescale 1ns / 1ps
// Fanout/collection controller for distributed physical scrub clients.
/*
 * Module: mlkem_zeroize_controller
 * Status: TEST_OR_COMPATIBILITY_ONLY
 * Purpose: ML-KEM controller, record checker, buffer, or implicit-rejection support.
 * Standard role: FIPS 203 Algorithms 16--21 support.
 * Input representation: FIPS byte records and controller metadata.
 * Output representation: FIPS byte records, shared secret, or completion metadata.
 * Interface: start/busy/done controller handshake.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module mlkem_zeroize_controller
    #(
        parameter integer CLIENTS = 4)
    (input wire clk,
     input wire rst_n,
     input wire start,
     output reg busy,
     output reg done,
     output reg error,
     output reg [CLIENTS - 1 : 0] client_start,
     input wire [CLIENTS - 1 : 0] client_done,
     output reg clear_secret_scalars);
    reg [CLIENTS - 1 : 0] seen;
    always @(posedge clk) begin
        done <= 0;
        client_start <= 0;
        clear_secret_scalars <= 0;
        if (!rst_n) begin
            busy <= 0;
            done <= 0;
            error <= 0;
            client_start <= 0;
            seen <= 0;
            clear_secret_scalars <= 0;
        end else if (start) begin
            if (busy)
                error <= 1;
            else begin
                busy <= 1;
                error <= 0;
                seen <= 0;
                client_start <= {CLIENTS{1'b1}};
                clear_secret_scalars <= 1;
            end
        end else if (busy) begin
            seen <= seen | client_done;
            if (&(seen | client_done)) begin
                busy <= 0;
                done <= 1;
                clear_secret_scalars <= 1;
            end
        end
    end
endmodule
