`include "defines.v"
module mycore_soc
(
	input wire			clk		,
	input wire 			rst		
);
	
	wire[`InstBus]		rom_inst_o						;
	wire[`InstAddrBus]	core_inst_addr_o				;
	wire[3:0] 			core_mem_wen_o					;
	wire[`MemBus]		core_mem_wdata_o				;
	wire[`MemAddrBus]	core_mem_waddr_o				;
	wire[`MemBus]		core_mem_raddr_o				;
	wire				core_mem_ren_o					;
	
	wire[`MemBus]		ram_rdata_o						;
	
	wire[`InstAddrBus]	uart_wmem_addr_o = 32'b0		;
	wire[`InstBus]		uart_wmem_data_o = 32'b0		;
	wire				uart_wmem_en_o	 = `WriteDisable;

	
	mycore core
	(
		.clk				(clk),
		.rst				(rst),

		.inst_i				(rom_inst_o),
		.inst_addr_o	    (core_inst_addr_o),

		.ex_mem_wen_o		(core_mem_wen_o), //Write(S类指令)
		.ex_mem_wdata_o		(core_mem_wdata_o),
		.ex_mem_waddr_o 	(core_mem_waddr_o),

		.mem_rdata_i		(ram_rdata_o),
		.id_mem_ren_o		(core_mem_ren_o),
		.id_mem_raddr_o	    (core_mem_raddr_o)
	);
	
	
	myram  
	#(
		.DW			(32)	,
		.ADDR_BIT   (32)
	)
	unit_ram
	(
		.clk			(clk),
		.rst			(rst),

		.mem_wen_i		(core_mem_wen_o)	,
		.mem_waddr_i	(core_mem_waddr_o)	,
		.mem_wdata_i	(core_mem_wdata_o)	,

		.mem_ren_i		(core_mem_ren_o)	,
		.mem_raddr_i 	(core_mem_raddr_o)	,
		.mem_rdata_o	(ram_rdata_o)
	);


	my_rom8x4096 unit_rom
	(
		.clk			(clk				),
		.rst			(rst				),
		.w_addr_i		(uart_wmem_addr_o	),
		.w_en_i			(uart_wmem_en_o		),
		.w_data_i		(uart_wmem_data_o	),

		.r_addr_i		(core_inst_addr_o	),
		.r_en_i			(`ReadEnable		),
		.inst_o		    (rom_inst_o			)
	);
endmodule 