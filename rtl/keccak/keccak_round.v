`timescale 1ns / 1ps
/*
 * Module: keccak_round
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Keccak permutation, sponge, SHA3/SHAKE, or ML-KEM hash wrapper.
 * Standard role: FIPS 202 and FIPS 203 hash support.
 * Input representation: low-byte-first stream or Keccak state lanes.
 * Output representation: hash/XOF stream or updated Keccak state.
 * Interface: combinational or valid-only as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns indexed payload/workspace state; reset behavior is local.
 * Submodules: none (leaf).
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */

module keccak_round
    (
        input wire [1599 : 0] state_in,
        input wire [4 : 0] round_index,
        output reg [1599 : 0] state_out);
    reg [63 : 0] a[0 : 24];
    reg [63 : 0] t[0 : 24];
    reg [63 : 0] b[0 : 24];
    reg [63 : 0] c[0 : 4];
    reg [63 : 0] d[0 : 4];
    integer i;
    integer x;
    integer y;

    function automatic[63 : 0] rotl64;
        input [63 : 0] value;
        input integer amount;
        begin
            if (amount == 0)
                rotl64 = value;
            else
                rotl64 = (value << amount) | (value >> (64 - amount));
        end
    endfunction

    function automatic integer rho_offset;
        input integer lane;
        begin
            case (lane)
                0:
                    rho_offset = 0;
                1:
                    rho_offset = 1;
                2:
                    rho_offset = 62;
                3:
                    rho_offset = 28;
                4:
                    rho_offset = 27;
                5:
                    rho_offset = 36;
                6:
                    rho_offset = 44;
                7:
                    rho_offset = 6;
                8:
                    rho_offset = 55;
                9:
                    rho_offset = 20;
                10:
                    rho_offset = 3;
                11:
                    rho_offset = 10;
                12:
                    rho_offset = 43;
                13:
                    rho_offset = 25;
                14:
                    rho_offset = 39;
                15:
                    rho_offset = 41;
                16:
                    rho_offset = 45;
                17:
                    rho_offset = 15;
                18:
                    rho_offset = 21;
                19:
                    rho_offset = 8;
                20:
                    rho_offset = 18;
                21:
                    rho_offset = 2;
                22:
                    rho_offset = 61;
                23:
                    rho_offset = 56;
                24:
                    rho_offset = 14;
                default:
                    rho_offset = 0;
            endcase
        end
    endfunction

    function automatic integer pi_destination;
        input integer lane;
        begin
            case (lane)
                0:
                    pi_destination = 0;
                1:
                    pi_destination = 10;
                2:
                    pi_destination = 20;
                3:
                    pi_destination = 5;
                4:
                    pi_destination = 15;
                5:
                    pi_destination = 16;
                6:
                    pi_destination = 1;
                7:
                    pi_destination = 11;
                8:
                    pi_destination = 21;
                9:
                    pi_destination = 6;
                10:
                    pi_destination = 7;
                11:
                    pi_destination = 17;
                12:
                    pi_destination = 2;
                13:
                    pi_destination = 12;
                14:
                    pi_destination = 22;
                15:
                    pi_destination = 23;
                16:
                    pi_destination = 8;
                17:
                    pi_destination = 18;
                18:
                    pi_destination = 3;
                19:
                    pi_destination = 13;
                20:
                    pi_destination = 14;
                21:
                    pi_destination = 24;
                22:
                    pi_destination = 9;
                23:
                    pi_destination = 19;
                24:
                    pi_destination = 4;
                default:
                    pi_destination = 0;
            endcase
        end
    endfunction

    function automatic[63 : 0] round_constant;
        input [4 : 0] index;
        begin
            case (index)
                0:
                    round_constant = 64'h0000000000000001;
                1:
                    round_constant = 64'h0000000000008082;
                2:
                    round_constant = 64'h800000000000808a;
                3:
                    round_constant = 64'h8000000080008000;
                4:
                    round_constant = 64'h000000000000808b;
                5:
                    round_constant = 64'h0000000080000001;
                6:
                    round_constant = 64'h8000000080008081;
                7:
                    round_constant = 64'h8000000000008009;
                8:
                    round_constant = 64'h000000000000008a;
                9:
                    round_constant = 64'h0000000000000088;
                10:
                    round_constant = 64'h0000000080008009;
                11:
                    round_constant = 64'h000000008000000a;
                12:
                    round_constant = 64'h000000008000808b;
                13:
                    round_constant = 64'h800000000000008b;
                14:
                    round_constant = 64'h8000000000008089;
                15:
                    round_constant = 64'h8000000000008003;
                16:
                    round_constant = 64'h8000000000008002;
                17:
                    round_constant = 64'h8000000000000080;
                18:
                    round_constant = 64'h000000000000800a;
                19:
                    round_constant = 64'h800000008000000a;
                20:
                    round_constant = 64'h8000000080008081;
                21:
                    round_constant = 64'h8000000000008080;
                22:
                    round_constant = 64'h0000000080000001;
                23:
                    round_constant = 64'h8000000080008008;
                default:
                    round_constant = 64'h0;
            endcase
        end
    endfunction

    always @* begin
        for (i = 0; i < 25; i = i + 1)
            a[i] = state_in[64 * i +: 64];

        for (x = 0; x < 5; x = x + 1)
            c[x] = a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20];
        d[0] = c[4] ^ rotl64(c[1], 1);
        d[1] = c[0] ^ rotl64(c[2], 1);
        d[2] = c[1] ^ rotl64(c[3], 1);
        d[3] = c[2] ^ rotl64(c[4], 1);
        d[4] = c[3] ^ rotl64(c[0], 1);
        for (y = 0; y < 5; y = y + 1)
            for (x = 0; x < 5; x = x + 1)
                t[x + 5 * y] = a[x + 5 * y] ^ d[x];

        for (i = 0; i < 25; i = i + 1)
            b[pi_destination(i)] = rotl64(t[i], rho_offset(i));

        for (y = 0; y < 5; y = y + 1)
            for (x = 0; x < 5; x = x + 1)
                a[x + 5 * y] = b[x + 5 * y] ^
                               ((~b[((x == 4) ? 0 : (x + 1)) + 5 * y]) &
                                b[((x >= 3) ? (x - 3) : (x + 2)) + 5 * y]);
        a[0] = a[0] ^ round_constant(round_index);

        state_out = 1600'h0;
        for (i = 0; i < 25; i = i + 1)
            state_out[64 * i +: 64] = a[i];
    end
endmodule
