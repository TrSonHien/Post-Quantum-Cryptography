`timescale 1ns / 1ps

// M1 conflict-free map:
// boundary layout:   bank=i[p],          addr=remove_bit(i,p)
// transition layout: bank=i[p] xor i[r], addr=remove_bit(i,r)
/*
 * Module: ntt_bank_map
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Synchronous storage, bank mapping, or ping-pong ownership primitive.
 * Standard role: workspace/bank ownership support.
 * Input representation: declared payload and control metadata.
 * Output representation: declared payload and control metadata.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: combinational address/bank mapping.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module ntt_bank_map
    (input wire [7 : 0] logical_index,
     input wire [2 : 0] pair_bit,
     input wire [2 : 0] addr_bit,
     input wire xor_layout,
     output wire bank,
     output reg [6 : 0] bank_addr);

    integer source_bit;
    integer dest_bit;

    assign bank = logical_index[pair_bit] ^ (xor_layout ? logical_index[addr_bit] : 1'b0);

    always @* begin
        bank_addr = 7'b0;
        dest_bit = 0;
        for (source_bit = 0; source_bit < 8; source_bit = source_bit + 1) begin
            if (source_bit != addr_bit) begin
                bank_addr[dest_bit] = logical_index[source_bit];
                dest_bit = dest_bit + 1;
            end
        end
    end
endmodule
