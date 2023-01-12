`include "defines.v"
module mycore
(
	input wire					clk			,
	input wire					rst			,
		
	input wire[`InstBus]		inst_i		,
	output wire[`InstAddrBus]	inst_addr_o	,
	
	//访存相关
	output wire[3:0]			ex_mem_wen_o		, //Write(S类指令)
	output wire[`MemBus]		ex_mem_wdata_o		,
	output wire[`MemAddrBus]	ex_mem_waddr_o		,
	
	input wire[`MemBus]			mem_rdata_i			,
	output wire					id_mem_ren_o		,
	output wire[`MemAddrBus]	id_mem_raddr_o	
);
	
	// pc_reg模块的输出信号
	wire[`InstAddrBus]			pc_reg_o			;
	
	// if_id模块的输出信号
	wire[`InstAddrBus]			ifid_inst_addr_o	;
	wire[`InstBus]				ifid_inst_o			;
		
	// id模块输出信号	
	wire[`RegAddrBus]			id_raddr1_o			;
	wire[`RegAddrBus]			id_raddr2_o			;
	wire[`RegBus]				id_op1_o			;
	wire[`RegBus]				id_op2_o			;
	wire[`InstBus]				id_inst_o			;
	wire[`InstAddrBus]			id_inst_addr_o		;
	wire[`RegBus]				id_rdata1_o			;
	wire[`RegBus]				id_rdata2_o			;
	wire						id_wen_o			;
	wire[`RegAddrBus]			id_waddr_o			;
	
	// id_ex模块输出信号
	wire[`RegBus]				idex_op1_o			;
	wire[`RegBus]				idex_op2_o			;
	wire[`InstBus]				idex_inst_o			;
	wire[`InstAddrBus]			idex_inst_addr_o	;
	wire[`RegBus]				idex_rdata1_o		;
	wire[`RegBus]				idex_rdata2_o		;
	wire						idex_wen_o			;
	wire[`RegAddrBus]			idex_waddr_o		;	
	
	// regs模块输出信号
	wire[`RegBus]				regs_rdata1_o		;
	wire[`RegBus]				regs_rdata2_o		;
		
	// ex模块输出信号	
	wire[`RegBus]				ex_wdata_o			;
	wire[`RegAddrBus]			ex_waddr_o			;
	wire						ex_wen_o			;
	wire						ex_jump_flag_o		;
	wire[`InstAddrBus]			ex_jump_addr_o		;
	wire						ex_hold_flag_o		;
	wire						ex_div_start_o		;
	wire[`RegAddrBus]			ex_div_regw_addr_o	;
	wire[`RegBus]				ex_dividend_o		;
	wire[`RegBus]				ex_divisor_o		;
	wire[2:0]					ex_div_op_o			;
	
		
	// ctrl模块输出信号	
	wire						ctrl_jump_flag_o	;
	wire[`InstAddrBus]			ctrl_jump_addr_o	;
	wire						ctrl_hold_flag_o	;
	
	// div模块输出信号
	wire[`RegAddrBus]			div_reg_waddr_o		;
	wire[`RegBus]				div_res_o			;
	wire						div_ready_o			;
	wire						div_busy_o			;
	
	
	//my_core模块输出的指令地址
	assign inst_addr_o = pc_reg_o					;
	
	
	// pc_reg
	pc_reg unit_pc_reg
	(
		.clk			(clk)				,
		.rst			(rst)				,
		.jump_flag_i	(ctrl_jump_flag_o)	,
		.jump_addr_i	(ctrl_jump_addr_o)	,
		.hold_flag_i	(ctrl_hold_flag_o)	,

		.pc_o		    (pc_reg_o)
	);



	//if_id
	if_id unit_if_id
	(
		.clk			(clk)				,
		.rst			(rst)				,
	
		.inst_addr_i	(pc_reg_o)			,	
		.inst_i			(inst_i)			,   
		
		.hold_flag_i	(ctrl_hold_flag_o)	,
	
		.inst_addr_o	(ifid_inst_addr_o)	,
		.inst_o			(ifid_inst_o)	
	);  


	//id
	id unit_id
	(
		.rst			(rst)				,
		
		.inst_i			(ifid_inst_o)		,
		.inst_addr_i	(ifid_inst_addr_o)	,


		.reg1_rdata_i	(regs_rdata1_o)		,
		.reg2_rdata_i	(regs_rdata2_o)		,


		.reg1_raddr_o	(id_raddr1_o)		,
		.reg2_raddr_o	(id_raddr2_o)		,


		.op1_o			(id_op1_o)			, //操作数1
		.op2_o			(id_op2_o)			, //操作数2

		.reg_wen_o		(id_wen_o)			,
		.reg_w_addr_o	(id_waddr_o)		,
		
	 
		.inst_o			(id_inst_o)			,
		.inst_addr_o	(id_inst_addr_o)	,

		.reg1_rdata_o	(id_rdata1_o)		, //输出读取的寄存器数据
		.reg2_rdata_o   (id_rdata2_o)		,
		
		.mem_ren_o		(id_mem_ren_o		),
		.mem_raddr_o	(id_mem_raddr_o		)
		
		
	);

	// regs
	regs unit_regs
	(
		.clk			(clk)				,
		.rst			(rst)				,
		
		.wen_i			(ex_wen_o)			,
		.w_addr_i		(ex_waddr_o)		,
		.w_data_i		(ex_wdata_o)		,
	
		.r_addr1_i		(id_raddr1_o)		,
		.r_addr2_i		(id_raddr2_o)		,
	
		.r_data1_o		(regs_rdata1_o)		,
		.r_data2_o	    (regs_rdata2_o)		
		
	);

	// id_ex
	id_ex unit_idex
	(
		.clk			(clk)				,
		.rst			(rst)				,
			
		.inst_i			(id_inst_o)			,
		.inst_addr_i	(id_inst_addr_o)	,
		.reg_waddr_i	(id_waddr_o)		,
		.reg_wen_i		(id_wen_o)			,
		.reg1_rdata_i	(id_rdata1_o)		,
		.reg2_rdata_i	(id_rdata2_o)		,
		.op1_i			(id_op1_o)			,
		.op2_i			(id_op2_o)			,
		
		.hold_flag_i	(ctrl_hold_flag_o)	,

		.inst_o			(idex_inst_o)		,
		.inst_addr_o	(idex_inst_addr_o)	,
		.reg_waddr_o	(idex_waddr_o)		,
		.reg_wen_o		(idex_wen_o)		,
		.reg1_rdata_o	(idex_rdata1_o)		,
		.reg2_rdata_o	(idex_rdata2_o)		,
		.op1_o			(idex_op1_o)		,
		.op2_o		    (idex_op2_o)
	);

	// ex
	ex unit_ex
	(
		.rst			(rst)				,

		.inst_i			(idex_inst_o)		,
		.inst_addr_i	(idex_inst_addr_o)	,

		.op1_i			(idex_op1_o)		,
		.op2_i			(idex_op2_o)		,

		.reg1_rdata_i	(idex_rdata1_o)		,
		.reg2_rdata_i	(idex_rdata2_o)		,

		.reg_waddr_i	(idex_waddr_o)		,
		.reg_wen_i		(idex_wen_o)		,
		
			//from div
		.div_ready_i	(div_ready_o)		,
		.div_res_i		(div_res_o)			,
		.div_busy_i		(div_busy_o)		,
		.div_reg_waddr_i(div_reg_waddr_o)	,

		.div_start_o	(ex_div_start_o)	,
		.div_reg_waddr_o(ex_div_regw_addr_o),
		.div_op_o		(ex_div_op_o)		,
		.div_dividend_o	(ex_dividend_o)		,
		.div_divisor_o  (ex_divisor_o)		,

		.reg_wdata_o 	(ex_wdata_o)		, 
		.reg_waddr_o 	(ex_waddr_o)		,
		.reg_wen_o	    (ex_wen_o)			,
		
	
		.mem_wen_o		(ex_mem_wen_o  )	, 
		.mem_wdata_o	(ex_mem_wdata_o)	,
		.mem_waddr_o	(ex_mem_waddr_o)	,
		
		.mem_rdata_i	(mem_rdata_i)		,
		

		.jump_flag_o	(ex_jump_flag_o)	,
		.jump_addr_o 	(ex_jump_addr_o)	, 
		.hold_flag_o	(ex_hold_flag_o)
	);
	
	//ctrl
	ctrl unit_ctrl
	(
		.rst			(rst)				,
		.jump_flag_i	(ex_jump_flag_o)	,
		.jump_addr_i	(ex_jump_addr_o)	,
		.hold_flag_i	(ex_hold_flag_o)	,

		.jump_flag_o	(ctrl_jump_flag_o)	,
		.jump_addr_o	(ctrl_jump_addr_o)	,
		.hold_flag_o    (ctrl_hold_flag_o)
	);
	
	//div
	div unit_div
(
	.clk				(clk			),
	.rst				(rst			),

	.dividend_i			(ex_dividend_o	),
	.divisor_i			(ex_divisor_o	),
	.op_i				(ex_div_op_o	),
	.reg_waddr_i		(ex_div_regw_addr_o),
	.start_i			(ex_div_start_o	),

	.reg_waddr_o		(div_reg_waddr_o),
	.div_res_o			(div_res_o		),
	.ready_o			(div_ready_o	),
	.busy_o             (div_busy_o		)
);
	
endmodule 