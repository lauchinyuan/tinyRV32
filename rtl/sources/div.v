`include "defines.v"
module div
(
	input wire				clk				,
	input wire				rst				,
	
	input wire[`RegBus]		dividend_i		,
	input wire[`RegBus]		divisor_i		,
	input wire[2:0] 		op_i			,
	input wire[`RegAddrBus]	reg_waddr_i		,
	input wire				start_i			,
	
	output reg[`RegAddrBus]	reg_waddr_o		,
	output reg[`RegBus]		div_res_o		,
	output reg				ready_o			,
	output reg				busy_o
);
	//暂存操作数
	reg[`RegBus] dividend_r		;
	reg[`RegBus] divisor_r		;
	reg[2:0]	 op_r			;
	reg[3:0]	 state			;
	
	//中间数据
	reg[`RegBus] minuend		;
	reg[`RegBus] count			;
	reg[`RegBus] div_result		;
	reg[`RegBus] div_remain		;
	wire[`RegBus] minuend_sub_div;
	
	
	wire[`RegBus] dividend_invert = ~dividend_r + 32'b1; //取补码
	wire[`RegBus] divisor_invert = ~divisor_r + 32'b1;
	
/* 	wire[`RegBus] dividend_invert = -dividend_r ; //取补码
	wire[`RegBus] divisor_invert = -divisor_r ; */
	
	//标志
	reg			invert_flag		;
	
	assign minuend_sub_div = minuend - divisor_r;
	// STATE
	localparam 	IDLE 	= 4'b0001,
				START 	= 4'b0010,
				CALC	= 4'b0100,
				END		= 4'b1000;
				
	`define DIV    			3'b100
	`define DIVU   			3'b101
	`define REM    			3'b110
	`define REMU   			3'b111
			  
	always @ (posedge clk) begin
		if(rst == `Rst) begin  //初始化
			state 		<= IDLE		;
			dividend_r 	<= `ZeroWord;
			divisor_r 	<= `ZeroWord;
			op_r		<= 	3'b0	;
			busy_o 		<= `DivIdle	;
			ready_o 	<= `DivNotReady;
			div_res_o 	<= `ZeroWord;
			reg_waddr_o <= `ZeroReg	;
			minuend		<= `ZeroWord;
			count		<= `ZeroWord;
			div_remain  <= `ZeroWord;
			div_result 	<= `ZeroWord;
			invert_flag <= 1'b0;
		end else begin
			case(state)
				IDLE: begin
					if(start_i == `DivStart) begin
						dividend_r <= dividend_i;  //除法运算开始的第一个周期，进行置数工作
						divisor_r <= divisor_i;
						op_r <= op_i;
						reg_waddr_o <= reg_waddr_i; //除法运算开始时保留写回寄存器地址信息
						busy_o <= `DivBusy;
						ready_o <= `DivNotReady;
						state <= START;  //转入下一状态，判断被除数是否为0等
					end else begin
					//在IDLE状态下没有进行除法指令
						dividend_r <= `ZeroWord;
						divisor_r <= `ZeroWord;
						op_r <= 3'b0; 
						busy_o <= `DivIdle;
						ready_o <= `DivNotReady;
						state <= IDLE;
					end
				end
				
				START: begin
					if(start_i == `DivStart) begin
					//有效的除法、求余操作		
					//判断除数是否为0
						if(divisor_r == `ZeroWord) begin
						//除数为0
							if((op_r == `DIV)||(op_r == `DIVU)) begin
							//除法操作
								div_res_o <= 32'hffffffff;
							end else begin
							//求余操作
								div_res_o <= dividend_r;
							end
							ready_o <= `DivReady;  //计算完成
							busy_o <= `DivIdle	;
							state <= IDLE		;
						end else begin
						//除数不为0,需要进入CALC状态计算得到结果
							busy_o <= `DivBusy;
							count <= 32'h40000000; //计数器，目前正在第二个周期
							state <= CALC;  //进入CALC状态计算
						end
						
						//求出minuend，分情况，是否需要对操作数求补码
						if((op_r == `DIV) || (op_r == `REM)) begin
							//被除数处理
							if(dividend_r[31] == 1'b1) begin
								dividend_r <= dividend_invert;
								minuend <= dividend_invert[31];
							end else begin
								minuend <= dividend_r[31];
							end
							
							//除数需要取补码
							if(divisor_r[31] == 1'b1) begin
								divisor_r <= divisor_invert;
							end else begin
								divisor_r <= divisor_r;
							end
						
						end else begin  //非有符号操作
							minuend <= dividend_r[31];
						end
						//判断是否要对结果取补码
						if(((op_r == `DIV) && ((dividend_r[31] ^ divisor_r[31]) == 1'b1)) ||
						((op_r == `REM) && (dividend_r[31] == 1'b1))) begin
							invert_flag <= 1'b1;  //需要对结果进行取补码
						end else begin
							invert_flag <= 1'b0;
						end
						
					end else begin 
					//无效的除法、求余操作
						state <= IDLE; //跳回IDLE状态
						busy_o <= `DivIdle;
						ready_o <= `DivNotReady;
						div_res_o <= `ZeroWord;
					end
				end
				
				CALC: begin   //整个除法器的关键执行部件
					if(start_i == `DivStart) begin
					//有效的操作
						busy_o <= `DivBusy;
						dividend_r <= {dividend_r[30:0], 1'b0}; // 被除数左移
						if(minuend >= divisor_r) begin
							div_result <= {div_result[30:0], 1'b1};  //最低位补1
						end else begin
							div_result <= {div_result[30:0], 1'b0};	//最低位补0
						end  //可以优化
						
						count <= {1'b0, count[31:1]}; //右移，用作计数器
						if(|count) begin
							if(minuend >= divisor_r) begin
								minuend <= {{minuend_sub_div[30:0]},dividend_r[30]};
							end else begin
								minuend <= {minuend[30:0], dividend_r[30]};
							end
						end else begin
							state <= END;  //33个周期完成，进入END状态
							if(minuend >= divisor_r) begin
								div_remain <= minuend_sub_div;
							end else begin
								div_remain <= minuend;
							end
						end
					end else begin
					//无效的操作
						state <= IDLE;
						busy_o <= `DivIdle;
						ready_o <= `DivNotReady;
						div_res_o <= `ZeroWord;
					end
				end
				
				END: begin
					if(start_i == `DivStart) begin
					//有效的操作
						ready_o <= `DivReady;
						busy_o <= `DivIdle;
						state <= IDLE;
						if(op_r == `DIV || op_r == `DIVU) begin
							if(invert_flag) begin
								div_res_o <= ~div_result + 32'b1;
								//div_res_o = -div_result;
							end else begin
								div_res_o <= div_result;
							end
						end else begin
							if(invert_flag) begin
								div_res_o <= ~div_remain + 32'b1;
								//div_res_o <= -div_remain;
							end else begin
								div_res_o <= div_remain;
							end
						end
						
					end else begin
					//无效的操作
						state <= IDLE;
						busy_o <= `DivIdle;
						ready_o <= `DivNotReady;
						div_res_o <= `ZeroWord;
					end
				end
				
				default: begin 
					div_res_o 	<= `ZeroWord	;
					busy_o 		<= `DivIdle		;
					ready_o 	<= `DivNotReady	; 
					state 		<= IDLE			;  //在状态不确定时转回IDLE状态
				end
			endcase
		
		end
	
	end




endmodule 