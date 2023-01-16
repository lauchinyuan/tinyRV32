`include "defines.v"
module id_ex
(
	input wire				clk				,
	input wire				rst				,
		
	//from id	
	input wire[`InstBus] 	inst_i			,
	input wire[`InstAddrBus]inst_addr_i		,
	input wire[`RegAddrBus]	reg_waddr_i		,
	input wire				reg_wen_i		,
	input wire[`RegBus]		reg1_rdata_i	,
	input wire[`RegBus]		reg2_rdata_i	,
	input wire[`RegBus]		op1_i			,
	input wire[`RegBus]		op2_i			,

	//csr
	input wire[`CSRAddrBus]		csr_waddr_i	,
	input wire					csr_wen_i	,
	input wire[`RegBus]			csr_rdata_i	,
	
		
	//from ctrl	
	input wire				hold_flag_i		,
	
	//to ex
	output wire[`InstBus] 		inst_o			,
	output wire[`InstAddrBus]	inst_addr_o		,
	output wire[`RegAddrBus]	reg_waddr_o		,
	output wire					reg_wen_o		,
	output wire[`RegBus]		reg1_rdata_o	,
	output wire[`RegBus]		reg2_rdata_o	,
	output wire[`RegBus]		op1_o			,
	output wire[`RegBus]		op2_o			,
	
	output wire[`CSRAddrBus]	csr_waddr_o	,
	output wire					csr_wen_o	,
	output wire[`RegBus]		csr_rdata_o	
	
);

//inst
set_dff #(.DW(32)) inst_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`Inst_NOP),
	.data_in	(inst_i),
	.data_out   (inst_o)
);

set_dff #(.DW(32)) inst_addr_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(inst_addr_i),
	.data_out   (inst_addr_o)
);

set_dff #(.DW(5)) reg_waddr_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroReg),
	.data_in	(reg_waddr_i),
	.data_out   (reg_waddr_o)
);

set_dff #(.DW(1)) reg_wen_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`WriteDisable),
	.data_in	(reg_wen_i),
	.data_out   (reg_wen_o)
);

set_dff #(.DW(32)) reg1_rdata_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(reg1_rdata_i),
	.data_out   (reg1_rdata_o)
);

set_dff #(.DW(32)) reg2_rdata_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(reg2_rdata_i),
	.data_out   (reg2_rdata_o)
);

set_dff #(.DW(32)) op1_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(op1_i),
	.data_out   (op1_o)
);

set_dff #(.DW(32)) op2_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(op2_i),
	.data_out   (op2_o)
);

set_dff #(.DW(32)) csr_waddr_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(csr_waddr_i),
	.data_out   (csr_waddr_o)
);

set_dff #(.DW(32)) csr_rdata_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i),
	.set_d		(`ZeroWord),
	.data_in	(csr_rdata_i),
	.data_out   (csr_rdata_o)
);

set_dff #(.DW(1)) csr_wen_dff
(
	.clk		(clk),
	.rst		(rst),
	.hold_flag	(hold_flag_i)	,
	.set_d		(`WriteDisable)	,
	.data_in	(csr_wen_i)		,
	.data_out   (csr_wen_o)
);


endmodule 