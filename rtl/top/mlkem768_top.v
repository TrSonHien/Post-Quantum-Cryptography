module and_gate (
    input wire a,
    input wire b,
    output wire c
);

assign c = a & b;

endmodule

module top (
    input wire in1, in2, in3, in4,
    output wire out
);

wire out12, out34;

and_gate u_and_gate_00 (.a(in1), .b(in2), .c(out12));
and_gate u_and_gate_01 (.a(in3), .b(in4), .c(out34));
and_gate u_and_gate_02 (.a(out12), .b(out34), .c(out));

endmodule
