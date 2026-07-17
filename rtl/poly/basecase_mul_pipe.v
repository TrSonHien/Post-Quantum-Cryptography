`timescale 1ns / 1ps

// FIPS 203 BaseCaseMultiply over canonical mathematical residues.
// c0=a0*b0+gamma*a1*b1; c1=a0*b1+a1*b0 (mod q).
/*
 * Module: basecase_mul_pipe
 * Status: ACTIVE_SHARED_LEAF
 * Purpose: Polynomial/polyvec workspace, transform adapter, or arithmetic controller.
 * Standard role: FIPS 203 polynomial/polyvec support.
 * Input representation: NORMAL/NTT coefficient domain as named by ports.
 * Output representation: NORMAL/NTT coefficient domain as named by ports.
 * Interface: valid-only pipeline as declared.
 * Latency / completion: See the declared valid/ready or busy/done contract; no fixed latency is implied for controllers.
 * State ownership: owns control and/or pipeline registers.
 * Submodules: fixed_latency_delay, mod_add_pipe, mod_mul_normal_pipe.
 * Verification: See docs/05_code_guide/module_catalog.md and the linked subsystem runner.
 */
module basecase_mul_pipe
    (
        input wire clk,
        input wire rst_n,
        input wire in_valid,
        input wire [11 : 0] a0, a1, b0, b1, gamma,
        output wire out_valid,
        output wire [11 : 0] c0, c1,
        input wire zeroize_req,
        output reg zeroize_busy,
        output reg zeroize_done);
    reg child_zeroize_req;
    reg [9 : 0] child_done_seen;
    wire [9 : 0] child_zeroize_done;
    wire [9 : 0] child_zeroize_busy;
    wire v00, v11, v01, v10;
    wire [11 : 0] p00, p11, p01, p10;
    mod_mul_normal_pipe m00(clk,
                            rst_n,
                            in_valid && !zeroize_busy,
                            a0,
                            b0,
                            v00,
                            p00,
                            child_zeroize_req,
                            child_zeroize_busy[0],
                            child_zeroize_done[0]);
    mod_mul_normal_pipe m11(clk,
                            rst_n,
                            in_valid && !zeroize_busy,
                            a1,
                            b1,
                            v11,
                            p11,
                            child_zeroize_req,
                            child_zeroize_busy[1],
                            child_zeroize_done[1]);
    mod_mul_normal_pipe m01(clk,
                            rst_n,
                            in_valid && !zeroize_busy,
                            a0,
                            b1,
                            v01,
                            p01,
                            child_zeroize_req,
                            child_zeroize_busy[2],
                            child_zeroize_done[2]);
    mod_mul_normal_pipe m10(clk,
                            rst_n,
                            in_valid && !zeroize_busy,
                            a1,
                            b0,
                            v10,
                            p10,
                            child_zeroize_req,
                            child_zeroize_busy[3],
                            child_zeroize_done[3]);

    wire vg;
    wire [11 : 0] gamma_d;
    wire [0 : 0] unused_g;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),
                          .METADATA_WIDTH(1),
                          .LATENCY(4))
        gamma_delay(
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(in_valid),
                .in_payload(gamma),
                .in_metadata(1'b0),
                .out_valid(vg),
                .out_payload(gamma_d),
                .out_metadata(unused_g),
                .zeroize_req(child_zeroize_req),
                .zeroize_busy(child_zeroize_busy[4]),
                .zeroize_done(child_zeroize_done[4]));

    wire vgamma;
    wire [11 : 0] p11g;
    mod_mul_normal_pipe mg(clk,
                           rst_n,
                           v11 && vg && !zeroize_busy,
                           p11,
                           gamma_d,
                           vgamma,
                           p11g,
                           child_zeroize_req,
                           child_zeroize_busy[5],
                           child_zeroize_done[5]);
    wire v00_d;
    wire [11 : 0] p00_d;
    wire [0 : 0] unused_00;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),
                          .METADATA_WIDTH(1),
                          .LATENCY(4))
        p00_delay(
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(v00),
                .in_payload(p00),
                .in_metadata(1'b0),
                .out_valid(v00_d),
                .out_payload(p00_d),
                .out_metadata(unused_00),
                .zeroize_req(child_zeroize_req),
                .zeroize_busy(child_zeroize_busy[6]),
                .zeroize_done(child_zeroize_done[6]));
    wire vcross;
    wire [11 : 0] cross_sum;
    mod_add_pipe across(clk,
                        rst_n,
                        v01 && v10 && !zeroize_busy,
                        p01,
                        p10,
                        vcross,
                        cross_sum,
                        child_zeroize_req,
                        child_zeroize_busy[7],
                        child_zeroize_done[7]);
    wire vcross_d;
    wire [11 : 0] cross_d;
    wire [0 : 0] unused_c;
    fixed_latency_delay #(.PAYLOAD_WIDTH(12),
                          .METADATA_WIDTH(1),
                          .LATENCY(4))
        cross_delay(
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(vcross),
                .in_payload(cross_sum),
                .in_metadata(1'b0),
                .out_valid(vcross_d),
                .out_payload(cross_d),
                .out_metadata(unused_c),
                .zeroize_req(child_zeroize_req),
                .zeroize_busy(child_zeroize_busy[8]),
                .zeroize_done(child_zeroize_done[8]));
    wire v0;
    mod_add_pipe add0(clk,
                      rst_n,
                      vgamma && v00_d && !zeroize_busy,
                      p00_d,
                      p11g,
                      v0,
                      c0,
                      child_zeroize_req,
                      child_zeroize_busy[9],
                      child_zeroize_done[9]);
    assign out_valid = !zeroize_busy && v0 && vcross_d;
    assign c1 = cross_d;
    always @(posedge clk) begin
        child_zeroize_req <= 0;
        zeroize_done <= 0;
        if (!rst_n) begin
            zeroize_busy <= 0;
            zeroize_done <= 0;
            child_zeroize_req <= 0;
            child_done_seen <= 0;
        end else if ((zeroize_req === 1'b1) && !zeroize_busy) begin
            zeroize_busy <= 1;
            child_zeroize_req <= 1;
            child_done_seen <= 0;
        end else if (zeroize_busy) begin
            child_zeroize_req <= 1;
            child_done_seen <= child_done_seen | child_zeroize_done;
            if (&(child_done_seen | child_zeroize_done)) begin
                zeroize_busy <= 0;
                zeroize_done <= 1;
                child_zeroize_req <= 0;
                child_done_seen <= 0;
            end
        end
    end
`ifndef SYNTHESIS
    always @(posedge clk)
        if (rst_n && in_valid && !zeroize_busy &&
            (a0 >= 3329 || a1 >= 3329 || b0 >= 3329 || b1 >= 3329 || gamma >= 3329))
            $fatal(1, "BASECASE_RANGE");
    always @(posedge clk)
        if (rst_n && !zeroize_busy && (v0 != vcross_d))
            $fatal(1, "BASECASE_ALIGNMENT");
`endif
endmodule
