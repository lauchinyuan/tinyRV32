`include "defines.v"
module ex
(
	input wire 					rst				,
	
	//from id_ex		
	input wire[`InstBus]		inst_i			,
	input wire[`InstAddrBus]	inst_addr_i		,
	
	input wire[`RegBus]			op1_i			,
	input wire[`RegBus]			op2_i			,
		
	input wire[`RegBus]			reg1_rdata_i	,
	input wire[`RegBus]			reg2_rdata_i	,
		
	input wire[`RegAddrBus]		reg_waddr_i		,
	input wire 					reg_wen_i		,
	
	output reg[`RegBus]			reg_wdata_o 	, //写回regs的数据
	output reg[`RegAddrBus]		reg_waddr_o 	,
	output reg					reg_wen_o		,
	
	//访存相关
	output reg[3:0]				mem_wen_o		, //Write(S类指令)
	output reg[`MemBus]			mem_wdata_o		,
	output reg[`MemAddrBus]		mem_waddr_o		,
	
	input wire[`MemBus]			mem_rdata_i		,
	
	//跳转相关		
	output reg					jump_flag_o		,
	output reg[`InstAddrBus]	jump_addr_o 	, 
	output reg					hold_flag_o		
	
);

	wire[6:0] opcode	;   //问题，这一个工作不应该在译码阶段完成吗？
	wire[4:0] rd		;
	wire[2:0] funct3	;	
	wire[4:0] rs1		;
	wire[4:0] rs2		;
	wire[6:0] funct7	;
	wire[31:0]b_imm		;
	
	
	//将指令分段
	assign opcode 	= inst_i[6:0]	;
	assign rd 		= inst_i[11:7]	;
	assign funct3	= inst_i[14:12]	;
	assign rs1 		= inst_i[19:15]	;
	assign rs2		= inst_i[24:20]	;
	assign funct7	= inst_i[31:25]	;
	
	// branch
	wire 	op1_eq_op2			;
	wire	op1_ge_op2_signed	;
	wire	op1_ge_op2_unsigned	;
	
	
	assign op1_eq_op2 = (op1_i == op2_i);
	assign op1_ge_op2_signed = $signed(op1_i) >= $signed(op2_i);
	assign op1_ge_op2_unsigned = op1_i >= op2_i	;
	
	
	//mask
	wire[`RegBus]	shift_mask;
	
	assign shift_mask = 32'hffffffff;

	
	
	//跳转指令的立即数,注意最后要补零的问题
	assign b_imm = {{19 {inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
	
	always @ (*) begin
		reg_waddr_o 	= reg_waddr_i	;
		reg_wen_o		= reg_wen_i		;
		mem_wen_o		= 4'b0000		;
		mem_waddr_o		= `ZeroWord		;
		mem_wdata_o		= op2_i			;  // S类指令的原始数据都来自op2_i
		case(opcode)
			`INST_TYPE_I: begin
				case(funct3)
					`INST_ADDI: begin
						reg_wdata_o = op1_i + op2_i	;  //计算数据并输出
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
					end
					
					`INST_SLTI: begin
						reg_wdata_o = {31'b0, ~op1_ge_op2_signed};
						hold_flag_o = `HoldDisable	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
					end
					
					`INST_SLTIU: begin
						reg_wdata_o = {31'b0, ~op1_ge_op2_unsigned};
						hold_flag_o = `HoldDisable	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
					end
					
					`INST_XORI: begin
						reg_wdata_o = op1_i ^ op2_i	;
						hold_flag_o = `HoldDisable	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
					end
					
					`INST_ORI: begin
						reg_wdata_o = op1_i | op2_i	;
						hold_flag_o = `HoldDisable	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
					end
					
					`INST_ANDI: begin
						reg_wdata_o = op1_i & op2_i	;
						hold_flag_o = `HoldDisable	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;	
					end
				
					`INST_SRI: begin
						if(inst_i[30] == 1'b0) begin  	//SRLI
							reg_wdata_o = op1_i >> op2_i[4:0]	;
							hold_flag_o = `HoldDisable			;
							jump_flag_o = `JumpDisable			;
							jump_addr_o = `ZeroWord				;
						end else begin					//SRAI
							reg_wdata_o = (((op1_i & shift_mask) >> op2_i[4:0])) | ({32 {(op1_i[31])}} & ~(shift_mask >> op2_i[4:0]));
							hold_flag_o = `HoldDisable	;
							jump_flag_o = `JumpDisable	;
							jump_addr_o = `ZeroWord		;
						end
					end
					
					`INST_SLLI: begin
						reg_wdata_o		= op1_i << op2_i[4:0]	;
						hold_flag_o 	= `HoldDisable			;
						jump_flag_o 	= `JumpDisable			;
						jump_addr_o 	= `ZeroWord				;
					end

					default: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
					end
				endcase
			end
			
			`INST_TYPE_R_M: begin
				case(funct3)
					`INST_ADD_SUB: begin
						if(inst_i[30] == 1'b1) begin 		//sub
							reg_wdata_o = op1_i - op2_i	;
							jump_flag_o = `JumpDisable	; 
							jump_addr_o = `ZeroWord		;
							hold_flag_o = `HoldDisable	;
						end else begin
							reg_wdata_o = op1_i + op2_i	;
							jump_flag_o = `JumpDisable	; 
							jump_addr_o = `ZeroWord		;
							hold_flag_o = `HoldDisable	;
						end
					end
					
					`INST_AND: begin
						reg_wdata_o = op1_i & op2_i		;
						hold_flag_o = `HoldDisable		;
						jump_flag_o = `JumpDisable		;
						jump_addr_o = `ZeroWord			;
					end
					
					`INST_OR: begin
						reg_wdata_o = op1_i | op2_i 	;
						hold_flag_o = `HoldDisable		;
						jump_flag_o = `JumpDisable		;
						jump_addr_o = `ZeroWord			;
					end
					
					`INST_XOR: begin
						reg_wdata_o = op1_i ^ op2_i		;
						hold_flag_o = `HoldDisable		;
						jump_flag_o = `JumpDisable		;
						jump_addr_o = `ZeroWord			;
					end
					
					`INST_SLL: begin
						reg_wdata_o = op1_i << op2_i[4:0]	;
						hold_flag_o = `HoldDisable			;
						jump_flag_o = `JumpDisable			;
						jump_addr_o = `ZeroWord				;
					end
					
					`INST_SLT: begin
						reg_wdata_o = {31'b0, ~op1_ge_op2_signed};
						hold_flag_o = `HoldDisable			;
						jump_flag_o = `JumpDisable			;
						jump_addr_o = `ZeroWord				;
					end
					
					`INST_SLTU: begin
						reg_wdata_o = {31'b0, ~op1_ge_op2_unsigned};
						hold_flag_o = `HoldDisable			;
						jump_flag_o = `JumpDisable			;
						jump_addr_o = `ZeroWord				;
					end
					
					`INST_SR: begin
						if(inst_i[30] == 1'b0) begin  //srl
							reg_wdata_o = op1_i >> op2_i[4:0]	;
							hold_flag_o = `HoldDisable			;
							jump_flag_o = `JumpDisable			;
							jump_addr_o = `ZeroWord				;
						end else begin				//sra
							reg_wdata_o = ((op1_i & shift_mask) >> op2_i[4:0]) | ({32 {op1_i[31]}} & ~(shift_mask >> op2_i[4:0]));
							hold_flag_o = `HoldDisable			;
							jump_flag_o = `JumpDisable			;
							jump_addr_o = `ZeroWord				;
						end
					end
					
					default: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;						
					end
				endcase
			end

			`INST_TYPE_B: begin  // jump 和 hold 有什么不同？
				case(funct3)
					`INST_BEQ: begin
						reg_wdata_o = `ZeroWord						;
						jump_flag_o = `JumpEnable & op1_eq_op2		;  // jump if equal
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(op1_eq_op2)}}; 
						hold_flag_o = `HoldEnable & op1_eq_op2;
					end
					`INST_BNE: begin
						reg_wdata_o = `ZeroWord				;
						jump_flag_o =  `JumpEnable & (~op1_eq_op2);  // jump if not equal
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(~op1_eq_op2)}}; 
						hold_flag_o = `HoldEnable & (~op1_eq_op2);	
					end 
					`INST_BLT: begin
						reg_wdata_o = `ZeroWord		;
						hold_flag_o = `HoldEnable & (~op1_ge_op2_signed);
						jump_flag_o = ~op1_ge_op2_signed;
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(~op1_ge_op2_signed)}};
					end
					`INST_BGE: begin
						reg_wdata_o = `ZeroWord		;
						hold_flag_o = `HoldEnable & op1_ge_op2_signed;
						jump_flag_o = `JumpEnable & op1_ge_op2_signed;
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(op1_ge_op2_signed)}};
					end
					`INST_BLTU: begin
						reg_wdata_o = `ZeroWord		;
						hold_flag_o = `HoldEnable & (~op1_ge_op2_unsigned);
						jump_flag_o = `JumpEnable & (~op1_ge_op2_unsigned);
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(~op1_ge_op2_unsigned)}};
					end
					`INST_BGEU: begin
						reg_wdata_o = `ZeroWord		;
						hold_flag_o = `HoldEnable & (op1_ge_op2_unsigned);
						jump_flag_o = `JumpEnable & (op1_ge_op2_unsigned);
						jump_addr_o = (inst_addr_i + b_imm) & {32 {(op1_ge_op2_unsigned)}};						
					end
					
					default: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;					
					end
				endcase
			end
			
			`INST_TYPE_S: begin
				case(funct3)
					`INST_SW: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
						mem_wen_o	= 4'b1111		;
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
					end
					`INST_SH: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
						mem_wen_o	= 4'b0011		;
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
					end
					`INST_SB: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
						mem_wen_o	= 4'b0001		;
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
					end
					default: begin
						reg_wdata_o = `ZeroWord		;
						jump_flag_o = `JumpDisable	; 
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;						
					end
				endcase
			end
			
			`INST_TYPE_L: begin
				case(funct3)
					`INST_LW: begin
						reg_wdata_o = mem_rdata_i	;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;
					end
					`INST_LH: begin
						reg_wdata_o = {{16 {(mem_rdata_i[15])}},mem_rdata_i[15:0]};
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;						
					end
					`INST_LB: begin
						reg_wdata_o = {{24 {(mem_rdata_i[7])}},mem_rdata_i[7:0]};
						//reg_wdata_o = 32'haaaa;
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;						
					end			
					`INST_LHU: begin
						reg_wdata_o = mem_rdata_i[15:0];
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;							
					end
					`INST_LBU: begin
						reg_wdata_o = mem_rdata_i[7:0];
						jump_flag_o = `JumpDisable	;
						jump_addr_o = `ZeroWord		;
						hold_flag_o = `HoldDisable	;						
					end
				endcase
			end
			
			`INST_JAL: begin  // 无条件跳转
				reg_wdata_o = inst_addr_i + 32'd4	; //pc+4
				jump_flag_o = `JumpEnable			;
				jump_addr_o = inst_addr_i + op1_i	;
				hold_flag_o = `HoldEnable			;
			end
			
			`INST_JALR: begin
				reg_wdata_o = inst_addr_i + 32'd4	;
				jump_flag_o = `JumpEnable			;
				jump_addr_o = op1_i + op2_i 		;
				hold_flag_o = `HoldEnable			;
			end
			
			`INST_AUIPC: begin
				reg_wdata_o = op1_i + inst_addr_i	;
				jump_flag_o = `JumpDisable			;
				jump_addr_o = `ZeroWord				;
				hold_flag_o = `HoldDisable			;
			end
			
			`INST_LUI: begin
				reg_wdata_o = op1_i			;  //可以优化
				jump_flag_o = `JumpDisable	;
				jump_addr_o = `ZeroWord		;
				hold_flag_o = `HoldDisable	;
			end
			
			default: begin
				reg_wdata_o = `ZeroWord		;
				jump_flag_o = `JumpDisable	; 
				jump_addr_o = `ZeroWord		;
				hold_flag_o = `HoldDisable	;
			end
		endcase
	end



endmodule