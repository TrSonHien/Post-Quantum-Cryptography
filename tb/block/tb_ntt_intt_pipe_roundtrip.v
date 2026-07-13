`timescale 1ns/1ps

module tb_ntt_intt_pipe_roundtrip;
    initial if ($test$plusargs("DEBUG_WAVES")) begin
        $dumpfile("sim/waves/tb_ntt_intt_pipe_roundtrip.vcd");
        $dumpvars(0, tb_ntt_intt_pipe_roundtrip);
    end
    localparam VECTOR_COUNT = 30;
    localparam WORDS_PER_VECTOR = 768;
    reg clk = 0;
    reg rst_n = 0;

    reg f_start = 0, f_preload_en = 0, f_result_req = 0;
    reg [7:0] f_preload_idx = 0, f_result_idx = 0;
    reg [11:0] f_preload_coeff = 0;
    wire f_busy, f_done, f_error, f_preload_ready, f_result_valid;
    wire [11:0] f_result_data;

    reg i_start = 0, i_preload_en = 0, i_result_req = 0;
    reg [7:0] i_preload_idx = 0, i_result_idx = 0;
    reg [11:0] i_preload_coeff = 0;
    wire i_busy, i_done, i_error, i_preload_ready, i_result_valid;
    wire [11:0] i_result_data;

    reg [11:0] vectors [0:VECTOR_COUNT*WORDS_PER_VECTOR-1];
    reg [11:0] forward_result [0:255];
    integer vector_index;
    integer j;
    integer cycles;
    integer failures = 0;
    integer forward_checks = 0;
    integer roundtrip_checks = 0;
    string vector_file;

    ntt_core_pipe u_forward (
        .clk(clk), .rst_n(rst_n), .start(f_start), .busy(f_busy), .done(f_done), .error(f_error),
        .preload_en(f_preload_en), .preload_idx(f_preload_idx),
        .preload_coeff(f_preload_coeff), .preload_ready(f_preload_ready),
        .result_rd_req(f_result_req), .result_rd_idx(f_result_idx),
        .result_rd_valid(f_result_valid), .result_rd_data(f_result_data)
    );
    intt_core_pipe u_inverse (
        .clk(clk), .rst_n(rst_n), .start(i_start), .busy(i_busy), .done(i_done), .error(i_error),
        .preload_en(i_preload_en), .preload_idx(i_preload_idx),
        .preload_coeff(i_preload_coeff), .preload_ready(i_preload_ready),
        .result_rd_req(i_result_req), .result_rd_idx(i_result_idx),
        .result_rd_valid(i_result_valid), .result_rd_data(i_result_data)
    );
    always #5 clk = ~clk;

    task reset_both;
        begin
            rst_n = 0; f_start = 0; i_start = 0; f_preload_en = 0; i_preload_en = 0;
            f_result_req = 0; i_result_req = 0;
            repeat (3) @(negedge clk); rst_n = 1; repeat (2) @(negedge clk);
        end
    endtask

    task run_one;
        input integer index;
        integer base;
        begin
            base = index * WORDS_PER_VECTOR;
            reset_both();
            for (j = 0; j < 256; j = j + 1) begin
                f_preload_en = 1; f_preload_idx = j[7:0]; f_preload_coeff = vectors[base + j];
                @(negedge clk);
            end
            f_preload_en = 0; repeat (2) @(negedge clk);
            f_start = 1; @(negedge clk); f_start = 0;
            cycles = 0;
            while (!f_done && cycles < 1200) begin @(negedge clk); cycles = cycles + 1; end
            if (!f_done) $fatal(1, "ROUNDTRIP forward timeout vector=%0d", index);
            if (f_error) failures = failures + 1;

            for (j = 0; j < 256; j = j + 1) begin
                f_result_req = 1; f_result_idx = j[7:0]; @(negedge clk);
                if (!f_result_valid || f_result_data !== vectors[base + 256 + j]) begin
                    $display("FORWARD_FAIL vector=%0d index=%0d expected=%0d got=%0d valid=%0b",
                             index, j, vectors[base + 256 + j], f_result_data, f_result_valid);
                    $fatal(1, "First forward differential mismatch");
                end
                forward_result[j] = f_result_data;
                forward_checks = forward_checks + 1;
            end
            f_result_req = 0; repeat (2) @(negedge clk);

            for (j = 0; j < 256; j = j + 1) begin
                i_preload_en = 1; i_preload_idx = j[7:0]; i_preload_coeff = forward_result[j];
                @(negedge clk);
            end
            i_preload_en = 0; repeat (2) @(negedge clk);
            i_start = 1; @(negedge clk); i_start = 0;
            cycles = 0;
            while (!i_done && cycles < 1300) begin @(negedge clk); cycles = cycles + 1; end
            if (!i_done) $fatal(1, "ROUNDTRIP inverse timeout vector=%0d", index);
            if (i_error) failures = failures + 1;

            for (j = 0; j < 256; j = j + 1) begin
                i_result_req = 1; i_result_idx = j[7:0]; @(negedge clk);
                if (!i_result_valid || i_result_data !== vectors[base + 512 + j] ||
                    i_result_data !== vectors[base + j]) begin
                    $display("ROUNDTRIP_FAIL vector=%0d index=%0d input=%0d python=%0d got=%0d valid=%0b",
                             index, j, vectors[base + j], vectors[base + 512 + j],
                             i_result_data, i_result_valid);
                    $fatal(1, "First roundtrip mismatch");
                end
                roundtrip_checks = roundtrip_checks + 1;
            end
            i_result_req = 0; repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        if (!$value$plusargs("VECTOR_FILE=%s", vector_file)) $fatal(1, "Missing +VECTOR_FILE");
        $readmemh(vector_file, vectors);
        for (vector_index = 0; vector_index < VECTOR_COUNT; vector_index = vector_index + 1)
            run_one(vector_index);
        if (failures == 0 && forward_checks == 7680 && roundtrip_checks == 7680) begin
            $display("PASS tb_ntt_intt_pipe_roundtrip polynomials=30 forward_checks=%0d roundtrip_checks=%0d",
                     forward_checks, roundtrip_checks);
            $finish;
        end
        $fatal(1, "FAIL roundtrip failures=%0d forward=%0d final=%0d",
               failures, forward_checks, roundtrip_checks);
    end

    initial begin
        repeat (100000) @(posedge clk);
        $fatal(1, "ROUNDTRIP_GLOBAL_WATCHDOG vector=%0d forward=%0d final=%0d",
               vector_index, forward_checks, roundtrip_checks);
    end
endmodule
