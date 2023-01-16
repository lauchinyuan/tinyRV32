`include "defines.v"

//对于Load类型的指令，在译码阶段就要开始读取ram，这样才能在ex模块得到数据
module id
(
	input wire					rst,
	//from if_id
	input wire	[`InstBus]		inst_i,
	input wire	[`InstAddrBus]	inst_addr_i,
	
	//from regs
	input wire [`RegBus]		reg1_rdata_i,
	input wire [`RegBus]		reg2_rdata_i,
	
	//从csr中读取的数据
	input wire[`RegBus]			csr_rdata_i	,
	
	//to regs
	output reg [`RegAddrBus]	reg1_raddr_o,
	output reg [`RegAddrBus]	reg2_raddr_o,

	
	//to ex
	output reg [`RegBus]		op1_o, //操作数1
	output reg [`RegBus]		op2_o, //操作数2
	

	output reg					reg_wen_o,
	output reg [`RegAddrBus] 	reg_w_addr_o,
	
	//to id_ex
	output reg	[`InstBus]		inst_o,
	output reg	[`InstAddrBus]	inst_addr_o,
	
	output reg	[`RegBus]		reg1_rdata_o,  //输出读取的寄存器数据
	output reg 	[`RegBus]		reg2_rdata_o,
	
	//csr
	output reg[`CSRAddrBus]		csr_raddr_o	,
	output reg					csr_wen_o	,
	output reg[`CSRAddrBus]		csr_waddr_o	,
	output reg[`RegBus]			csr_rdata_o ,
	
	
	output reg					mem_ren_o	,
	output reg[`MemAddrBus]		mem_raddr_o	
	
);
	//将指令内容进行拆分
	wire[6:0] opcode = inst_i[6:0];
	wire[4:0] rd = inst_i[11:7];
	wire[2:0] funct3 = inst_i[14:12];
	wire[4:0] rs1 = inst_i[19:15];
	wire[4:0] rs2 = inst_i[24:20];
	wire[6:0] funct7 = inst_i[31:25];
	
	
	//做测试的时候应该是一条一条指令测试
	always @ (*) begin
		inst_o = inst_i;			//输出的指令
		inst_addr_o = inst_addr_i;	//输出的指令地址
		
		reg1_rdata_o = reg1_rdata_i; 
		reg2_rdata_o = reg2_rdata_i;
		csr_rdata_o = csr_rdata_i;
		
		
		op1_o = `ZeroWord;
		op2_o = `ZeroWord;
		mem_ren_o = `ReadDisable;   //默认不读取数据存储器，只有L型指令需要读取
		mem_raddr_o = `ZeroWord	;
		csr_wen_o = `WriteDisable;
		csr_raddr_o = `ZeroWord;
		csr_waddr_o = `ZeroWord;
		
		case(opcode)
			`INST_TYPE_I: begin
				case(funct3)
					`INST_ADDI, `INST_SLTI, `INST_SLTIU, `INST_XORI, `INST_ORI, `INST_ANDI: begin
						reg1_raddr_o = rs1;  //读取寄存器1的索引为rs1
						reg2_raddr_o = `ZeroReg;  //无需读取rs2
						reg_w_addr_o = rd;
						reg_wen_o = `WriteEnable;
						op1_o = reg1_rdata_i;
						op2_o = {{20{inst_i[31]}},inst_i[31:20]};
					end
					`INST_SLLI, `INST_SRI: begin
						reg1_raddr_o = rs1		;
						reg2_raddr_o = `ZeroReg	;
						reg_w_addr_o = rd		;
						reg_wen_o	 = `WriteEnable;
						op1_o = reg1_rdata_i;
						op2_o = rs2;		//移动的位数?
					end
					
					
					default: begin
						reg1_raddr_o = `ZeroReg;  //不读(读0)
						reg2_raddr_o = `ZeroReg;  //不读(读0)
						reg_w_addr_o = `ZeroReg;
						reg_wen_o = `WriteDisable;				
					end
				endcase
			end
			
			`INST_TYPE_R_M: begin
				case(funct7) 
					`INST_R_7, `INST_SUB_SRA_7: begin
						case(funct3)
							`INST_ADD_SUB, `INST_SLL, `INST_SLT, `INST_SLTU, `INST_SR, `INST_AND, `INST_OR, `INST_XOR: begin
								reg1_raddr_o = rs1;  
								reg2_raddr_o = rs2;  
								reg_w_addr_o = rd;
								reg_wen_o = `WriteEnable;
								op1_o = reg1_rdata_i;
								op2_o = reg2_rdata_i;
							end
							
							default: begin
								reg1_raddr_o = `ZeroReg;  //不读(读0)
								reg2_raddr_o = `ZeroReg;  //不读(读0)
								reg_w_addr_o = `ZeroReg;
								reg_wen_o = `WriteDisable;				
							end
						endcase						
					end
					
					`INST_TYPE_M_7: begin
						case(funct3)
						`INST_MUL, `INST_MULH, `INST_MULHU, `INST_MULHSU: begin
							reg1_raddr_o = rs1;
							reg2_raddr_o = rs2;
							reg_wen_o = `WriteEnable;
							reg_w_addr_o = rd;
							op1_o = reg1_rdata_i;
							op2_o = reg2_rdata_i;
						end
						`INST_DIV: begin
							reg1_raddr_o = rs1;
							reg2_raddr_o = rs2;
							reg_w_addr_o = rd;
							reg_wen_o 	 = `WriteDisable;  //暂时不写，等到计算结果完成后写
						end
						default: begin
							reg1_raddr_o = `ZeroReg;
							reg2_raddr_o = `ZeroReg;
							reg_wen_o	 = `WriteDisable;
							reg_w_addr_o = `ZeroWord;
						end
						endcase
					end
					
					default: begin
						reg1_raddr_o = `ZeroReg;
						reg2_raddr_o = `ZeroReg;
						reg_w_addr_o = `ZeroReg;
						reg_wen_o = `WriteDisable;
					end
					
				
				endcase

				
			end
			
			`INST_TYPE_B: begin
				case(funct3) 
					`INST_BEQ, `INST_BNE, `INST_BLT, `INST_BGE, `INST_BLTU, `INST_BGEU: begin
						reg1_raddr_o = rs1;
						reg2_raddr_o = rs2;
						reg_w_addr_o = `ZeroReg;
						reg_wen_o = `WriteDisable;
						op1_o = reg1_rdata_i;
						op2_o = reg2_rdata_i;
					end
					
					default: begin
						reg1_raddr_o = `ZeroReg;  //不读(读0)
						reg2_raddr_o = `ZeroReg;  //不读(读0)
						reg_w_addr_o = `ZeroReg;
						reg_wen_o = `WriteDisable;
					end
				endcase
			end
			
			`INST_TYPE_S: begin
				case(funct3) 
					`INST_SB, `INST_SH, `INST_SW: begin
						reg1_raddr_o = rs1;
						reg2_raddr_o = rs2;
						reg_w_addr_o = `ZeroReg		;
						reg_wen_o 	 = `WriteDisable;
						op1_o = reg1_rdata_i		;
						op2_o = reg2_rdata_i		;  
					end
					default: begin
						reg1_raddr_o = `ZeroReg		;  //不读(读0)
						reg2_raddr_o = `ZeroReg		;  //不读(读0)
						reg_w_addr_o = `ZeroReg		;
						reg_wen_o = `WriteDisable	;						
					end
				endcase
			end
			
			`INST_TYPE_L: begin
				case(funct3)
					`INST_LB, `INST_LH, `INST_LBU, `INST_LHU, `INST_LW: begin
						reg1_raddr_o = rs1			;
						reg2_raddr_o = `ZeroReg		;
						reg_w_addr_o = rd			;
						reg_wen_o	= `WriteEnable	;
						op1_o = `ZeroWord			;
						op2_o = `ZeroWord			;
						mem_raddr_o = reg1_rdata_i + {{20{inst_i[31]}},inst_i[31:20]};
						mem_ren_o = `ReadEnable		;
					end
					
					default: begin
						reg1_raddr_o = `ZeroReg		;  
						reg2_raddr_o = `ZeroReg		;  
						reg_w_addr_o = `ZeroReg		;
						reg_wen_o = `WriteDisable	;							
					end
				endcase
			end
			
			`INST_JAL: begin
				reg1_raddr_o = `ZeroReg		;
				reg2_raddr_o = `ZeroReg		;
				reg_w_addr_o = rd			;
				reg_wen_o = `WriteEnable	;
				op1_o = {{12 {inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
				op2_o = `ZeroWord			;
				
			end
			
			`INST_JALR: begin
				reg1_raddr_o = rs1			;
				reg2_raddr_o = `ZeroReg		;
				reg_w_addr_o = rd			;
				reg_wen_o = `WriteEnable	;
				op1_o = reg1_rdata_i		;
				op2_o = {{20 {inst_i[31]}}, inst_i[31:20]};
			end
			
			`INST_AUIPC: begin
				reg1_raddr_o = `ZeroReg		;
				reg2_raddr_o = `ZeroReg		;
				reg_w_addr_o = rd			;
				reg_wen_o 	 = `WriteEnable	;
				op1_o		 = {inst_i[31:12], 12'b0};
				op2_o 		 = `ZeroWord	;
			end
			
			`INST_LUI: begin
				reg1_raddr_o = `ZeroReg		;
				reg2_raddr_o = `ZeroReg		;
				reg_w_addr_o = rd			;
				reg_wen_o 	 = `WriteEnable ;
				op1_o		 = {inst_i[31:12], 12'b0};
				op2_o		 = `ZeroWord	;
			end
			
			`INST_CSR: begin
				case(funct3) 
					`INST_CSRRW, `INST_CSRRS, `INST_CSRRC: begin
						reg1_raddr_o = rs1;
						reg2_raddr_o = `ZeroReg;
						reg_w_addr_o = rd;
						reg_wen_o	 = `WriteEnable;
						csr_wen_o = `WriteEnable;
						csr_raddr_o = {20'b0 ,inst_i[31:20]};
						csr_waddr_o = {20'b0 ,inst_i[31:20]};
					end
					
					`INST_CSRRWI, `INST_CSRRSI, `INST_CSRRCI: begin
						reg1_raddr_o = `ZeroReg;
						reg2_raddr_o = `ZeroReg;
						reg_w_addr_o = rd;
						reg_wen_o = `WriteEnable;
						csr_wen_o = `WriteEnable;
						csr_raddr_o = {20'b0 ,inst_i[31:20]};
						csr_waddr_o = {20'b0 ,inst_i[31:20]};
					end
					
					default: begin
						reg1_raddr_o = `ZeroReg;
						reg2_raddr_o = `ZeroReg;
						reg_w_addr_o = `ZeroReg;
						reg_wen_o = `WriteDisable;
						csr_wen_o = `WriteDisable;
						csr_raddr_o = `ZeroWord;
						csr_waddr_o = `ZeroWord;						
					end
				endcase
			end
			
			
			default: begin
				reg1_raddr_o = `ZeroReg; 
				reg2_raddr_o = `ZeroReg; 
				reg_w_addr_o = `ZeroReg;
				reg_wen_o = `WriteDisable;	
			end
			
		endcase
	end
endmodule 