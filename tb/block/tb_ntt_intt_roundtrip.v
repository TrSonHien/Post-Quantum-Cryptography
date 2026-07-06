`timescale 1ns/1ps
`include "kyber_params.vh"

module tb_ntt_intt_roundtrip;

    localparam integer N = `KYBER_N;
    localparam integer DATA_WIDTH = `KYBER_Q_WIDTH;
    localparam integer ADDR_WIDTH = `KYBER_N_WIDTH;
    localparam integer NTT_TIMEOUT = 920;
    localparam integer INTT_TIMEOUT = 1180;
    localparam integer MONT = 2285; // 2^16 mod KYBER_Q

    reg clk;
    reg rst_n;

    reg ntt_start;
    wire ntt_busy;
    wire ntt_done;
    reg                  ntt_load_en;
    reg  [ADDR_WIDTH-1:0] ntt_load_addr;
    reg  [DATA_WIDTH-1:0] ntt_load_data;
    reg  [ADDR_WIDTH-1:0] ntt_read_addr;
    wire [DATA_WIDTH-1:0] ntt_read_data;

    reg intt_start;
    wire intt_busy;
    wire intt_done;
    reg                  intt_load_en;
    reg  [ADDR_WIDTH-1:0] intt_load_addr;
    reg  [DATA_WIDTH-1:0] intt_load_data;
    reg  [ADDR_WIDTH-1:0] intt_read_addr;
    wire [DATA_WIDTH-1:0] intt_read_data;

    integer pass_count;
    integer fail_count;
    integer first_fail_seen;
    integer input_poly [0:N-1];

    ntt_core u_ntt_core (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (ntt_start),
        .busy      (ntt_busy),
        .done      (ntt_done),
        .load_en   (ntt_load_en),
        .load_addr (ntt_load_addr),
        .load_data (ntt_load_data),
        .read_addr (ntt_read_addr),
        .read_data (ntt_read_data)
    );

    intt_core u_intt_core (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (intt_start),
        .busy      (intt_busy),
        .done      (intt_done),
        .load_en   (intt_load_en),
        .load_addr (intt_load_addr),
        .load_data (intt_load_data),
        .read_addr (intt_read_addr),
        .read_data (intt_read_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task record_fail;
        input [1023:0] message;
        begin
            fail_count = fail_count + 1;
            if (!first_fail_seen) begin
                first_fail_seen = 1;
                $display("FIRST_FAIL tb_ntt_intt_roundtrip: %0s", message);
            end
            $display("ERROR tb_ntt_intt_roundtrip: %0s", message);
        end
    endtask

    task apply_reset;
        begin
            rst_n = 1'b0;
            ntt_start = 1'b0;
            ntt_load_en = 1'b0;
            ntt_load_addr = {ADDR_WIDTH{1'b0}};
            ntt_load_data = {DATA_WIDTH{1'b0}};
            ntt_read_addr = {ADDR_WIDTH{1'b0}};
            intt_start = 1'b0;
            intt_load_en = 1'b0;
            intt_load_addr = {ADDR_WIDTH{1'b0}};
            intt_load_data = {DATA_WIDTH{1'b0}};
            intt_read_addr = {ADDR_WIDTH{1'b0}};
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
                    0: input_poly[i] = i % `KYBER_Q;
                    1: input_poly[i] = ((i * 23) + (i * i * 7) + 3) % `KYBER_Q;
                    2: input_poly[i] = ((i * 97) ^ (i * 11) ^ 16'h5a5a) % `KYBER_Q;
                    3: input_poly[i] = (i[0] == 0) ? 0 : (`KYBER_Q - 1);
                    default: input_poly[i] = 0;
                endcase
            end
        end
    endtask

    task load_ntt_input;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk);
                ntt_load_en = 1'b1;
                ntt_load_addr = i[ADDR_WIDTH-1:0];
                ntt_load_data = input_poly[i][DATA_WIDTH-1:0];
            end
            @(negedge clk);
            ntt_load_en = 1'b0;
            ntt_load_addr = {ADDR_WIDTH{1'b0}};
            ntt_load_data = {DATA_WIDTH{1'b0}};
        end
    endtask

    task start_ntt;
        begin
            @(negedge clk);
            ntt_start = 1'b1;
            @(negedge clk);
            ntt_start = 1'b0;
        end
    endtask

    task start_intt;
        begin
            @(negedge clk);
            intt_start = 1'b1;
            @(negedge clk);
            intt_start = 1'b0;
        end
    endtask

    task wait_for_ntt_done;
        integer cycles;
        integer done_pulses;
        begin
            cycles = 0;
            done_pulses = 0;
            while (cycles < NTT_TIMEOUT) begin
                @(negedge clk);
                #1;
                if (ntt_done) begin
                    done_pulses = done_pulses + 1;
                    if (ntt_busy)
                        record_fail("ntt_busy must be low when ntt_done is high");
                    @(negedge clk);
                    #1;
                    if (ntt_done)
                        record_fail("ntt_done must pulse for exactly one cycle");
                    if (ntt_busy)
                        record_fail("ntt_busy must stay low after ntt_done");
                    cycles = NTT_TIMEOUT;
                end else begin
                    cycles = cycles + 1;
                end
            end

            if (done_pulses != 1)
                record_fail("ntt_done pulse count mismatch");
        end
    endtask

    task wait_for_intt_done;
        integer cycles;
        integer done_pulses;
        begin
            cycles = 0;
            done_pulses = 0;
            while (cycles < INTT_TIMEOUT) begin
                @(negedge clk);
                #1;
                if (intt_done) begin
                    done_pulses = done_pulses + 1;
                    if (intt_busy)
                        record_fail("intt_busy must be low when intt_done is high");
                    @(negedge clk);
                    #1;
                    if (intt_done)
                        record_fail("intt_done must pulse for exactly one cycle");
                    if (intt_busy)
                        record_fail("intt_busy must stay low after intt_done");
                    cycles = INTT_TIMEOUT;
                end else begin
                    cycles = cycles + 1;
                end
            end

            if (done_pulses != 1)
                record_fail("intt_done pulse count mismatch");
        end
    endtask

    task transfer_ntt_to_intt;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk);
                ntt_read_addr = i[ADDR_WIDTH-1:0];
                #1;
                intt_load_en = 1'b1;
                intt_load_addr = i[ADDR_WIDTH-1:0];
                intt_load_data = ntt_read_data;
            end
            @(negedge clk);
            intt_load_en = 1'b0;
            intt_load_addr = {ADDR_WIDTH{1'b0}};
            intt_load_data = {DATA_WIDTH{1'b0}};
        end
    endtask

    function integer montgomery_domain_expected;
        input integer coeff;
        begin
            montgomery_domain_expected = (coeff * MONT) % `KYBER_Q;
        end
    endfunction

    task check_roundtrip_output;
        input integer pattern_id;
        integer i;
        integer actual;
        integer expected;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk);
                intt_read_addr = i[ADDR_WIDTH-1:0];
                #1;
                actual = intt_read_data;
                expected = montgomery_domain_expected(input_poly[i]);
                if (actual !== expected) begin
                    fail_count = fail_count + 1;
                    if (!first_fail_seen) begin
                        first_fail_seen = 1;
                        $display("FIRST_FAIL tb_ntt_intt_roundtrip: pattern=%0d index=%0d expected=%0d actual=%0d",
                                 pattern_id, i, expected, actual);
                    end
                    $display("ERROR tb_ntt_intt_roundtrip: pattern=%0d index=%0d expected=%0d actual=%0d",
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
            $display("INFO tb_ntt_intt_roundtrip: starting pattern %0d", pattern_id);
            apply_reset();
            init_input_pattern(pattern_id);
            load_ntt_input();
            start_ntt();
            wait_for_ntt_done();
            transfer_ntt_to_intt();
            start_intt();
            wait_for_intt_done();
            check_roundtrip_output(pattern_id);
            $display("INFO tb_ntt_intt_roundtrip: completed pattern %0d", pattern_id);
        end
    endtask

    initial begin
        $dumpfile("sim/waves/ntt_intt_roundtrip.vcd");
        $dumpvars(0, tb_ntt_intt_roundtrip);

        pass_count = 0;
        fail_count = 0;
        first_fail_seen = 0;

        run_pattern(0);
        run_pattern(1);
        run_pattern(2);
        run_pattern(3);

        $display("INFO tb_ntt_intt_roundtrip: pass_count=%0d fail_count=%0d", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("PASS tb_ntt_intt_roundtrip");
        end else begin
            $display("FAIL tb_ntt_intt_roundtrip");
        end
        $finish;
    end

endmodule
