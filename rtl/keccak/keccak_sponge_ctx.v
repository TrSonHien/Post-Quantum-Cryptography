`timescale 1ns/1ps

module keccak_sponge_ctx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        init_valid,
    output wire        init_ready,
    input  wire [1:0]  mode,
    input  wire        finalize_valid,
    output wire        finalize_ready,
    output reg         context_valid,
    output reg         absorb_phase,
    output reg         squeeze_phase,
    output wire        busy,
    output reg         done,
    output reg         error,
    input  wire        absorb_valid,
    output wire        absorb_ready,
    input  wire [31:0] absorb_data,
    input  wire [3:0]  absorb_keep,
    input  wire        squeeze_req_valid,
    output wire        squeeze_req_ready,
    input  wire [31:0] squeeze_len_bytes,
    output reg         out_valid,
    input  wire        out_ready,
    output reg  [31:0] out_data,
    output reg  [3:0]  out_keep,
    output reg         out_last
);
    localparam OWNER_ABSORB=2'd0, OWNER_FINAL=2'd1, OWNER_SQUEEZE=2'd2;
    reg [1:0] mode_reg;
    reg [7:0] rate_bytes;
    reg [7:0] suffix;
    reg [1599:0] state_reg;
    reg [7:0] absorb_offset;
    reg [7:0] squeeze_offset;

    reg hold_valid;
    reg [31:0] hold_data;
    reg [2:0] hold_count;
    reg [1:0] hold_index;

    reg perm_start;
    reg perm_active;
    reg [1:0] perm_owner;
    reg [1599:0] perm_state_in;
    wire perm_busy,perm_done,perm_error;
    wire [1599:0] perm_state_out;

    reg squeeze_active;
    reg [31:0] squeeze_remaining;
    reg [31:0] build_data;
    reg [2:0] build_count;
    reg sha3_used;
    integer keep_n;

    function automatic integer keep_count;
        input [3:0] keep;
        begin
            case(keep)
                4'b0001:keep_count=1;4'b0011:keep_count=2;
                4'b0111:keep_count=3;4'b1111:keep_count=4;
                default:keep_count=0;
            endcase
        end
    endfunction

    function automatic [3:0] count_keep;
        input [2:0] count;
        begin
            case(count)
                3'd1:count_keep=4'b0001;3'd2:count_keep=4'b0011;
                3'd3:count_keep=4'b0111;default:count_keep=4'b1111;
            endcase
        end
    endfunction

    function automatic [1599:0] xor_byte;
        input [1599:0] s;
        input [7:0] offset;
        input [7:0] value;
        reg [1599:0] t;
        begin t=s;t[8*offset +: 8]=t[8*offset +: 8]^value;xor_byte=t;end
    endfunction

    function automatic [1599:0] apply_pad;
        input [1599:0] s;
        input [7:0] offset;
        input [7:0] rate;
        input [7:0] delim;
        reg [1599:0] t;
        begin
            t=s;
            t[8*offset +:8]=t[8*offset +:8]^delim;
            t[8*(rate-1'b1) +:8]=t[8*(rate-1'b1) +:8]^8'h80;
            apply_pad=t;
        end
    endfunction

    function automatic [31:0] insert_byte;
        input [31:0] word;
        input [2:0] index;
        input [7:0] value;
        reg [31:0] t;
        begin t=word;t[8*index +:8]=value;insert_byte=t;end
    endfunction

    assign init_ready = !perm_active && !hold_valid && !squeeze_active && !out_valid;
    assign absorb_ready = context_valid && absorb_phase && !perm_active &&
                          !hold_valid && !error;
    assign finalize_ready = context_valid && absorb_phase && !perm_active &&
                            !hold_valid && !error;
    assign squeeze_req_ready = context_valid && squeeze_phase && !perm_active &&
                               !squeeze_active && !out_valid && !sha3_used && !error;
    assign busy = perm_active || hold_valid || squeeze_active || out_valid;

    keccak_f1600_core u_perm (
        .clk(clk),.rst_n(rst_n),.start(perm_start),.state_in(perm_state_in),
        .busy(perm_busy),.done(perm_done),.error(perm_error),.state_out(perm_state_out)
    );

    always @(posedge clk) begin
        if(!rst_n) begin
            mode_reg<=0;rate_bytes<=0;suffix<=0;context_valid<=0;
            absorb_phase<=0;squeeze_phase<=0;done<=0;error<=0;
            absorb_offset<=0;squeeze_offset<=0;hold_valid<=0;hold_data<=0;
            hold_count<=0;hold_index<=0;perm_start<=0;perm_active<=0;
            perm_owner<=0;perm_state_in<=0;squeeze_active<=0;
            squeeze_remaining<=0;build_data<=0;build_count<=0;
            out_valid<=0;out_data<=0;out_keep<=0;out_last<=0;sha3_used<=0;
        end else begin
            done<=0;perm_start<=0;
            if(perm_error)error<=1;

            // Illegal-phase commands error; temporary ready stalls do not.
            if(init_valid && !init_ready)error<=1;
            if(absorb_valid && (!context_valid || !absorb_phase))error<=1;
            if(finalize_valid && (!context_valid || !absorb_phase))error<=1;
            if(squeeze_req_valid && (!context_valid || !squeeze_phase))error<=1;

            if(perm_active && perm_done) begin
                state_reg<=perm_state_out;perm_active<=0;
                case(perm_owner)
                    OWNER_ABSORB: absorb_offset<=0;
                    OWNER_FINAL: begin
                        absorb_phase<=0;squeeze_phase<=1;squeeze_offset<=0;done<=1;
                    end
                    OWNER_SQUEEZE: squeeze_offset<=0;
                    default: error<=1;
                endcase
            end else if(init_valid && init_ready) begin
                mode_reg<=mode;state_reg<=0;context_valid<=1;absorb_phase<=1;
                squeeze_phase<=0;absorb_offset<=0;squeeze_offset<=0;
                hold_valid<=0;squeeze_active<=0;build_count<=0;out_valid<=0;
                sha3_used<=0;error<=0;
                case(mode)
                    2'd0:begin rate_bytes<=8'd136;suffix<=8'h06;end
                    2'd1:begin rate_bytes<=8'd72;suffix<=8'h06;end
                    2'd2:begin rate_bytes<=8'd168;suffix<=8'h1f;end
                    2'd3:begin rate_bytes<=8'd136;suffix<=8'h1f;end
                endcase
            end else if(absorb_valid && absorb_ready) begin
                keep_n=keep_count(absorb_keep);
                if(keep_n==0)error<=1;
                else begin
                    hold_valid<=1;hold_data<=absorb_data;
                    hold_count<=keep_n[2:0];hold_index<=0;
                end
            end else if(hold_valid && !perm_active) begin
                state_reg<=xor_byte(state_reg,absorb_offset,
                                    hold_data[8*hold_index +:8]);
                if(hold_index+1 >= hold_count)hold_valid<=0;
                else hold_index<=hold_index+1'b1;
                if(absorb_offset==rate_bytes-1'b1) begin
                    perm_state_in<=xor_byte(state_reg,absorb_offset,
                                            hold_data[8*hold_index +:8]);
                    perm_start<=1;perm_active<=1;perm_owner<=OWNER_ABSORB;
                    absorb_offset<=0;
                end else absorb_offset<=absorb_offset+1'b1;
            end else if(finalize_valid && finalize_ready) begin
                perm_state_in<=apply_pad(state_reg,absorb_offset,rate_bytes,suffix);
                perm_start<=1;perm_active<=1;perm_owner<=OWNER_FINAL;
                absorb_phase<=0;
            end else if(squeeze_req_valid && squeeze_req_ready) begin
                if(squeeze_len_bytes==0)error<=1;
                else if((mode_reg==2'd0 && squeeze_len_bytes!=32) ||
                        (mode_reg==2'd1 && squeeze_len_bytes!=64))error<=1;
                else begin
                    squeeze_active<=1;squeeze_remaining<=squeeze_len_bytes;
                    build_data<=0;build_count<=0;
                end
            end else if(squeeze_active && !out_valid && !perm_active) begin
                if(squeeze_offset>=rate_bytes) begin
                    perm_state_in<=state_reg;perm_start<=1;perm_active<=1;
                    perm_owner<=OWNER_SQUEEZE;
                end else begin
                    build_data<=insert_byte(build_data,build_count,
                                           state_reg[8*squeeze_offset +:8]);
                    squeeze_remaining<=squeeze_remaining-1'b1;
                    if(squeeze_offset==rate_bytes-1'b1) begin
                        squeeze_offset<=rate_bytes;
                        if(squeeze_remaining>1) begin
                            perm_state_in<=state_reg;perm_start<=1;perm_active<=1;
                            perm_owner<=OWNER_SQUEEZE;
                        end
                    end else squeeze_offset<=squeeze_offset+1'b1;

                    if(build_count==3 || squeeze_remaining==1) begin
                        out_data<=insert_byte(build_data,build_count,
                                             state_reg[8*squeeze_offset +:8]);
                        out_keep<=count_keep(build_count+1'b1);
                        out_last<=(squeeze_remaining==1);
                        out_valid<=1;build_count<=0;build_data<=0;
                    end else build_count<=build_count+1'b1;
                end
            end else if(out_valid && out_ready) begin
                out_valid<=0;
                if(out_last) begin
                    squeeze_active<=0;done<=1;
                    if(mode_reg<2)begin sha3_used<=1;context_valid<=0;squeeze_phase<=0;end
                end
            end
        end
    end
endmodule
