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
	
	//from div
	input wire					div_ready_i		,
	input wire[`RegBus]			div_res_i		,
	input wire					div_busy_i		,
	input wire[`RegAddrBus]		div_reg_waddr_i	,
	
	//to div
	output reg					div_start_o		,
	output reg[`RegAddrBus]		div_reg_waddr_o	,
	output reg[2:0]				div_op_o		,
	output reg[`RegBus]			div_dividend_o	,
	output reg[`RegBus]			div_divisor_o   ,
	
	output wire[`RegBus]		reg_wdata_o 	, //写回regs的数据
	output wire[`RegAddrBus]	reg_waddr_o 	,
	output wire					reg_wen_o		,
	
	//访存相关
	output reg[3:0]				mem_wen_o		, //Write(S类指令)
	output reg[`MemBus]			mem_wdata_o		,
	output reg[`MemAddrBus]		mem_waddr_o		,
	
	input wire[`MemBus]			mem_rdata_i		,
	
	//跳转相关		
	output wire					jump_flag_o		,
	output wire[`InstAddrBus]	jump_addr_o 	, 
	output wire					hold_flag_o		
	
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
	

	
	
	
	
	//ALU
	wire[`RegBus] op1_add_op2			;
	wire[`RegBus] op1_and_op2			;
	wire[`RegBus] op1_or_op2			;
	wire[`RegBus] op1_xor_op2			;
	wire[31:0] 	  base1_add_ofset3120	;
	wire[31:0]	  base1_add_ofset31257	;
	wire[`InstAddrBus] hold_jump_addr	;   //除法、求余运算暂停后的下一条执行指令的地址
	assign op1_add_op2 = op1_i + op2_i ;    //加法
	assign op1_and_op2 = op1_i & op2_i ;    //与
	assign op1_or_op2  = op1_i | op2_i ;    //或
	assign op1_xor_op2 = op1_i ^ op2_i ;    //异或
	// 以rs1寄存器的值为基地址，加上符号扩展的位于指令[31:20]的12位立即数作为偏移地址
	assign base1_add_ofset3120 = reg1_rdata_i + {{20{inst_i[31]}},inst_i[31:20]};  
	// 以rs1寄存器的值为基地址，加上符号扩展的位于指令[31:25]以及[11:7]的12位立即数作为偏移地址
	assign base1_add_ofset31257 = reg1_rdata_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
	assign hold_jump_addr = inst_addr_i + 32'd4;
	
	//mask
	wire[`RegBus]	shift_mask;
	
	assign shift_mask = 32'hffffffff;

	// Load and Store
	wire[1:0] ld_idx;   //用于指定Load操作数据所在字节位置的索引
	wire[1:0] st_idx;	//用于指定Store操作数据所在字节位置的索引
	assign ld_idx = base1_add_ofset3120[1:0];
	assign st_idx = base1_add_ofset31257[1:0];
	
	assign b_imm = {{19 {inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
	
	//乘法相关
	reg[`RegBus] mul_op1; // 乘法操作数1
	reg[`RegBus] mul_op2; // 乘法操作数2
	wire[64:0]	  mul_res;
	wire[64:0]	  mul_res_inv; // mul_res按位取反，末位加1
	wire[`RegBus] reg1_rdata_inv; // reg1数据取反加1，用于有符号乘法指令
	wire[`RegBus] reg2_rdata_inv; // reg2数据取反加1
	assign mul_res = mul_op1 * mul_op2;
	assign mul_res_inv = ~mul_res_inv + 1;
	assign reg1_rdata_inv = ~reg1_rdata_i + 1;
	assign reg2_rdata_inv = ~reg2_rdata_i + 1;
	
	//除法相关
	reg[`InstAddrBus] 	div_jump_addr;
	reg					div_jump_flag;
	reg					div_hold_flag;
	reg[`RegBus]		div_wdata	 ; 
	reg[`RegAddrBus]  	div_waddr	 ;
	reg					div_wen		 ; 
	
	
	//为除法器设计的二选一数据通路
	//jump and hold
	reg[`InstAddrBus] 	jump_addr	;
	reg					jump_flag	;
	reg					hold_flag	;
	
	assign jump_addr_o = (div_jump_addr | jump_addr); //跳转的来源分为除法器的来源和普通来源
	assign jump_flag_o = jump_flag | div_jump_flag;
	assign hold_flag_o = hold_flag | div_hold_flag;
	
	//reg write
	reg[`RegAddrBus] 	reg_waddr	;
	reg[`RegBus]		reg_wdata	;
	reg					reg_wen		;
	
	assign reg_waddr_o = reg_waddr | div_waddr	;
	assign reg_wdata_o = reg_wdata | div_wdata	;
	assign reg_wen_o   = reg_wen|div_wen		;
	
	// 处理乘法指令，决定mul_op1和mul_op2
	always @ (*) begin
		if((opcode == `INST_TYPE_R_M) && (funct7 == `INST_TYPE_M_7)) begin
			case(funct3)
				`INST_MUL, `INST_MULHU: begin  //无符号乘法的高位Word直接由操作数相乘得到
					mul_op1 = op1_i;
					mul_op2 = op2_i;
				end
				`INST_MULH: begin
				//若有有符号负数,则取相反数进行计算
					mul_op1 = (op1_i[31] == 1'b1)? (reg1_rdata_inv):(op1_i);  
					mul_op2 = (op2_i[31] == 1'b1)? (reg2_rdata_inv):(op2_i);
				end
				`INST_MULHSU: begin
				//有符号数和无符号数相乘, 规定op1为有符号数
					mul_op1 = (op1_i[31] == 1'b1)? (reg1_rdata_inv):(op1_i);
					mul_op2 = op2_i;
				end
				default: begin
					mul_op1 = op1_i;
					mul_op2 = op1_i;
				end
			endcase
		end else begin
			mul_op1 = op1_i;
			mul_op2 = op2_i;
		end
	end
	
	// 处理除法指令
	always @ (*) begin
		div_dividend_o	= reg1_rdata_i	;
		div_divisor_o 	= reg2_rdata_i	;
		div_op_o		= funct3		;
		div_reg_waddr_o = reg_waddr_i	;
		if((opcode == `INST_TYPE_R_M) && (funct7 == `INST_TYPE_M_7)) begin
			div_wen = `WriteDisable		;  //第一次进入指令，暂时无需写目的寄存器
			div_waddr = `ZeroReg		;
			div_wdata = `ZeroWord		;
			case(funct3)
				`INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
					div_start_o = `DivStart		;
					div_jump_addr = hold_jump_addr;
					div_jump_flag = `JumpEnable	;
					div_hold_flag = `HoldEnable	;
				end
				default: begin
					div_start_o = `DivStop		; //其他同类指令无需进行除法操作
					div_jump_addr = `ZeroWord	;
					div_jump_flag = `JumpDisable;
					div_hold_flag = `HoldDisable;
				end
			endcase
		end else begin   //不是M类指令，但需要注意，此时可能是NoP指令（可能除法正在进行）
			div_jump_flag = `JumpDisable	;  // 无需再次跳转，但有可能需要hold(在长周期指令进行时)
			div_jump_addr = `ZeroWord		;
			if(div_busy_i == `DivBusy) begin     //正在计算
				div_hold_flag = `HoldEnable	;
				div_start_o = `DivStart		;
				div_waddr = `ZeroReg		;
				div_wdata = `ZeroWord		;
				div_wen	  = `WriteDisable	;
			end else begin
				div_hold_flag = `HoldDisable;
				div_start_o   = `DivStop	;
				if(div_ready_i == `DivReady) begin  //不再busy，数据准备完成
					div_wdata = div_res_i ; 
					div_waddr = div_reg_waddr_i;
					div_wen	  = `WriteEnable;
				end else begin
					div_wdata = `ZeroWord	;   //不busy，也没有数据准备，非计算除法求余指令的情况
					div_waddr = `ZeroReg	;
					div_wen	  = `WriteDisable;
				end
				
			end
		end
	
	end
	
	//执行
	always @ (*) begin
		reg_waddr 		= reg_waddr_i	;
		reg_wen			= reg_wen_i		;
		mem_wen_o		= 4'b0000		;
		mem_waddr_o		= `ZeroWord		;
		case(opcode)
			`INST_TYPE_I: begin
				case(funct3)
					`INST_ADDI: begin
						reg_wdata = op1_add_op2	;  //计算数据并输出
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;
					end
					
					`INST_SLTI: begin
						reg_wdata = {31'b0, ~op1_ge_op2_signed};
						hold_flag	 = `HoldDisable	;
						jump_flag	 = `JumpDisable	;
						jump_addr	 = `ZeroWord	;
					end
					
					`INST_SLTIU: begin
						reg_wdata = {31'b0, ~op1_ge_op2_unsigned};
						hold_flag	 = `HoldDisable		;
						jump_flag	 = `JumpDisable		;
						jump_addr	 = `ZeroWord		;
					end
					
					`INST_XORI: begin
						reg_wdata = op1_xor_op2	;
						hold_flag = `HoldDisable	;
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
					end
					
					`INST_ORI: begin
						reg_wdata = op1_or_op2	;
						hold_flag = `HoldDisable	;
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
					end
					
					`INST_ANDI: begin
						reg_wdata = op1_add_op2	;
						hold_flag = `HoldDisable	;
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;	
					end
				
					`INST_SRI: begin
						if(inst_i[30] == 1'b0) begin  	//SRLI
							reg_wdata = op1_i >> op2_i[4:0]	;
							hold_flag	 = `HoldDisable			;
							jump_flag	 = `JumpDisable			;
							jump_addr	 = `ZeroWord			;
						end else begin					//SRAI
							reg_wdata = (((op1_i & shift_mask) >> op2_i[4:0])) | ({32 {(op1_i[31])}} & ~(shift_mask >> op2_i[4:0]));
							hold_flag	 = `HoldDisable		;
							jump_flag	 = `JumpDisable		;
							jump_addr	 = `ZeroWord		;
						end
					end
					
					`INST_SLLI: begin
						reg_wdata		= op1_i << op2_i[4:0]	;
						hold_flag	 	= `HoldDisable			;
						jump_flag	 	= `JumpDisable			;
						jump_addr	 	= `ZeroWord				;
					end

					default: begin
						reg_wdata = `ZeroWord		;
						jump_flag	 = `JumpDisable	; 
						jump_addr	 = `ZeroWord	;
						hold_flag	 = `HoldDisable	;
					end
				endcase
			end
			
			`INST_TYPE_R_M: begin
				case(funct7)
					`INST_R_7 ,`INST_SUB_SRA_7: begin
						case(funct3)
						`INST_ADD_SUB: begin
							if(inst_i[30] == 1'b1) begin 		//sub
								reg_wdata = op1_i - op2_i	;
								jump_flag = `JumpDisable	; 
								jump_addr = `ZeroWord		;
								hold_flag = `HoldDisable	;
							end else begin
								reg_wdata = op1_i + op2_i	;
								jump_flag	 = `JumpDisable	; 
								jump_addr	 = `ZeroWord	;
								hold_flag	 = `HoldDisable	;
							end
						end
						
						`INST_AND: begin
							reg_wdata = op1_i & op2_i		;
							hold_flag	 = `HoldDisable		;
							jump_flag	 = `JumpDisable		;
							jump_addr	 = `ZeroWord		;
						end
						
						`INST_OR: begin
							reg_wdata = op1_i | op2_i 	;
							hold_flag = `HoldDisable		;
							jump_flag = `JumpDisable		;
							jump_addr = `ZeroWord			;
						end
						
						`INST_XOR: begin
							reg_wdata = op1_i ^ op2_i		;
							hold_flag	 = `HoldDisable		;
							jump_flag	 = `JumpDisable		;
							jump_addr	 = `ZeroWord		;
						end
						
						`INST_SLL: begin
							reg_wdata = op1_i << op2_i[4:0]	;
							hold_flag = `HoldDisable			;
							jump_flag = `JumpDisable			;
							jump_addr = `ZeroWord				;
						end
						
						`INST_SLT: begin
							reg_wdata = {31'b0, ~op1_ge_op2_signed};
							hold_flag = `HoldDisable			;
							jump_flag = `JumpDisable			;
							jump_addr = `ZeroWord				;
						end
						
						`INST_SLTU: begin
							reg_wdata = {31'b0, ~op1_ge_op2_unsigned};
							hold_flag = `HoldDisable			;
							jump_flag = `JumpDisable			;
							jump_addr = `ZeroWord				;
						end
						
						`INST_SR: begin
							if(inst_i[30] == 1'b0) begin  //srl
								reg_wdata = op1_i >> op2_i[4:0]	;
								hold_flag = `HoldDisable			;
								jump_flag = `JumpDisable			;
								jump_addr = `ZeroWord				;
							end else begin				//sra
								reg_wdata = ((op1_i & shift_mask) >> op2_i[4:0]) | ({32 {op1_i[31]}} & ~(shift_mask >> op2_i[4:0]));
								hold_flag = `HoldDisable			;
								jump_flag = `JumpDisable			;
								jump_addr = `ZeroWord				;
							end
						end
						
						default: begin
							reg_wdata = `ZeroWord		;
							jump_flag = `JumpDisable	; 
							jump_addr = `ZeroWord		;
							hold_flag = `HoldDisable	;						
						end
						endcase
					end
					
					`INST_TYPE_M_7: begin
						case(funct3)
							`INST_MUL: begin
								reg_wdata = mul_res[31:0]	;
								jump_flag = `JumpDisable	;
								jump_addr = `ZeroWord		;
								hold_flag = `HoldDisable	;
							end
							`INST_MULHU: begin
								reg_wdata = mul_res[63:32];
								jump_flag = `JumpDisable;
								jump_addr = `ZeroWord;
								hold_flag = `HoldDisable;
							end
							`INST_MULHSU: begin
								reg_wdata = (reg1_rdata_i[31] == 1'b1)? mul_res_inv[63:32]:mul_res[63:32];
								jump_flag = `JumpDisable;
								jump_addr = `ZeroWord;
								hold_flag = `HoldDisable;
							end
							`INST_MULH: begin
								jump_flag = `JumpDisable	;
								jump_addr = `ZeroWord		;
								hold_flag = `HoldDisable	;
								case({reg1_rdata_i[31], reg2_rdata_i[31]})
									2'b00,2'b11: begin
										reg_wdata = mul_res[63:32];
									end
									default: begin
										reg_wdata = mul_res_inv[63:32];
									end
								endcase
							end
							default: begin
								reg_wdata = `ZeroWord	;
								jump_flag = `JumpDisable;
								jump_addr = `ZeroWord	;
								hold_flag = `HoldDisable;
							end
						endcase
					end
				endcase
			end

			`INST_TYPE_B: begin  // jump 和 hold 有什么不同？
				case(funct3)
					`INST_BEQ: begin
						reg_wdata = `ZeroWord						;
						jump_flag	 = `JumpEnable & op1_eq_op2		;  // jump if equal
						jump_addr	 = (inst_addr_i + b_imm) & {32 {(op1_eq_op2)}}; 
						hold_flag	 = `HoldEnable & op1_eq_op2;
					end
					`INST_BNE: begin
						reg_wdata	 = `ZeroWord				;
						jump_flag	 =  `JumpEnable & (~op1_eq_op2);  // jump if not equal
						jump_addr	 = (inst_addr_i + b_imm) & {32 {(~op1_eq_op2)}}; 
						hold_flag	 = `HoldEnable & (~op1_eq_op2);	
					end 
					`INST_BLT: begin
						reg_wdata = `ZeroWord		;
						hold_flag = `HoldEnable & (~op1_ge_op2_signed);
						jump_flag = ~op1_ge_op2_signed;
						jump_addr = (inst_addr_i + b_imm) & {32 {(~op1_ge_op2_signed)}};
					end
					`INST_BGE: begin
						reg_wdata = `ZeroWord		;
						hold_flag = `HoldEnable & op1_ge_op2_signed;
						jump_flag = `JumpEnable & op1_ge_op2_signed;
						jump_addr = (inst_addr_i + b_imm) & {32 {(op1_ge_op2_signed)}};
					end
					`INST_BLTU: begin
						reg_wdata = `ZeroWord		;
						hold_flag = `HoldEnable & (~op1_ge_op2_unsigned);
						jump_flag = `JumpEnable & (~op1_ge_op2_unsigned);
						jump_addr = (inst_addr_i + b_imm) & {32 {(~op1_ge_op2_unsigned)}};
					end
					`INST_BGEU: begin
						reg_wdata = `ZeroWord		;
						hold_flag = `HoldEnable & (op1_ge_op2_unsigned);
						jump_flag = `JumpEnable & (op1_ge_op2_unsigned);
						jump_addr = (inst_addr_i + b_imm) & {32 {(op1_ge_op2_unsigned)}};						
					end
					
					default: begin
						reg_wdata = `ZeroWord		;
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;					
					end
				endcase
			end
			
			`INST_TYPE_S: begin
				case(funct3)
					`INST_SW: begin
						reg_wdata = `ZeroWord		;
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;
						mem_wen_o	= 4'b1111		;
						mem_wdata_o	= op2_i			;  
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
					end
					`INST_SH: begin
						reg_wdata = `ZeroWord		;
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]}; //改
						case(st_idx[1])
							1'b0: begin
								mem_wen_o	= 4'b0011;
								mem_wdata_o	= {16'b0, op2_i[15:0]};  
							end
							1'b1: begin
								mem_wen_o = 4'b1100	;
								mem_wdata_o = {op2_i[15:0],16'b0};
 							end
							default: begin
								mem_wen_o = 4'b0000	;
								mem_wdata_o = `ZeroWord	;
							end
						endcase

					end
					`INST_SB: begin
						reg_wdata = `ZeroWord		;
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;
						mem_waddr_o = op1_i + {{20 {(inst_i[31])}},inst_i[31:25],inst_i[11:7]};
						case(st_idx)
							2'b00: begin
								mem_wen_o = 4'b0001;
								mem_wdata_o = {24'b0, op2_i[7:0]};
							end
							2'b01: begin
								mem_wen_o = 4'b0010;
								mem_wdata_o = {16'b0, op2_i[7:0], 8'b0};								
							end
							2'b10: begin
								mem_wen_o = 4'b0100;
								mem_wdata_o = {8'b0, op2_i[7:0], 16'b0};
							end
							2'b11: begin
								mem_wen_o = 4'b1000;
								mem_wdata_o = {op2_i[7:0], 24'b0};
							end
							default: begin
								mem_wen_o = 4'b0000;
								mem_wdata_o = `ZeroWord;
							end
						endcase
					end
					default: begin
						reg_wdata = `ZeroWord		;
						jump_flag = `JumpDisable	; 
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;						
					end
				endcase
			end
			
			`INST_TYPE_L: begin
				case(funct3)
					`INST_LW: begin
						reg_wdata = mem_rdata_i	;
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;
					end
					`INST_LH: begin
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;			
						case(ld_idx[1])
							1'b0: begin
								reg_wdata = {{16{mem_rdata_i[15]}}, mem_rdata_i[15:0]};
							end
							1'b1: begin
								reg_wdata = {{16{mem_rdata_i[31]}}, mem_rdata_i[31:16]};
							end
							default: begin
								reg_wdata = `ZeroWord;
							end
						endcase						
					end
					`INST_LB: begin
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;	
						case(ld_idx)
							2'b00: begin
								reg_wdata = {{24 {(mem_rdata_i[7])}},mem_rdata_i[7:0]};
							end
							2'b01: begin
								reg_wdata = {{24 {(mem_rdata_i[15])}},mem_rdata_i[15:8]};
							end
							2'b10: begin
								reg_wdata = {{24 {(mem_rdata_i[23])}},mem_rdata_i[23:16]};
							end
							2'b11: begin
								reg_wdata = {{24 {(mem_rdata_i[31])}},mem_rdata_i[31:24]};
							end			
							default: begin
								reg_wdata = `ZeroWord;
							end
						endcase
					end			
					`INST_LHU: begin
						reg_wdata = mem_rdata_i[15:0];
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;							
					end
					`INST_LBU: begin
						reg_wdata = mem_rdata_i[7:0];
						jump_flag = `JumpDisable	;
						jump_addr = `ZeroWord		;
						hold_flag = `HoldDisable	;						
					end
				endcase
			end
			
			`INST_JAL: begin  // 无条件跳转
				reg_wdata = inst_addr_i + 32'd4	; //pc+4
				jump_flag = `JumpEnable			;
				jump_addr = inst_addr_i + op1_i	;
				hold_flag = `HoldEnable			;
			end
			
			`INST_JALR: begin
				reg_wdata = inst_addr_i + 32'd4	;
				jump_flag = `JumpEnable			;
				jump_addr = op1_i + op2_i 		;
				hold_flag = `HoldEnable			;
			end
			
			`INST_AUIPC: begin
				reg_wdata = op1_i + inst_addr_i	;
				jump_flag = `JumpDisable			;
				jump_addr = `ZeroWord				;
				hold_flag = `HoldDisable			;
			end
			
			`INST_LUI: begin
				reg_wdata = op1_i			;  //可以优化
				jump_flag = `JumpDisable	;
				jump_addr = `ZeroWord		;
				hold_flag = `HoldDisable	;
			end
			
			default: begin
				reg_wdata = `ZeroWord		;
				jump_flag = `JumpDisable	; 
				jump_addr = `ZeroWord		;
				hold_flag = `HoldDisable	;
			end
		endcase
	end



endmodule