`include "defines.v"
module myram   
#(
	parameter DW = 			32	,
	parameter ADDR_BIT = 	32	
)

(
	input wire					clk			,
	input wire					rst			,
	
	input wire[3:0] 			mem_wen_i	,
	input wire[ADDR_BIT-1:0] 	mem_waddr_i	,
	input wire[DW-1:0]			mem_wdata_i	,
	
	input wire					mem_ren_i	,
	input wire[ADDR_BIT-1:0]	mem_raddr_i ,
	output wire[DW-1:0]			mem_rdata_o	
);
	
	wire[11:0] w_addr = mem_waddr_i[13:2]	;
	wire[11:0] r_addr = mem_raddr_i[13:2]	;
	// byte0
	dual_ram 
	#(
		.DW 			(8),
		.DEPTH 			(4096),
		.ADDR_BIT       (12)
	)
	ram_byte0
	(
		.clk 			(clk),
		.rst			(rst),

		.wen_i			(mem_wen_i[0])		,
		.waddr_i		(w_addr)			,
		.wdata_i		(mem_wdata_i[7:0])	,

		.ren_i			(mem_ren_i)			,
		.raddr_i		(r_addr)			,
		.rdata_o        (mem_rdata_o[7:0])
	);
	
	// byte1
	dual_ram 
	#(
		.DW 			(8),
		.DEPTH 			(4096),
		.ADDR_BIT       (12)
	)
	ram_byte1
	(
		.clk 			(clk),
		.rst			(rst),

		.wen_i			(mem_wen_i[1]),
		.waddr_i		(w_addr),
		.wdata_i		(mem_wdata_i[15:8]),

		.ren_i			(mem_ren_i),
		.raddr_i		(r_addr),
		.rdata_o        (mem_rdata_o[15:8])
	);
	
	dual_ram 
	#(
		.DW 			(8),
		.DEPTH 			(4096),
		.ADDR_BIT       (12)
	)
	ram_byte2
	(
		.clk 			(clk),
		.rst			(rst),

		.wen_i			(mem_wen_i[2]),
		.waddr_i		(w_addr),
		.wdata_i		(mem_wdata_i[23:16]),

		.ren_i			(mem_ren_i),
		.raddr_i		(r_addr),
		.rdata_o        (mem_rdata_o[23:16])
	);
	
	dual_ram 
	#(
		.DW 			(8),
		.DEPTH 			(4096),
		.ADDR_BIT       (12)
	)
	ram_byte3
	(
		.clk 			(clk),
		.rst			(rst),

		.wen_i			(mem_wen_i[3]),
		.waddr_i		(w_addr),
		.wdata_i		(mem_wdata_i[31:24]),

		.ren_i			(mem_ren_i),
		.raddr_i		(r_addr),
		.rdata_o        (mem_rdata_o[31:24])
	);

endmodule 