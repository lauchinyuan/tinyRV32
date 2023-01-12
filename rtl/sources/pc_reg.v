`include "defines.v"  //参数
module pc_reg
(
	input	wire					clk			,
	input	wire					rst			,
	input	wire					jump_flag_i	,
	input	wire	[`InstAddrBus]	jump_addr_i	,
	input 	wire					hold_flag_i	,
	
	output	reg		[`InstAddrBus]	pc_o		

);

always@(posedge clk) begin
	if (rst == `Rst) begin   //复位
		pc_o <= `CpuResetAddr;
	end else if(jump_flag_i == `JumpEnable) begin //发生跳转
		pc_o <= jump_addr_i;
	end else if(hold_flag_i == `HoldEnable) begin
		pc_o <= pc_o;
	end else begin		//按顺序执行
		pc_o <= pc_o + 32'd4;
	end
end

endmodule


