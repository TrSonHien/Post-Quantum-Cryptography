`timescale 1ns/1ps

// Four-bank out-of-place NTT storage. Two banks are the source set and two are
// the destination set. swap_roles is legal only with no traffic or pending read.
module ntt_pingpong_banks #(
    parameter DATA_WIDTH = 12
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  swap_roles,
    output reg                   role_select,

    input  wire                  src_rd_en,
    input  wire [7:0]            src_index0,
    input  wire [7:0]            src_index1,
    input  wire [2:0]            src_pair_bit,
    input  wire [2:0]            src_addr_bit,
    input  wire                  src_xor_layout,
    output wire                  src_rd_valid,
    output wire [DATA_WIDTH-1:0] src_data0,
    output wire [DATA_WIDTH-1:0] src_data1,

    input  wire                  dst_wr_en,
    input  wire [7:0]            dst_index0,
    input  wire [7:0]            dst_index1,
    input  wire [2:0]            dst_pair_bit,
    input  wire [2:0]            dst_addr_bit,
    input  wire                  dst_xor_layout,
    input  wire [DATA_WIDTH-1:0] dst_data0,
    input  wire [DATA_WIDTH-1:0] dst_data1,

    input  wire                  zeroize_req,
    output reg                   zeroize_busy,
    output reg                   zeroize_done
);

    wire src_bank0_sel, src_bank1_sel;
    wire dst_bank0_sel, dst_bank1_sel;
    wire [6:0] src_addr0, src_addr1, dst_addr0, dst_addr1;

    ntt_bank_map u_src_map0 (src_index0, src_pair_bit, src_addr_bit, src_xor_layout, src_bank0_sel, src_addr0);
    ntt_bank_map u_src_map1 (src_index1, src_pair_bit, src_addr_bit, src_xor_layout, src_bank1_sel, src_addr1);
    ntt_bank_map u_dst_map0 (dst_index0, dst_pair_bit, dst_addr_bit, dst_xor_layout, dst_bank0_sel, dst_addr0);
    ntt_bank_map u_dst_map1 (dst_index1, dst_pair_bit, dst_addr_bit, dst_xor_layout, dst_bank1_sel, dst_addr1);

    wire [6:0] src_phys_addr0 = src_bank0_sel ? src_addr1 : src_addr0;
    wire [6:0] src_phys_addr1 = src_bank0_sel ? src_addr0 : src_addr1;
    wire [6:0] dst_phys_addr0 = dst_bank0_sel ? dst_addr1 : dst_addr0;
    wire [6:0] dst_phys_addr1 = dst_bank0_sel ? dst_addr0 : dst_addr1;
    wire [DATA_WIDTH-1:0] dst_phys_data0 = dst_bank0_sel ? dst_data1 : dst_data0;
    wire [DATA_WIDTH-1:0] dst_phys_data1 = dst_bank0_sel ? dst_data0 : dst_data1;

    wire a0_rd_valid, a1_rd_valid, b0_rd_valid, b1_rd_valid;
    wire [DATA_WIDTH-1:0] a0_rd_data, a1_rd_data, b0_rd_data, b1_rd_data;
    wire source_rd_valid0 = role_select ? b0_rd_valid : a0_rd_valid;
    wire source_rd_valid1 = role_select ? b1_rd_valid : a1_rd_valid;
    wire [DATA_WIDTH-1:0] source_data_bank0 = role_select ? b0_rd_data : a0_rd_data;
    wire [DATA_WIDTH-1:0] source_data_bank1 = role_select ? b1_rd_data : a1_rd_data;

    reg src_index0_bank_d;
    reg [6:0] scrub_addr;
    reg scrub_commit_pending;
    wire accept_zeroize = (zeroize_req === 1'b1);
    always @(posedge clk) begin
        if (!rst_n) begin
            role_select <= 1'b0;
            src_index0_bank_d <= 1'b0;
            scrub_addr <= 7'd0;
            scrub_commit_pending <= 1'b0;
            zeroize_busy <= 1'b0;
            zeroize_done <= 1'b0;
        end else begin
            zeroize_done <= 1'b0;
            if (accept_zeroize && !zeroize_busy) begin
                role_select <= 1'b0;
                src_index0_bank_d <= 1'b0;
                scrub_addr <= 7'd0;
                scrub_commit_pending <= 1'b0;
                zeroize_busy <= 1'b1;
            end else if (zeroize_busy) begin
                if (scrub_commit_pending) begin
                    scrub_commit_pending <= 1'b0;
                    zeroize_busy <= 1'b0;
                    zeroize_done <= 1'b1;
                end else if (scrub_addr == 7'd127) begin
                    scrub_commit_pending <= 1'b1;
                end else begin
                    scrub_addr <= scrub_addr + 1'b1;
                end
            end else begin
            if (src_rd_en)
                src_index0_bank_d <= src_bank0_sel;
            if (swap_roles)
                role_select <= ~role_select;
`ifndef SYNTHESIS
            if (src_rd_en && (src_bank0_sel == src_bank1_sel))
                $fatal(1, "NTT_BANK_MAP: source indices map to the same bank");
            if (dst_wr_en && (dst_bank0_sel == dst_bank1_sel))
                $fatal(1, "NTT_BANK_MAP: destination indices map to the same bank");
            if (swap_roles && (src_rd_en || dst_wr_en || source_rd_valid0 || source_rd_valid1))
                $fatal(1, "NTT_BANK_SWAP: swap with active or pending traffic");
