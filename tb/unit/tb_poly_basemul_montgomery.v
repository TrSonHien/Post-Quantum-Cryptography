`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_poly_basemul_montgomery;

    localparam integer CLK_PERIOD = 10;
    localparam integer NUM_PATTERNS = 3;
    localparam integer DONE_TIMEOUT = 300;

    reg clk;
    reg rst_n;
    reg start;

    reg                         a_load_en;
    reg  [`KYBER_N_WIDTH-1:0]   a_load_addr;
    reg  [`KYBER_Q_WIDTH-1:0]   a_load_data;
    reg                         b_load_en;
    reg  [`KYBER_N_WIDTH-1:0]   b_load_addr;
    reg  [`KYBER_Q_WIDTH-1:0]   b_load_data;
    reg  [`KYBER_N_WIDTH-1:0]   r_read_addr;
    wire [`KYBER_Q_WIDTH-1:0]   r_read_data;

    wire busy;
    wire done;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;
    integer pattern;
    integer i;
    integer wait_cycles;

    reg [`KYBER_Q_WIDTH-1:0] a_poly   [0:`KYBER_N-1];
    reg [`KYBER_Q_WIDTH-1:0] b_poly   [0:`KYBER_N-1];
    reg [`KYBER_Q_WIDTH-1:0] expected [0:`KYBER_N-1];

    poly_basemul_montgomery dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .busy        (busy),
        .done        (done),
        .a_load_en   (a_load_en),
        .a_load_addr (a_load_addr),
        .a_load_data (a_load_data),
        .b_load_en   (b_load_en),
        .b_load_addr (b_load_addr),
        .b_load_data (b_load_data),
        .r_read_addr (r_read_addr),
        .r_read_data (r_read_data)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/waves/poly_basemul_montgomery.vcd");
        $dumpvars(0, tb_poly_basemul_montgomery);
    end

    function signed [15:0] expected_montgomery_reduce;
        input signed [31:0] x;
        reg signed [31:0] qinv;
        reg signed [15:0] u;
        reg signed [31:0] t;
        begin
            qinv = -3327;
            u = x * qinv;
            t = x - (u * `KYBER_Q);
            expected_montgomery_reduce = t >>> 16;
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] expected_mod_mul;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        reg signed [31:0] product;
        reg signed [15:0] mont_result;
        reg signed [16:0] mont_ext;
        begin
            product = x * y;
            mont_result = expected_montgomery_reduce(product);
            mont_ext = {mont_result[15], mont_result};
            if (mont_ext < 0)
                expected_mod_mul = mont_ext + `KYBER_Q;
            else
                expected_mod_mul = mont_ext[`KYBER_Q_WIDTH-1:0];
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] expected_mod_add;
        input [`KYBER_Q_WIDTH-1:0] x;
        input [`KYBER_Q_WIDTH-1:0] y;
        reg [`KYBER_SUM_WIDTH-1:0] sum;
        begin
            sum = x + y;
            if (sum >= `KYBER_Q)
                expected_mod_add = sum - `KYBER_Q;
            else
                expected_mod_add = sum[`KYBER_Q_WIDTH-1:0];
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] zeta_forward;
        input [6:0] addr;
        begin
            case (addr)
                7'd64:  zeta_forward = 12'd2226;
                7'd65:  zeta_forward = 12'd430;
                7'd66:  zeta_forward = 12'd555;
                7'd67:  zeta_forward = 12'd843;
                7'd68:  zeta_forward = 12'd2078;
                7'd69:  zeta_forward = 12'd871;
                7'd70:  zeta_forward = 12'd1550;
                7'd71:  zeta_forward = 12'd105;
                7'd72:  zeta_forward = 12'd422;
                7'd73:  zeta_forward = 12'd587;
                7'd74:  zeta_forward = 12'd177;
                7'd75:  zeta_forward = 12'd3094;
                7'd76:  zeta_forward = 12'd3038;
                7'd77:  zeta_forward = 12'd2869;
                7'd78:  zeta_forward = 12'd1574;
                7'd79:  zeta_forward = 12'd1653;
                7'd80:  zeta_forward = 12'd3083;
                7'd81:  zeta_forward = 12'd778;
                7'd82:  zeta_forward = 12'd1159;
                7'd83:  zeta_forward = 12'd3182;
                7'd84:  zeta_forward = 12'd2552;
                7'd85:  zeta_forward = 12'd1483;
                7'd86:  zeta_forward = 12'd2727;
                7'd87:  zeta_forward = 12'd1119;
                7'd88:  zeta_forward = 12'd1739;
                7'd89:  zeta_forward = 12'd644;
                7'd90:  zeta_forward = 12'd2457;
                7'd91:  zeta_forward = 12'd349;
                7'd92:  zeta_forward = 12'd418;
                7'd93:  zeta_forward = 12'd329;
                7'd94:  zeta_forward = 12'd3173;
                7'd95:  zeta_forward = 12'd3254;
                7'd96:  zeta_forward = 12'd817;
                7'd97:  zeta_forward = 12'd1097;
                7'd98:  zeta_forward = 12'd603;
                7'd99:  zeta_forward = 12'd610;
                7'd100: zeta_forward = 12'd1322;
                7'd101: zeta_forward = 12'd2044;
                7'd102: zeta_forward = 12'd1864;
                7'd103: zeta_forward = 12'd384;
                7'd104: zeta_forward = 12'd2114;
                7'd105: zeta_forward = 12'd3193;
                7'd106: zeta_forward = 12'd1218;
                7'd107: zeta_forward = 12'd1994;
                7'd108: zeta_forward = 12'd2455;
                7'd109: zeta_forward = 12'd220;
                7'd110: zeta_forward = 12'd2142;
                7'd111: zeta_forward = 12'd1670;
                7'd112: zeta_forward = 12'd2144;
                7'd113: zeta_forward = 12'd1799;
                7'd114: zeta_forward = 12'd2051;
                7'd115: zeta_forward = 12'd794;
                7'd116: zeta_forward = 12'd1819;
                7'd117: zeta_forward = 12'd2475;
                7'd118: zeta_forward = 12'd2459;
                7'd119: zeta_forward = 12'd478;
                7'd120: zeta_forward = 12'd3221;
                7'd121: zeta_forward = 12'd3021;
                7'd122: zeta_forward = 12'd996;
                7'd123: zeta_forward = 12'd991;
                7'd124: zeta_forward = 12'd958;
                7'd125: zeta_forward = 12'd1869;
                7'd126: zeta_forward = 12'd1522;
                7'd127: zeta_forward = 12'd1628;
                default: zeta_forward = 12'd0;
            endcase
        end
    endfunction

    function [`KYBER_Q_WIDTH-1:0] negate_zeta;
        input [`KYBER_Q_WIDTH-1:0] zeta;
        begin
            if (zeta == 0)
                negate_zeta = 0;
            else
                negate_zeta = `KYBER_Q - zeta;
        end
    endfunction

    task expected_basemul_pair;
        input integer base;
        input [`KYBER_Q_WIDTH-1:0] zeta;
        reg [`KYBER_Q_WIDTH-1:0] t0;
        reg [`KYBER_Q_WIDTH-1:0] t1;
        reg [`KYBER_Q_WIDTH-1:0] t2;
        reg [`KYBER_Q_WIDTH-1:0] t3;
        reg [`KYBER_Q_WIDTH-1:0] t4;
        begin
            t0 = expected_mod_mul(a_poly[base + 1], b_poly[base + 1]);
            t1 = expected_mod_mul(t0, zeta);
            t2 = expected_mod_mul(a_poly[base + 0], b_poly[base + 0]);
            expected[base + 0] = expected_mod_add(t1, t2);

            t3 = expected_mod_mul(a_poly[base + 0], b_poly[base + 1]);
            t4 = expected_mod_mul(a_poly[base + 1], b_poly[base + 0]);
            expected[base + 1] = expected_mod_add(t3, t4);
        end
    endtask

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_poly_basemul_montgomery: %0s", message);
            end
            $display("ERROR tb_poly_basemul_montgomery: %0s", message);
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            a_load_en = 1'b0;
            b_load_en = 1'b0;
            a_load_addr = {`KYBER_N_WIDTH{1'b0}};
            b_load_addr = {`KYBER_N_WIDTH{1'b0}};
            a_load_data = {`KYBER_Q_WIDTH{1'b0}};
            b_load_data = {`KYBER_Q_WIDTH{1'b0}};
            r_read_addr = {`KYBER_N_WIDTH{1'b0}};
            repeat (5) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
            #1;

            if (busy !== 1'b0)
                record_fail("busy must be low after reset");
            if (done !== 1'b0)
                record_fail("done must be low after reset");
        end
    endtask

    task build_pattern;
        input integer pattern_id;
        integer j;
        integer group;
        reg [`KYBER_Q_WIDTH-1:0] zeta;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                case (pattern_id)
                    0: begin
                        a_poly[j] = j % `KYBER_Q;
                        b_poly[j] = ((3 * j) + 5) % `KYBER_Q;
                    end
                    1: begin
                        a_poly[j] = (`KYBER_Q - 1 - j) % `KYBER_Q;
                        b_poly[j] = ((17 * j) + 29) % `KYBER_Q;
                    end
                    default: begin
                        a_poly[j] = ((j * j) + (11 * j) + 7) % `KYBER_Q;
                        b_poly[j] = ((13 * j * j) + (3 * j) + 19) % `KYBER_Q;
                    end
                endcase
                expected[j] = {`KYBER_Q_WIDTH{1'b0}};
            end

            for (group = 0; group < (`KYBER_N/4); group = group + 1) begin
                zeta = zeta_forward(7'd64 + group[6:0]);
                expected_basemul_pair(4 * group, zeta);
                expected_basemul_pair((4 * group) + 2, negate_zeta(zeta));
            end
        end
    endtask

    task load_polynomials;
        integer j;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                @(negedge clk);
                a_load_en = 1'b1;
                a_load_addr = j[`KYBER_N_WIDTH-1:0];
                a_load_data = a_poly[j];
                b_load_en = 1'b1;
                b_load_addr = j[`KYBER_N_WIDTH-1:0];
                b_load_data = b_poly[j];
            end

            @(negedge clk);
            a_load_en = 1'b0;
            b_load_en = 1'b0;
            a_load_addr = {`KYBER_N_WIDTH{1'b0}};
            b_load_addr = {`KYBER_N_WIDTH{1'b0}};
            a_load_data = {`KYBER_Q_WIDTH{1'b0}};
            b_load_data = {`KYBER_Q_WIDTH{1'b0}};
            repeat (2) @(negedge clk);
        end
    endtask

    task run_dut;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait_cycles = 0;
            while ((done !== 1'b1) && (wait_cycles < DONE_TIMEOUT)) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (done !== 1'b1)
                record_fail("timed out waiting for done");

            @(negedge clk);
            #1;
            if (done !== 1'b0)
                record_fail("done must be a one-cycle pulse");
            if (busy !== 1'b0)
                record_fail("busy must be low after done");
        end
    endtask

    task check_result;
        input integer pattern_id;
        integer j;
        begin
            for (j = 0; j < `KYBER_N; j = j + 1) begin
                r_read_addr = j[`KYBER_N_WIDTH-1:0];
                #1;
                if (r_read_data !== expected[j]) begin
                    fail_count = fail_count + 1;
                    if (!first_fail_seen) begin
                        first_fail_seen = 1;
                        $display("FIRST_FAIL tb_poly_basemul_montgomery: pattern=%0d index=%0d expected=%0d actual=%0d",
                                 pattern_id, j, expected[j], r_read_data);
                    end
                    $display("ERROR tb_poly_basemul_montgomery: pattern=%0d index=%0d expected=%0d actual=%0d",
                             pattern_id, j, expected[j], r_read_data);
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;

        apply_reset();

        for (pattern = 0; pattern < NUM_PATTERNS; pattern = pattern + 1) begin
            $display("INFO tb_poly_basemul_montgomery: running pattern=%0d", pattern);
            build_pattern(pattern);
            load_polynomials();
            run_dut();
            check_result(pattern);
            repeat (4) @(negedge clk);
        end

        $display("INFO tb_poly_basemul_montgomery: pass_count=%0d fail_count=%0d",
                 pass_count, fail_count);

        if ((fail_count == 0) && (pass_count == (`KYBER_N * NUM_PATTERNS))) begin
            $display("PASS tb_poly_basemul_montgomery");
        end else begin
            $display("FAIL tb_poly_basemul_montgomery");
            $fatal(1, "tb_poly_basemul_montgomery detected mismatches");
        end

        $finish;
    end

endmodule
