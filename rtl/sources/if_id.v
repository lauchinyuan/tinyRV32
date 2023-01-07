`include "defines.v"


module if_id
(
	input	wire		clk		,
	input 	wire		rst		,
	
	//input
	input	wire[`InstAddrBus]	inst_addr_i	,	//指令地址
	input	wire[`InstBus]		inst_i		,   //指令内容
	
	input 	wire				hold_flag_i	,
	
	//output
	output	wire[`InstAddrBus]	inst_addr_o	,
	output	wire[`InstBus]		inst_o		
);  
//output是input的打拍

	reg rom_flag;  //指令来源标志，1代表来自rom， 2代表空指令
	always @ (posedge clk) begin
		if(hold_flag_i && ~rst) begin
			rom_flag <= 1'b0;
		end else begin
			rom_flag <= 1'b1;
		end
	end
	
	assign inst_o = rom_flag? inst_i: `Inst_NOP;
	
//inst的打拍已经在读取rom的过程中实现
/* set_dff 
#(.DW(32)) inst_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`Inst_NOP),  //复位有效时指令内容为NOP指令
	.data_in	(inst_i),
	.data_out	(inst_o)
); */



//对inst_addr进行打拍
set_dff 
#(.DW(32)) inst_addr_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),  
	.data_in	(inst_addr_i),
	.data_out	(inst_addr_o)
);


endmodule  //endmodule of if_id

