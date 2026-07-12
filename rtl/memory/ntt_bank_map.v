`timescale 1ns/1ps

// M1 conflict-free map:
// boundary layout:   bank=i[p],          addr=remove_bit(i,p)
// transition layout: bank=i[p] xor i[r], addr=remove_bit(i,r)
module ntt_bank_map (
    input  wire [7:0] logical_index,
    input  wire [2:0] pair_bit,
    input  wire [2:0] addr_bit,
    input  wire       xor_layout,
    output wire       bank,
    output reg  [6:0] bank_addr
);

    integer source_bit;
    integer dest_bit;

    assign bank = logical_index[pair_bit] ^
                  (xor_layout ? logical_index[addr_bit] : 1'b0);

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
