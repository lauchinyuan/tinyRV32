`include "defines.v"
module my_rom8x4096
(
	input wire 					clk			,
	input wire					rst			,
	input wire[`InstAddrBus]	w_addr_i	,
	input wire					w_en_i		,
	input wire[`InstBus]		w_data_i	,
		
	input wire[`InstAddrBus]	r_addr_i	,
	input wire					r_en_i		,
	output wire[`InstBus]		inst_o	
);

	wire[`RamAddrBus] w_addr = w_addr_i[13:2];   //宏定义不匹配问题解决
	wire[`RamAddrBus] r_addr = r_addr_i[13:2];
	
dual_ram 
#(
	.DW 		(32		)		,
	.DEPTH 		(4096	)		,
	.ADDR_BIT 	(12     )
)unit_ram_rom
(
	.clk 			(clk	)	,
	.rst			(rst	)	,

	.wen_i			(w_en_i)	,
	.waddr_i		(w_addr)	,
	.wdata_i		(w_data_i)	,

	.ren_i			(r_en_i)	,
	.raddr_i		(r_addr	)	,
	.rdata_o        (inst_o	)
);
endmodule