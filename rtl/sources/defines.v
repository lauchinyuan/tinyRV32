//处理器参数设定

`define Rst				1'b0
`define RstDisable		1'b1

`define CpuResetAddr	32'b0	

`define InstAddrBus 	31:0	//指令地址总线
`define InstBus			31:0	//指令内容总线

// dual_ram
`define RamBus			31:0
`define RamAddrBus		11:0

//mem
`define MemBus			31:0
`define MemAddrBus		31:0


//hold_flag
`define HoldFlagBus		2:0
`define HoldNone 		3'b000
`define HoldPc   		3'b001
`define HoldIf   		3'b010
`define HoldId   		3'b011

//jump_flag
`define JumpEnable		1'b1
`define JumpDisable		1'b0
`define HoldEnable		1'b1
`define HoldDisable		1'b0

//regs
`define RegBus			31:0	//通用寄存器数据总线
`define RegAddrBus		4:0		//通用寄存器地址总线
`define RegNum			32		//通用寄存器个数
`define WriteEnable		1'b1	//写使能标志
`define WriteDisable	1'b0	//写不使能
`define ZeroReg			5'h0	//零号寄存器
`define ZeroWord		32'b0   
`define ReadEnable 		1'b1
`define ReadDisable		1'b0


//inst
`define Inst_NOP		32'h0000_0013

//I-type 
`define INST_TYPE_I 	7'b0010011
`define INST_ADDI   	3'b000
`define INST_SLTI   	3'b010
`define INST_SLTIU  	3'b011
`define INST_XORI   	3'b100
`define INST_ORI    	3'b110
`define INST_ANDI   	3'b111
`define INST_SLLI   	3'b001
`define INST_SRI    	3'b101



//I-L-type
`define INST_TYPE_L 	7'b0000011
`define INST_LB     	3'b000
`define INST_LH     	3'b001
`define INST_LW     	3'b010
`define INST_LBU    	3'b100
`define INST_LHU    	3'b101

//S-type
`define INST_TYPE_S		7'b0100011
`define INST_SB    		3'b000
`define INST_SH    		3'b001
`define INST_SW    		3'b010

//R-type
//注意，M-type没有实现
`define INST_TYPE_R_M 	7'b0110011
`define INST_ADD_SUB 	3'b000
`define INST_SLL    	3'b001
`define INST_SLT    	3'b010
`define INST_SLTU   	3'b011
`define INST_XOR    	3'b100
`define INST_SR     	3'b101
`define INST_OR     	3'b110
`define INST_AND    	3'b111


`define INST_AND_7		7'b000000
// M type inst
`define INST_MUL    	3'b000
`define INST_MULH   	3'b001
`define INST_MULHSU 	3'b010
`define INST_MULHU  	3'b011
`define INST_DIV    	3'b100
`define INST_DIVU   	3'b101
`define INST_REM    	3'b110
`define INST_REMU   	3'b111

// J-type
`define INST_JAL    	7'b1101111
`define INST_JALR   	7'b1100111

// B-type
`define INST_TYPE_B 	7'b1100011
`define INST_BEQ    	3'b000
`define INST_BNE    	3'b001
`define INST_BLT    	3'b100
`define INST_BGE    	3'b101
`define INST_BLTU   	3'b110
`define INST_BGEU   	3'b111

// U-type
`define INST_LUI    	7'b0110111
`define INST_AUIPC  	7'b0010111


