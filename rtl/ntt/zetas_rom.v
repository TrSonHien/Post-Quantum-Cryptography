`timescale 1ns/1ps
`include "kyber_params.vh"

// -----------------------------------------------------------------------------
// Module: zetas_rom
// Description:
//   ROM for Kyber NTT twiddle factors.
//
// Reference:
//   kyber768/ntt.c
//
// Arrays:
//   zetas[128]     : forward NTT twiddle factors
//   zetas_inv[128] : inverse NTT twiddle factors
//
// Notes:
//   - Forward NTT in ntt.c starts with k = 1, so zetas[0] is not used by ntt().
//   - Inverse NTT uses zetas_inv[0..126] in the loop and zetas_inv[127]
//     for final scaling.
//   - The constants are copied from kyber768/ntt.c. They are all positive
//     canonical representatives less than q, so KYBER_Q_WIDTH bits are enough.
//   - This is a combinational lookup table. A later memory-mapped or registered
//     ROM can preserve the same addr/inverse/zeta interface.
// -----------------------------------------------------------------------------

module zetas_rom (
    input  wire                      inverse,  // 0: zetas[], 1: zetas_inv[]
    input  wire [6:0]                addr,
    output reg  [`KYBER_Q_WIDTH-1:0] zeta
);

    always @(*) begin
        if (!inverse) begin
            case (addr)
                7'd0:   zeta = 12'd2285;
                7'd1:   zeta = 12'd2571;
                7'd2:   zeta = 12'd2970;
                7'd3:   zeta = 12'd1812;
                7'd4:   zeta = 12'd1493;
                7'd5:   zeta = 12'd1422;
                7'd6:   zeta = 12'd287;
                7'd7:   zeta = 12'd202;
                7'd8:   zeta = 12'd3158;
                7'd9:   zeta = 12'd622;
                7'd10:  zeta = 12'd1577;
                7'd11:  zeta = 12'd182;
                7'd12:  zeta = 12'd962;
                7'd13:  zeta = 12'd2127;
                7'd14:  zeta = 12'd1855;
                7'd15:  zeta = 12'd1468;
                7'd16:  zeta = 12'd573;
                7'd17:  zeta = 12'd2004;
                7'd18:  zeta = 12'd264;
                7'd19:  zeta = 12'd383;
                7'd20:  zeta = 12'd2500;
                7'd21:  zeta = 12'd1458;
                7'd22:  zeta = 12'd1727;
                7'd23:  zeta = 12'd3199;
                7'd24:  zeta = 12'd2648;
                7'd25:  zeta = 12'd1017;
                7'd26:  zeta = 12'd732;
                7'd27:  zeta = 12'd608;
                7'd28:  zeta = 12'd1787;
                7'd29:  zeta = 12'd411;
                7'd30:  zeta = 12'd3124;
                7'd31:  zeta = 12'd1758;
                7'd32:  zeta = 12'd1223;
                7'd33:  zeta = 12'd652;
                7'd34:  zeta = 12'd2777;
                7'd35:  zeta = 12'd1015;
                7'd36:  zeta = 12'd2036;
                7'd37:  zeta = 12'd1491;
                7'd38:  zeta = 12'd3047;
                7'd39:  zeta = 12'd1785;
                7'd40:  zeta = 12'd516;
                7'd41:  zeta = 12'd3321;
                7'd42:  zeta = 12'd3009;
                7'd43:  zeta = 12'd2663;
                7'd44:  zeta = 12'd1711;
                7'd45:  zeta = 12'd2167;
                7'd46:  zeta = 12'd126;
                7'd47:  zeta = 12'd1469;
                7'd48:  zeta = 12'd2476;
                7'd49:  zeta = 12'd3239;
                7'd50:  zeta = 12'd3058;
                7'd51:  zeta = 12'd830;
                7'd52:  zeta = 12'd107;
                7'd53:  zeta = 12'd1908;
                7'd54:  zeta = 12'd3082;
                7'd55:  zeta = 12'd2378;
                7'd56:  zeta = 12'd2931;
                7'd57:  zeta = 12'd961;
                7'd58:  zeta = 12'd1821;
                7'd59:  zeta = 12'd2604;
                7'd60:  zeta = 12'd448;
                7'd61:  zeta = 12'd2264;
                7'd62:  zeta = 12'd677;
                7'd63:  zeta = 12'd2054;
                7'd64:  zeta = 12'd2226;
                7'd65:  zeta = 12'd430;
                7'd66:  zeta = 12'd555;
                7'd67:  zeta = 12'd843;
                7'd68:  zeta = 12'd2078;
                7'd69:  zeta = 12'd871;
                7'd70:  zeta = 12'd1550;
                7'd71:  zeta = 12'd105;
                7'd72:  zeta = 12'd422;
                7'd73:  zeta = 12'd587;
                7'd74:  zeta = 12'd177;
                7'd75:  zeta = 12'd3094;
                7'd76:  zeta = 12'd3038;
                7'd77:  zeta = 12'd2869;
                7'd78:  zeta = 12'd1574;
                7'd79:  zeta = 12'd1653;
                7'd80:  zeta = 12'd3083;
                7'd81:  zeta = 12'd778;
                7'd82:  zeta = 12'd1159;
                7'd83:  zeta = 12'd3182;
                7'd84:  zeta = 12'd2552;
                7'd85:  zeta = 12'd1483;
                7'd86:  zeta = 12'd2727;
                7'd87:  zeta = 12'd1119;
                7'd88:  zeta = 12'd1739;
                7'd89:  zeta = 12'd644;
                7'd90:  zeta = 12'd2457;
                7'd91:  zeta = 12'd349;
                7'd92:  zeta = 12'd418;
                7'd93:  zeta = 12'd329;
                7'd94:  zeta = 12'd3173;
                7'd95:  zeta = 12'd3254;
                7'd96:  zeta = 12'd817;
                7'd97:  zeta = 12'd1097;
                7'd98:  zeta = 12'd603;
                7'd99:  zeta = 12'd610;
                7'd100: zeta = 12'd1322;
                7'd101: zeta = 12'd2044;
                7'd102: zeta = 12'd1864;
                7'd103: zeta = 12'd384;
                7'd104: zeta = 12'd2114;
                7'd105: zeta = 12'd3193;
                7'd106: zeta = 12'd1218;
                7'd107: zeta = 12'd1994;
                7'd108: zeta = 12'd2455;
                7'd109: zeta = 12'd220;
                7'd110: zeta = 12'd2142;
                7'd111: zeta = 12'd1670;
                7'd112: zeta = 12'd2144;
                7'd113: zeta = 12'd1799;
                7'd114: zeta = 12'd2051;
                7'd115: zeta = 12'd794;
                7'd116: zeta = 12'd1819;
                7'd117: zeta = 12'd2475;
                7'd118: zeta = 12'd2459;
                7'd119: zeta = 12'd478;
                7'd120: zeta = 12'd3221;
                7'd121: zeta = 12'd3021;
                7'd122: zeta = 12'd996;
                7'd123: zeta = 12'd991;
                7'd124: zeta = 12'd958;
                7'd125: zeta = 12'd1869;
                7'd126: zeta = 12'd1522;
                7'd127: zeta = 12'd1628;
                default: zeta = 12'd0;
            endcase
        end else begin
            case (addr)
                7'd0:   zeta = 12'd1701;
                7'd1:   zeta = 12'd1807;
                7'd2:   zeta = 12'd1460;
                7'd3:   zeta = 12'd2371;
                7'd4:   zeta = 12'd2338;
                7'd5:   zeta = 12'd2333;
                7'd6:   zeta = 12'd308;
                7'd7:   zeta = 12'd108;
                7'd8:   zeta = 12'd2851;
                7'd9:   zeta = 12'd870;
                7'd10:  zeta = 12'd854;
                7'd11:  zeta = 12'd1510;
                7'd12:  zeta = 12'd2535;
                7'd13:  zeta = 12'd1278;
                7'd14:  zeta = 12'd1530;
                7'd15:  zeta = 12'd1185;
                7'd16:  zeta = 12'd1659;
                7'd17:  zeta = 12'd1187;
                7'd18:  zeta = 12'd3109;
                7'd19:  zeta = 12'd874;
                7'd20:  zeta = 12'd1335;
                7'd21:  zeta = 12'd2111;
                7'd22:  zeta = 12'd136;
                7'd23:  zeta = 12'd1215;
                7'd24:  zeta = 12'd2945;
                7'd25:  zeta = 12'd1465;
                7'd26:  zeta = 12'd1285;
                7'd27:  zeta = 12'd2007;
                7'd28:  zeta = 12'd2719;
                7'd29:  zeta = 12'd2726;
                7'd30:  zeta = 12'd2232;
                7'd31:  zeta = 12'd2512;
                7'd32:  zeta = 12'd75;
                7'd33:  zeta = 12'd156;
                7'd34:  zeta = 12'd3000;
                7'd35:  zeta = 12'd2911;
                7'd36:  zeta = 12'd2980;
                7'd37:  zeta = 12'd872;
                7'd38:  zeta = 12'd2685;
                7'd39:  zeta = 12'd1590;
                7'd40:  zeta = 12'd2210;
                7'd41:  zeta = 12'd602;
                7'd42:  zeta = 12'd1846;
                7'd43:  zeta = 12'd777;
                7'd44:  zeta = 12'd147;
                7'd45:  zeta = 12'd2170;
                7'd46:  zeta = 12'd2551;
                7'd47:  zeta = 12'd246;
                7'd48:  zeta = 12'd1676;
                7'd49:  zeta = 12'd1755;
                7'd50:  zeta = 12'd460;
                7'd51:  zeta = 12'd291;
                7'd52:  zeta = 12'd235;
                7'd53:  zeta = 12'd3152;
                7'd54:  zeta = 12'd2742;
                7'd55:  zeta = 12'd2907;
                7'd56:  zeta = 12'd3224;
                7'd57:  zeta = 12'd1779;
                7'd58:  zeta = 12'd2458;
                7'd59:  zeta = 12'd1251;
                7'd60:  zeta = 12'd2486;
                7'd61:  zeta = 12'd2774;
                7'd62:  zeta = 12'd2899;
                7'd63:  zeta = 12'd1103;
                7'd64:  zeta = 12'd1275;
                7'd65:  zeta = 12'd2652;
                7'd66:  zeta = 12'd1065;
                7'd67:  zeta = 12'd2881;
                7'd68:  zeta = 12'd725;
                7'd69:  zeta = 12'd1508;
                7'd70:  zeta = 12'd2368;
                7'd71:  zeta = 12'd398;
                7'd72:  zeta = 12'd951;
                7'd73:  zeta = 12'd247;
                7'd74:  zeta = 12'd1421;
                7'd75:  zeta = 12'd3222;
                7'd76:  zeta = 12'd2499;
                7'd77:  zeta = 12'd271;
                7'd78:  zeta = 12'd90;
                7'd79:  zeta = 12'd853;
                7'd80:  zeta = 12'd1860;
                7'd81:  zeta = 12'd3203;
                7'd82:  zeta = 12'd1162;
                7'd83:  zeta = 12'd1618;
                7'd84:  zeta = 12'd666;
                7'd85:  zeta = 12'd320;
                7'd86:  zeta = 12'd8;
                7'd87:  zeta = 12'd2813;
                7'd88:  zeta = 12'd1544;
                7'd89:  zeta = 12'd282;
                7'd90:  zeta = 12'd1838;
                7'd91:  zeta = 12'd1293;
                7'd92:  zeta = 12'd2314;
                7'd93:  zeta = 12'd552;
                7'd94:  zeta = 12'd2677;
                7'd95:  zeta = 12'd2106;
                7'd96:  zeta = 12'd1571;
                7'd97:  zeta = 12'd205;
                7'd98:  zeta = 12'd2918;
                7'd99:  zeta = 12'd1542;
                7'd100: zeta = 12'd2721;
                7'd101: zeta = 12'd2597;
                7'd102: zeta = 12'd2312;
                7'd103: zeta = 12'd681;
                7'd104: zeta = 12'd130;
                7'd105: zeta = 12'd1602;
                7'd106: zeta = 12'd1871;
                7'd107: zeta = 12'd829;
                7'd108: zeta = 12'd2946;
                7'd109: zeta = 12'd3065;
                7'd110: zeta = 12'd1325;
                7'd111: zeta = 12'd2756;
                7'd112: zeta = 12'd1861;
                7'd113: zeta = 12'd1474;
                7'd114: zeta = 12'd1202;
                7'd115: zeta = 12'd2367;
                7'd116: zeta = 12'd3147;
                7'd117: zeta = 12'd1752;
                7'd118: zeta = 12'd2707;
                7'd119: zeta = 12'd171;
                7'd120: zeta = 12'd3127;
                7'd121: zeta = 12'd3042;
                7'd122: zeta = 12'd1907;
                7'd123: zeta = 12'd1836;
                7'd124: zeta = 12'd1517;
                7'd125: zeta = 12'd359;
                7'd126: zeta = 12'd758;
                7'd127: zeta = 12'd1441;
                default: zeta = 12'd0;
            endcase
        end
    end

endmodule
