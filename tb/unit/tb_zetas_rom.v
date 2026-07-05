`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_zetas_rom;

    reg inverse;
    reg [6:0] addr;
    wire [`KYBER_Q_WIDTH-1:0] zeta;

    integer pass_count;
    integer fail_count;

    zetas_rom dut (
        .inverse(inverse),
        .addr(addr),
        .zeta(zeta)
    );

    task check_case;
        input inv;
        input [6:0] a;
        input [`KYBER_Q_WIDTH-1:0] expected;
        begin
            inverse = inv;
            addr = a;
            #1;
            if (zeta !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL zetas_rom inverse=%0d addr=%0d got=%0d expected=%0d",
                         inv, a, zeta, expected);
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("INFO tb_zetas_rom: running selected table checks");

        check_case(1'b0, 7'd0,   16'd2285);
        check_case(1'b0, 7'd1,   16'd2571);
        check_case(1'b0, 7'd2,   16'd2970);
        check_case(1'b0, 7'd63,  16'd2054);
        check_case(1'b0, 7'd64,  16'd2226);
        check_case(1'b0, 7'd100, 16'd1322);
        check_case(1'b0, 7'd126, 16'd1522);
        check_case(1'b0, 7'd127, 16'd1628);

        check_case(1'b1, 7'd0,   16'd1701);
        check_case(1'b1, 7'd1,   16'd1807);
        check_case(1'b1, 7'd2,   16'd1460);
        check_case(1'b1, 7'd63,  16'd1103);
        check_case(1'b1, 7'd64,  16'd1275);
        check_case(1'b1, 7'd100, 16'd2721);
        check_case(1'b1, 7'd126, 16'd758);
        check_case(1'b1, 7'd127, 16'd1441);

        $display("INFO tb_zetas_rom: pass_count=%0d fail_count=%0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("PASS tb_zetas_rom");
            $finish;
        end else begin
            $display("FAIL tb_zetas_rom");
            $fatal(1, "tb_zetas_rom detected mismatches");
        end
    end

endmodule
