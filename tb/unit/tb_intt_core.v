`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_intt_core;

    localparam integer N = `KYBER_N;
    localparam integer Q = `KYBER_Q;
    localparam integer DATA_WIDTH = `KYBER_Q_WIDTH;
    localparam integer ADDR_WIDTH = `KYBER_N_WIDTH;
    localparam integer TOTAL_BUTTERFLIES = 896;
    localparam integer TOTAL_SCALE = 256;

    reg clk;
    reg rst_n;
    reg start;
    wire busy;
    wire done;

    reg                   load_en;
    reg  [ADDR_WIDTH-1:0] load_addr;
    reg  [DATA_WIDTH-1:0] load_data;
    reg  [ADDR_WIDTH-1:0] read_addr;
    wire [DATA_WIDTH-1:0] read_data;

    reg  [6:0] oracle_zeta_addr;
    wire [DATA_WIDTH-1:0] oracle_zeta;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;

    integer ref_poly [0:N-1];
    integer input_poly [0:N-1];

    intt_core dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .busy      (busy),
        .done      (done),
        .load_en   (load_en),
        .load_addr (load_addr),
        .load_data (load_data),
        .read_addr (read_addr),
        .read_data (read_data)
    );

    zetas_rom oracle_zetas (
        .inverse (1'b1),
        .addr    (oracle_zeta_addr),
        .zeta    (oracle_zeta)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function integer mod_q;
        input integer x;
        integer t;
        begin
            t = x % Q;
            if (t < 0)
                t = t + Q;
            mod_q = t;
        end
    endfunction

    function integer montgomery_reduce_ref;
        input integer a;
        integer qinv;
        integer u;
        integer t;
        begin
            qinv = -3327;
            u = (a * qinv) & 16'hffff;
            if (u >= 32768)
                u = u - 65536;
            t = a - (u * Q);
            montgomery_reduce_ref = t >>> 16;
        end
    endfunction

    function integer fqmul_ref;
        input integer a;
        input integer b;
        integer r;
        begin
            r = montgomery_reduce_ref(a * b);
            fqmul_ref = mod_q(r);
        end
    endfunction

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_intt_core: %0s", message);
            end
            $display("ERROR tb_intt_core: %0s", message);
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            load_en = 1'b0;
            load_addr = {ADDR_WIDTH{1'b0}};
            load_data = {DATA_WIDTH{1'b0}};
            read_addr = {ADDR_WIDTH{1'b0}};
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task init_input_pattern;
        input integer pattern_id;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                case (pattern_id)
                    0: input_poly[i] = i % Q;
                    1: input_poly[i] = ((i * 19) + (i * i * 5) + 11) % Q;
                    2: input_poly[i] = ((i * 73) ^ (i * 9)) % Q;
                    default: input_poly[i] = 0;
                endcase
                ref_poly[i] = input_poly[i];
            end
        end
    endtask

    task load_input_poly;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk);
                load_en = 1'b1;
                load_addr = i[ADDR_WIDTH-1:0];
                load_data = input_poly[i][DATA_WIDTH-1:0];
            end
            @(negedge clk);
            load_en = 1'b0;
            load_addr = {ADDR_WIDTH{1'b0}};
            load_data = {DATA_WIDTH{1'b0}};
        end
    endtask

    task compute_reference_intt;
        integer len;
        integer start_idx;
        integer j;
        integer k;
        integer zeta;
        integer t;
        integer diff;
        begin
            k = 0;
            for (len = 2; len <= 128; len = len << 1) begin
                start_idx = 0;
                while (start_idx < 256) begin
                    oracle_zeta_addr = k[6:0];
                    #1;
                    zeta = oracle_zeta;
                    k = k + 1;

                    for (j = start_idx; j < start_idx + len; j = j + 1) begin
                        t = ref_poly[j];
                        ref_poly[j] = mod_q(t + ref_poly[j + len]);
                        diff = mod_q(t - ref_poly[j + len]);
                        ref_poly[j + len] = fqmul_ref(zeta, diff);
                    end
                    start_idx = j + len;
                end
            end

            oracle_zeta_addr = 7'd127;
            #1;
            zeta = oracle_zeta;
            for (j = 0; j < 256; j = j + 1)
                ref_poly[j] = fqmul_ref(ref_poly[j], zeta);
        end
    endtask

    task start_core;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_for_done;
        integer cycles;
        integer done_pulses;
        begin
            cycles = 0;
            done_pulses = 0;
            while (cycles < TOTAL_BUTTERFLIES + TOTAL_SCALE + 40) begin
                @(negedge clk);
                #1;
                if (done) begin
                    done_pulses = done_pulses + 1;
                    if (busy)
                        record_fail("busy must be low when done is high");
                    @(negedge clk);
                    #1;
                    if (done)
                        record_fail("done must pulse for exactly one cycle");
                    if (busy)
                        record_fail("busy must stay low after done");
                    cycles = TOTAL_BUTTERFLIES + TOTAL_SCALE + 40;
                end else begin
                    cycles = cycles + 1;
                end
            end

            if (done_pulses != 1)
                record_fail("done pulse count mismatch");
        end
    endtask

    task check_output_poly;
        input integer pattern_id;
        integer i;
        integer actual;
        integer expected;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk);
                read_addr = i[ADDR_WIDTH-1:0];
                #1;
                actual = read_data;
                expected = ref_poly[i];
                if (actual !== expected) begin
                    fail_count = fail_count + 1;
                    if (!first_fail_seen) begin
                        first_fail_seen = 1;
                        $display("FIRST_FAIL tb_intt_core: pattern=%0d index=%0d expected=%0d actual=%0d",
                                 pattern_id, i, expected, actual);
                    end
                    $display("ERROR tb_intt_core: pattern=%0d index=%0d expected=%0d actual=%0d",
                             pattern_id, i, expected, actual);
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end
    endtask

    task run_pattern;
        input integer pattern_id;
        begin
            $display("INFO tb_intt_core: starting pattern %0d", pattern_id);
            apply_reset();
            init_input_pattern(pattern_id);
            load_input_poly();
            compute_reference_intt();
            start_core();
            wait_for_done();
            check_output_poly(pattern_id);
            $display("INFO tb_intt_core: completed pattern %0d", pattern_id);
        end
    endtask

    initial begin
        $dumpfile("sim/waves/intt_core.vcd");
        $dumpvars(0, tb_intt_core);

        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;
        oracle_zeta_addr = 7'd0;

        run_pattern(0);
        run_pattern(1);
        run_pattern(2);

        $display("INFO tb_intt_core: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("PASS tb_intt_core");
        end else begin
            $display("FAIL tb_intt_core");
        end
        $finish;
    end

endmodule