`endif
            end
        end
    end

    assign src_rd_valid = !zeroize_busy && source_rd_valid0 && source_rd_valid1;
    assign src_data0 = src_index0_bank_d ? source_data_bank1 : source_data_bank0;
    assign src_data1 = src_index0_bank_d ? source_data_bank0 : source_data_bank1;

    wire scrub_write = zeroize_busy && !scrub_commit_pending;
    wire a0_wr_en = scrub_write || (dst_wr_en && role_select);
    wire a1_wr_en = scrub_write || (dst_wr_en && role_select);
    wire b0_wr_en = scrub_write || (dst_wr_en && !role_select);
    wire b1_wr_en = scrub_write || (dst_wr_en && !role_select);
    wire [6:0] a0_wr_addr = scrub_write ? scrub_addr : dst_phys_addr0;
    wire [6:0] a1_wr_addr = scrub_write ? scrub_addr : dst_phys_addr1;
    wire [6:0] b0_wr_addr = scrub_write ? scrub_addr : dst_phys_addr0;
    wire [6:0] b1_wr_addr = scrub_write ? scrub_addr : dst_phys_addr1;
    wire [DATA_WIDTH-1:0] a0_wr_data = scrub_write ? {DATA_WIDTH{1'b0}} : dst_phys_data0;
    wire [DATA_WIDTH-1:0] a1_wr_data = scrub_write ? {DATA_WIDTH{1'b0}} : dst_phys_data1;
    wire [DATA_WIDTH-1:0] b0_wr_data = scrub_write ? {DATA_WIDTH{1'b0}} : dst_phys_data0;
    wire [DATA_WIDTH-1:0] b1_wr_data = scrub_write ? {DATA_WIDTH{1'b0}} : dst_phys_data1;

    sync_1r1w_ram #(.DATA_WIDTH(DATA_WIDTH)) u_set_a_bank0 (
        clk, rst_n,
        src_rd_en && !role_select && !zeroize_busy, src_phys_addr0, a0_rd_valid, a0_rd_data,
        a0_wr_en, a0_wr_addr, a0_wr_data
    );
    sync_1r1w_ram #(.DATA_WIDTH(DATA_WIDTH)) u_set_a_bank1 (
        clk, rst_n,
        src_rd_en && !role_select && !zeroize_busy, src_phys_addr1, a1_rd_valid, a1_rd_data,
        a1_wr_en, a1_wr_addr, a1_wr_data
    );
    sync_1r1w_ram #(.DATA_WIDTH(DATA_WIDTH)) u_set_b_bank0 (
        clk, rst_n,
        src_rd_en && role_select && !zeroize_busy, src_phys_addr0, b0_rd_valid, b0_rd_data,
        b0_wr_en, b0_wr_addr, b0_wr_data
    );
    sync_1r1w_ram #(.DATA_WIDTH(DATA_WIDTH)) u_set_b_bank1 (
        clk, rst_n,
        src_rd_en && role_select && !zeroize_busy, src_phys_addr1, b1_rd_valid, b1_rd_data,
        b1_wr_en, b1_wr_addr, b1_wr_data
    );

endmodule
