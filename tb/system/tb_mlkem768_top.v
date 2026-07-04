`timescale 1ns/1ps

module test_bench; 

    reg in1, in2, in3, in4;
    wire out;

    top dut (
        .in1(in1), .in2(in2), .in3(in3), .in4(in4),
        .out(out)
    );

    initial begin
        $display("Start simu...");
        
        in1=0; in2=0; in3=0; in4=0;
        #10; 
        
        in1=1; in2=1; in3=1; in4=0;
        #10;
        
        in1=1; in2=1; in3=1; in4=1;
        #10;
        
        $display("End simu!");
        $finish; 
    end

endmodule
