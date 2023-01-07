`include "defines.v"
module set_dff
#(parameter DW = 32)
(
	input wire 				clk		,
	input wire				rst		,
	input wire				hold_flag,
	input wire	[DW-1:0]	set_d	,
	input wire	[DW-1:0]	data_in	,
	output reg	[DW-1:0]	data_out
);
	always@(posedge clk)begin
		if((rst == `Rst) || (hold_flag == `HoldEnable))begin
			data_out <= set_d;
		end else begin
			data_out <= data_in;
		end
	end

endmodule 