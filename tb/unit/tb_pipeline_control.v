`timescale 1ns/1ps

module tb_pipeline_control;
    reg clk=0,rst_n=0;
    reg delay_in_valid=0;
    reg [11:0] delay_in_payload=0;
    reg [15:0] delay_in_metadata=0;
    wire delay_out_valid;
    wire [11:0] delay_out_payload;
    wire [15:0] delay_out_metadata;
    reg slice_in_valid=0;
    wire slice_in_ready;
    reg [11:0] slice_in_payload=0;
    reg [15:0] slice_in_metadata=0;
    wire slice_out_valid;
    reg slice_out_ready=0;
    wire [11:0] slice_out_payload;
    wire [15:0] slice_out_metadata;
    reg [2:0] exp_valid_pipe=0;
    reg [11:0] exp_payload_pipe[0:2];
    reg [15:0] exp_metadata_pipe[0:2];
    integer pass_count=0,fail_count=0,i;

    always #5 clk=~clk;
    fixed_latency_delay #(.LATENCY(3)) delay_dut(
        clk,rst_n,delay_in_valid,delay_in_payload,delay_in_metadata,
        delay_out_valid,delay_out_payload,delay_out_metadata);
    rv_register_slice #(.PAYLOAD_WIDTH(12), .METADATA_WIDTH(16)) slice_dut(
        clk,rst_n,slice_in_valid,slice_in_ready,slice_in_payload,slice_in_metadata,
        slice_out_valid,slice_out_ready,slice_out_payload,slice_out_metadata);

    always @(posedge clk) begin
        if(!rst_n) begin
            exp_valid_pipe <= 3'b000;
        end else begin
            exp_valid_pipe[0] <= delay_in_valid;
            exp_valid_pipe[1] <= exp_valid_pipe[0];
            exp_valid_pipe[2] <= exp_valid_pipe[1];
            if(delay_in_valid) begin
                exp_payload_pipe[0] <= delay_in_payload;
                exp_metadata_pipe[0] <= delay_in_metadata;
            end
            if(exp_valid_pipe[0]) begin
                exp_payload_pipe[1] <= exp_payload_pipe[0];
                exp_metadata_pipe[1] <= exp_metadata_pipe[0];
            end
            if(exp_valid_pipe[1]) begin
                exp_payload_pipe[2] <= exp_payload_pipe[1];
                exp_metadata_pipe[2] <= exp_metadata_pipe[1];
            end
        end
        #1;
        if(delay_out_valid!==exp_valid_pipe[2]) begin
            $display("FAIL delay valid expected=%b actual=%b",exp_valid_pipe[2],delay_out_valid); fail_count=fail_count+1;
        end else if(delay_out_valid && (delay_out_payload!==exp_payload_pipe[2] || delay_out_metadata!==exp_metadata_pipe[2])) begin
            $display("FAIL delay payload/metadata alignment"); fail_count=fail_count+1;
        end else pass_count=pass_count+1;
    end

    initial begin
        repeat(2) @(posedge clk); @(negedge clk); rst_n=1;
        for(i=0;i<12;i=i+1) begin
            @(negedge clk); delay_in_valid=(i%4)!=2; delay_in_payload=i*9+3;
            delay_in_metadata=16'h8000|i;
        end
        @(negedge clk); delay_in_valid=0;
        repeat(5) @(posedge clk);

        // Reset flushes valid state without requiring payload reset.
        @(negedge clk); delay_in_valid=1; delay_in_payload=12'habc; delay_in_metadata=16'h8abc;
        @(posedge clk); #2; @(negedge clk); rst_n=0; delay_in_valid=0;
        @(posedge clk); #2;
        if(delay_out_valid) begin $display("FAIL delay reset flush"); fail_count=fail_count+1; end else pass_count=pass_count+1;
        @(negedge clk); rst_n=1;

        // Register slice: fill, stall while checking stability, consume/refill.
        slice_out_ready=0; slice_in_valid=1; slice_in_payload=12'h123; slice_in_metadata=16'h4567;
        @(posedge clk); #2;
        if(!slice_out_valid || slice_out_payload!==12'h123 || slice_out_metadata!==16'h4567) fail_count=fail_count+1; else pass_count=pass_count+1;
        @(negedge clk); slice_in_payload=12'h999; slice_in_metadata=16'haaaa;
        repeat(3) begin @(posedge clk); #2; if(slice_in_ready || slice_out_payload!==12'h123 || slice_out_metadata!==16'h4567) fail_count=fail_count+1; else pass_count=pass_count+1; end
        @(negedge clk); slice_out_ready=1;
        @(posedge clk); #2;
        if(!slice_out_valid || slice_out_payload!==12'h999 || slice_out_metadata!==16'haaaa) fail_count=fail_count+1; else pass_count=pass_count+1;
        @(negedge clk); slice_in_valid=0;
        @(posedge clk); #2;
        if(slice_out_valid) fail_count=fail_count+1; else pass_count=pass_count+1;

        $display("INFO tb_pipeline_control: pass_count=%0d fail_count=%0d",pass_count,fail_count);
        if(fail_count==0) $display("PASS tb_pipeline_control"); else $fatal(1,"FAIL tb_pipeline_control");
        $finish;
    end
endmodule
