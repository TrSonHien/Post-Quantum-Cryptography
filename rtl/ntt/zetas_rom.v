`timescale 1ns/1ps

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
// -----------------------------------------------------------------------------

module zetas_rom (
    input  wire        inverse,  // 0: zetas[], 1: zetas_inv[]
    input  wire [6:0]  addr,
    output reg  [15:0] zeta
);

    always @(*) begin
        if (!inverse) begin
            case (addr)
                7'd0:   zeta = 16'sd2285;
                7'd1:   zeta = 16'sd2571;
                7'd2:   zeta = 16'sd2970;
                7'd3:   zeta = 16'sd1812;
                7'd4:   zeta = 16'sd1493;
                7'd5:   zeta = 16'sd1422;
                7'd6:   zeta = 16'sd287;
                7'd7:   zeta = 16'sd202;
                7'd8:   zeta = 16'sd3158;
                7'd9:   zeta = 16'sd622;
                7'd10:  zeta = 16'sd1577;
                7'd11:  zeta = 16'sd182;
                7'd12:  zeta = 16'sd962;
                7'd13:  zeta = 16'sd2127;
                7'd14:  zeta = 16'sd1855;
                7'd15:  zeta = 16'sd1468;
                7'd16:  zeta = 16'sd573;
                7'd17:  zeta = 16'sd2004;
                7'd18:  zeta = 16'sd264;
                7'd19:  zeta = 16'sd383;
                7'd20:  zeta = 16'sd2500;
                7'd21:  zeta = 16'sd1458;
                7'd22:  zeta = 16'sd1727;
                7'd23:  zeta = 16'sd3199;
                7'd24:  zeta = 16'sd2648;
                7'd25:  zeta = 16'sd1017;
                7'd26:  zeta = 16'sd732;
                7'd27:  zeta = 16'sd608;
                7'd28:  zeta = 16'sd1787;
                7'd29:  zeta = 16'sd411;
                7'd30:  zeta = 16'sd3124;
                7'd31:  zeta = 16'sd1758;
                7'd32:  zeta = 16'sd1223;
                7'd33:  zeta = 16'sd652;
                7'd34:  zeta = 16'sd2777;
                7'd35:  zeta = 16'sd1015;
                7'd36:  zeta = 16'sd2036;
                7'd37:  zeta = 16'sd1491;
                7'd38:  zeta = 16'sd3047;
                7'd39:  zeta = 16'sd1785;
                7'd40:  zeta = 16'sd516;
                7'd41:  zeta = 16'sd3321;
                7'd42:  zeta = 16'sd3009;
                7'd43:  zeta = 16'sd2663;
                7'd44:  zeta = 16'sd1711;
                7'd45:  zeta = 16'sd2167;
                7'd46:  zeta = 16'sd126;
                7'd47:  zeta = 16'sd1469;
                7'd48:  zeta = 16'sd2476;
                7'd49:  zeta = 16'sd3239;
                7'd50:  zeta = 16'sd3058;
                7'd51:  zeta = 16'sd830;
                7'd52:  zeta = 16'sd107;
                7'd53:  zeta = 16'sd1908;
                7'd54:  zeta = 16'sd3082;
                7'd55:  zeta = 16'sd2378;
                7'd56:  zeta = 16'sd2931;
                7'd57:  zeta = 16'sd961;
                7'd58:  zeta = 16'sd1821;
                7'd59:  zeta = 16'sd2604;
                7'd60:  zeta = 16'sd448;
                7'd61:  zeta = 16'sd2264;
                7'd62:  zeta = 16'sd677;
                7'd63:  zeta = 16'sd2054;
                7'd64:  zeta = 16'sd2226;
                7'd65:  zeta = 16'sd430;
                7'd66:  zeta = 16'sd555;
                7'd67:  zeta = 16'sd843;
                7'd68:  zeta = 16'sd2078;
                7'd69:  zeta = 16'sd871;
                7'd70:  zeta = 16'sd1550;
                7'd71:  zeta = 16'sd105;
                7'd72:  zeta = 16'sd422;
                7'd73:  zeta = 16'sd587;
                7'd74:  zeta = 16'sd177;
                7'd75:  zeta = 16'sd3094;
                7'd76:  zeta = 16'sd3038;
                7'd77:  zeta = 16'sd2869;
                7'd78:  zeta = 16'sd1574;
                7'd79:  zeta = 16'sd1653;
                7'd80:  zeta = 16'sd3083;
                7'd81:  zeta = 16'sd778;
                7'd82:  zeta = 16'sd1159;
                7'd83:  zeta = 16'sd3182;
                7'd84:  zeta = 16'sd2552;
                7'd85:  zeta = 16'sd1483;
                7'd86:  zeta = 16'sd2727;
                7'd87:  zeta = 16'sd1119;
                7'd88:  zeta = 16'sd1739;
                7'd89:  zeta = 16'sd644;
                7'd90:  zeta = 16'sd2457;
                7'd91:  zeta = 16'sd349;
                7'd92:  zeta = 16'sd418;
                7'd93:  zeta = 16'sd329;
                7'd94:  zeta = 16'sd3173;
                7'd95:  zeta = 16'sd3254;
                7'd96:  zeta = 16'sd817;
                7'd97:  zeta = 16'sd1097;
                7'd98:  zeta = 16'sd603;
                7'd99:  zeta = 16'sd610;
                7'd100: zeta = 16'sd1322;
                7'd101: zeta = 16'sd2044;
                7'd102: zeta = 16'sd1864;
                7'd103: zeta = 16'sd384;
                7'd104: zeta = 16'sd2114;
                7'd105: zeta = 16'sd3193;
                7'd106: zeta = 16'sd1218;
                7'd107: zeta = 16'sd1994;
                7'd108: zeta = 16'sd2455;
                7'd109: zeta = 16'sd220;
                7'd110: zeta = 16'sd2142;
                7'd111: zeta = 16'sd1670;
                7'd112: zeta = 16'sd2144;
                7'd113: zeta = 16'sd1799;
                7'd114: zeta = 16'sd2051;
                7'd115: zeta = 16'sd794;
                7'd116: zeta = 16'sd1819;
                7'd117: zeta = 16'sd2475;
                7'd118: zeta = 16'sd2459;
                7'd119: zeta = 16'sd478;
                7'd120: zeta = 16'sd3221;
                7'd121: zeta = 16'sd3021;
                7'd122: zeta = 16'sd996;
                7'd123: zeta = 16'sd991;
                7'd124: zeta = 16'sd958;
                7'd125: zeta = 16'sd1869;
                7'd126: zeta = 16'sd1522;
                7'd127: zeta = 16'sd1628;
                default: zeta = 16'sd0;
            endcase
        end else begin
            case (addr)
                7'd0:   zeta = 16'sd1701;
                7'd1:   zeta = 16'sd1807;
                7'd2:   zeta = 16'sd1460;
                7'd3:   zeta = 16'sd2371;
                7'd4:   zeta = 16'sd2338;
                7'd5:   zeta = 16'sd2333;
                7'd6:   zeta = 16'sd308;
                7'd7:   zeta = 16'sd108;
                7'd8:   zeta = 16'sd2851;
                7'd9:   zeta = 16'sd870;
                7'd10:  zeta = 16'sd854;
                7'd11:  zeta = 16'sd1510;
                7'd12:  zeta = 16'sd2535;
                7'd13:  zeta = 16'sd1278;
                7'd14:  zeta = 16'sd1530;
                7'd15:  zeta = 16'sd1185;
                7'd16:  zeta = 16'sd1659;
                7'd17:  zeta = 16'sd1187;
                7'd18:  zeta = 16'sd3109;
                7'd19:  zeta = 16'sd874;
                7'd20:  zeta = 16'sd1335;
                7'd21:  zeta = 16'sd2111;
                7'd22:  zeta = 16'sd136;
                7'd23:  zeta = 16'sd1215;
                7'd24:  zeta = 16'sd2945;
                7'd25:  zeta = 16'sd1465;
                7'd26:  zeta = 16'sd1285;
                7'd27:  zeta = 16'sd2007;
                7'd28:  zeta = 16'sd2719;
                7'd29:  zeta = 16'sd2726;
                7'd30:  zeta = 16'sd2232;
                7'd31:  zeta = 16'sd2512;
                7'd32:  zeta = 16'sd75;
                7'd33:  zeta = 16'sd156;
                7'd34:  zeta = 16'sd3000;
                7'd35:  zeta = 16'sd2911;
                7'd36:  zeta = 16'sd2980;
                7'd37:  zeta = 16'sd872;
                7'd38:  zeta = 16'sd2685;
                7'd39:  zeta = 16'sd1590;
                7'd40:  zeta = 16'sd2210;
                7'd41:  zeta = 16'sd602;
                7'd42:  zeta = 16'sd1846;
                7'd43:  zeta = 16'sd777;
                7'd44:  zeta = 16'sd147;
                7'd45:  zeta = 16'sd2170;
                7'd46:  zeta = 16'sd2551;
                7'd47:  zeta = 16'sd246;
                7'd48:  zeta = 16'sd1676;
                7'd49:  zeta = 16'sd1755;
                7'd50:  zeta = 16'sd460;
                7'd51:  zeta = 16'sd291;
                7'd52:  zeta = 16'sd235;
                7'd53:  zeta = 16'sd3152;
                7'd54:  zeta = 16'sd2742;
                7'd55:  zeta = 16'sd2907;
                7'd56:  zeta = 16'sd3224;
                7'd57:  zeta = 16'sd1779;
                7'd58:  zeta = 16'sd2458;
                7'd59:  zeta = 16'sd1251;
                7'd60:  zeta = 16'sd2486;
                7'd61:  zeta = 16'sd2774;
                7'd62:  zeta = 16'sd2899;
                7'd63:  zeta = 16'sd1103;
                7'd64:  zeta = 16'sd1275;
                7'd65:  zeta = 16'sd2652;
                7'd66:  zeta = 16'sd1065;
                7'd67:  zeta = 16'sd2881;
                7'd68:  zeta = 16'sd725;
                7'd69:  zeta = 16'sd1508;
                7'd70:  zeta = 16'sd2368;
                7'd71:  zeta = 16'sd398;
                7'd72:  zeta = 16'sd951;
                7'd73:  zeta = 16'sd247;
                7'd74:  zeta = 16'sd1421;
                7'd75:  zeta = 16'sd3222;
                7'd76:  zeta = 16'sd2499;
                7'd77:  zeta = 16'sd271;
                7'd78:  zeta = 16'sd90;
                7'd79:  zeta = 16'sd853;
                7'd80:  zeta = 16'sd1860;
                7'd81:  zeta = 16'sd3203;
                7'd82:  zeta = 16'sd1162;
                7'd83:  zeta = 16'sd1618;
                7'd84:  zeta = 16'sd666;
                7'd85:  zeta = 16'sd320;
                7'd86:  zeta = 16'sd8;
                7'd87:  zeta = 16'sd2813;
                7'd88:  zeta = 16'sd1544;
                7'd89:  zeta = 16'sd282;
                7'd90:  zeta = 16'sd1838;
                7'd91:  zeta = 16'sd1293;
                7'd92:  zeta = 16'sd2314;
                7'd93:  zeta = 16'sd552;
                7'd94:  zeta = 16'sd2677;
                7'd95:  zeta = 16'sd2106;
                7'd96:  zeta = 16'sd1571;
                7'd97:  zeta = 16'sd205;
                7'd98:  zeta = 16'sd2918;
                7'd99:  zeta = 16'sd1542;
                7'd100: zeta = 16'sd2721;
                7'd101: zeta = 16'sd2597;
                7'd102: zeta = 16'sd2312;
                7'd103: zeta = 16'sd681;
                7'd104: zeta = 16'sd130;
                7'd105: zeta = 16'sd1602;
                7'd106: zeta = 16'sd1871;
                7'd107: zeta = 16'sd829;
                7'd108: zeta = 16'sd2946;
                7'd109: zeta = 16'sd3065;
                7'd110: zeta = 16'sd1325;
                7'd111: zeta = 16'sd2756;
                7'd112: zeta = 16'sd1861;
                7'd113: zeta = 16'sd1474;
                7'd114: zeta = 16'sd1202;
                7'd115: zeta = 16'sd2367;
                7'd116: zeta = 16'sd3147;
                7'd117: zeta = 16'sd1752;
                7'd118: zeta = 16'sd2707;
                7'd119: zeta = 16'sd171;
                7'd120: zeta = 16'sd3127;
                7'd121: zeta = 16'sd3042;
                7'd122: zeta = 16'sd1907;
                7'd123: zeta = 16'sd1836;
                7'd124: zeta = 16'sd1517;
                7'd125: zeta = 16'sd359;
                7'd126: zeta = 16'sd758;
                7'd127: zeta = 16'sd1441;
                default: zeta = 16'sd0;
            endcase
        end
    end

endmodule
