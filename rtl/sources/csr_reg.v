`include "defines.v"
module csr_reg
(
	input wire					clk				,
	input wire					rst				,
	
	input wire[`CSRAddrBus]		csr_raddr_i		,
	input wire[`CSRAddrBus]		csr_waddr_i		,
	input wire					csr_wen_i		,
	input wire[`RegBus]			csr_wdata_i		,
	
	output reg[`RegBus]			csr_rdata_o		,
	output wire					global_int_en_o 
);

	reg[`DoubleRegBus] 	cycle	;
	reg[`RegBus]		mtvec	;  	//发生异常时跳转的地址
	reg[`RegBus]		mepc	;	//发生异常的指令
	reg[`RegBus]		mcause	;	//发生异常的种类
	reg[`RegBus]		mie		;   //指出能处理和忽略的中断
	reg[`RegBus]		mip		;   //目前正准备处理的中断
	reg[`RegBus]		mtval	;   //陷入的附加信息
	reg[`RegBus]		mscratch;	//暂存数据
	reg[`RegBus]		mstatus	;	//保存全局中断使能以及其他状态

	assign global_int_en_o = mstatus[3];
	
	// cycle
	always @ (posedge clk) begin
		if(rst == `Rst) begin
			cycle <= `ZeroDoubleWord;
		end else begin
			cycle <= cycle + 64'd1;
		end
	end
	
	//写csr_reg
	always @ (posedge clk) begin
		if(rst == `Rst) begin
			mtvec <= `ZeroWord;
			mepc <= `ZeroWord;
			mcause <= `ZeroWord;
			mie		<= `ZeroWord;
			mip	<= `ZeroWord	;
			mtval <= `ZeroWord	;
			mscratch <= `ZeroWord;
			mstatus <= `ZeroWord;
		end else begin
			case(csr_waddr_i[11:0])
				`CSR_MTVEC: begin
					mtvec <= csr_wdata_i;
				end
				`CSR_MCAUSE: begin
					mcause <= csr_wdata_i;
				end
				`CSR_MEPC: begin
					mepc <= csr_wdata_i;
				end
				`CSR_MIE: begin
					mie <= csr_wdata_i;
				end
				`CSR_MSTATUS: begin
					mstatus <= csr_wdata_i;
				end
				`CSR_MSCRATCH: begin
					mscratch <= csr_wdata_i;
				end
			endcase
			
		end
	end
	
	//读csr_reg
	always @ (*) begin
		// 读写地址相同
		if((csr_wen_i) && (csr_raddr_i == csr_waddr_i)) begin
			csr_rdata_o = csr_wdata_i;
		end else begin
			case(csr_raddr_i[11:0])
				`CSR_CYCLE: begin
					csr_rdata_o = cycle[31:0];
				end
				`CSR_CYCLEH: begin
					csr_rdata_o = cycle[63:32];
				end
				`CSR_MTVEC: begin
					csr_rdata_o = mtvec;
				end
				`CSR_MCAUSE: begin
					csr_rdata_o = mcause;
				end
				`CSR_MEPC: begin
					csr_rdata_o = mepc;
				end
				`CSR_MIE: begin
					csr_rdata_o = mie;
				end
				`CSR_MSTATUS: begin
					csr_rdata_o = mstatus;
				end
				`CSR_MSCRATCH: begin
					csr_rdata_o = mscratch;
				end
				default: begin
					csr_rdata_o = `ZeroWord;
				end
			endcase
		end
		
	end

endmodule