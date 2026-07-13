`timescale 1ns/1ps

// FIPS 203 BaseCaseMultiply over canonical mathematical residues.
// c0=a0*b0+gamma*a1*b1; c1=a0*b1+a1*b0 (mod q).
module basecase_mul_pipe(
    input wire clk, input wire rst_n, input wire in_valid,
    input wire [11:0] a0,a1,b0,b1,gamma,
    output wire out_valid, output wire [11:0] c0,c1
);
    wire v00,v11,v01,v10;
    wire [11:0] p00,p11,p01,p10;
    mod_mul_normal_pipe m00(clk,rst_n,in_valid,a0,b0,v00,p00);
    mod_mul_normal_pipe m11(clk,rst_n,in_valid,a1,b1,v11,p11);
    mod_mul_normal_pipe m01(clk,rst_n,in_valid,a0,b1,v01,p01);
    mod_mul_normal_pipe m10(clk,rst_n,in_valid,a1,b0,v10,p10);

    wire vg; wire [11:0] gamma_d; wire [0:0] unused_g;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),.METADATA_WIDTH(1),.LATENCY(4)) gamma_delay(
        .clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_payload(gamma),.in_metadata(1'b0),
        .out_valid(vg),.out_payload(gamma_d),.out_metadata(unused_g));

    wire vgamma; wire [11:0] p11g;
    mod_mul_normal_pipe mg(clk,rst_n,v11 && vg,p11,gamma_d,vgamma,p11g);
    wire v00_d; wire [11:0] p00_d; wire [0:0] unused_00;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),.METADATA_WIDTH(1),.LATENCY(4)) p00_delay(
        .clk(clk),.rst_n(rst_n),.in_valid(v00),.in_payload(p00),.in_metadata(1'b0),
        .out_valid(v00_d),.out_payload(p00_d),.out_metadata(unused_00));
    wire vcross; wire [11:0] cross_sum;
    mod_add_pipe across(clk,rst_n,v01 && v10,p01,p10,vcross,cross_sum);
    wire vcross_d; wire [11:0] cross_d; wire [0:0] unused_c;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),.METADATA_WIDTH(1),.LATENCY(4)) cross_delay(
        .clk(clk),.rst_n(rst_n),.in_valid(vcross),.in_payload(cross_sum),.in_metadata(1'b0),
        .out_valid(vcross_d),.out_payload(cross_d),.out_metadata(unused_c));
    wire v0;
    mod_add_pipe add0(clk,rst_n,vgamma && v00_d,p00_d,p11g,v0,c0);
    assign out_valid = v0 && vcross_d;
    assign c1 = cross_d;
`ifndef SYNTHESIS
    always @(posedge clk) if (rst_n && in_valid &&
        (a0>=3329 || a1>=3329 || b0>=3329 || b1>=3329 || gamma>=3329))
        $fatal(1,"BASECASE_RANGE");
    always @(posedge clk) if (rst_n && (v0 != vcross_d)) $fatal(1,"BASECASE_ALIGNMENT");
`endif
endmodule
