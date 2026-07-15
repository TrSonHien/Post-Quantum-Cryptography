module mlkem_h(
 input wire clk,input wire rst_n,input wire cmd_valid,output wire cmd_ready,
 input wire[31:0]msg_len_bytes,input wire in_valid,output wire in_ready,
 input wire[31:0]in_data,input wire[3:0]in_keep,input wire in_last,
 output wire out_valid,input wire out_ready,output wire[31:0]out_data,
 output wire[3:0]out_keep,output wire out_last,output wire busy,
 output wire done,output wire error,input wire zeroize_req,
 output reg zeroize_busy,output reg zeroize_done);
 wire core_busy,core_done,core_cmd_ready,core_zeroize_done;
 wire core_in_ready,core_out_valid,core_error;
 wire[31:0]core_out_data;wire[3:0]core_out_keep;wire core_out_last;
 wire accept_zeroize=(zeroize_req===1'b1);
 assign busy=core_busy|zeroize_busy;assign done=core_done&&!zeroize_busy;
 assign cmd_ready=!zeroize_busy&&core_cmd_ready;
 assign in_ready=!zeroize_busy&&core_in_ready;
 assign out_valid=!zeroize_busy&&core_out_valid;
 assign out_data=core_out_data;assign out_keep=core_out_keep;assign out_last=core_out_last;
 assign error=!zeroize_busy&&core_error;
 sha3_256_stream u(.clk(clk),.rst_n(rst_n),.cmd_valid(cmd_valid&&!zeroize_busy),.cmd_ready(core_cmd_ready),.msg_len_bytes(msg_len_bytes),.in_valid(in_valid&&!zeroize_busy),.in_ready(core_in_ready),.in_data(in_data),.in_keep(in_keep),.in_last(in_last),.out_valid(core_out_valid),.out_ready(out_ready),.out_data(core_out_data),.out_keep(core_out_keep),.out_last(core_out_last),.busy(core_busy),.done(core_done),.error(core_error),.zeroize_req(zeroize_busy),.zeroize_done(core_zeroize_done));
 always@(posedge clk)begin zeroize_done<=0;if(!rst_n)zeroize_busy<=0;else if(accept_zeroize&&!zeroize_busy)zeroize_busy<=1;else if(zeroize_busy&&core_zeroize_done)begin zeroize_busy<=0;zeroize_done<=1;end end
endmodule
