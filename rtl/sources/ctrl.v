`include "defines.v"
module ctrl
(
	input wire					rst			,
	input wire					jump_flag_i	,
	input wire[`InstAddrBus]	jump_addr_i	,
	input wire					hold_flag_i	,
		
	output reg					jump_flag_o	,
	output reg[`InstAddrBus]	jump_addr_o	,
	output reg					hold_flag_o  
);

	always @ (*) begin
		//输入-输出缓存?
		jump_flag_o = jump_flag_i;
		jump_addr_o = jump_addr_i;
		hold_flag_o = hold_flag_i;
	end


endmodule 
