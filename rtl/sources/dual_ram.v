`include "defines.v"
module dual_ram
#(
	parameter DW 		= 32	,
	parameter DEPTH 	= 4096	,
	parameter ADDR_BIT 	= 12
)
(
	input wire						clk 		,
	input wire						rst			,
			
	input wire						wen_i		,
	input wire[ADDR_BIT-1:0]		waddr_i		,
	input wire[DW-1:0]				wdata_i		,
		
	input wire						ren_i		,
	input wire[ADDR_BIT-1:0]		raddr_i		,
	output wire[DW-1:0]				rdata_o
);

	wire[DW-1:0]		ram_rdata_o		;
	reg					w_r_eq_flag		;
	reg[DW-1:0]			wdata_reg		;
	
	// wdata_reg
	always @ (posedge clk) begin
		wdata_reg <= wdata_i;
	end
	
	// w_r_eq_flag
	always @ (posedge clk) begin
		if(wen_i && ren_i && (raddr_i == waddr_i)) begin //读写地址相同，进行标记
			w_r_eq_flag <= 1'b1; //用于在读写地址相同时的数据选择操作
		end else begin
			w_r_eq_flag <= 1'b0;
		end
	end
	
	// 依据读写地址是否相同进行读取数据通路的判断，相同时选择wdata_reg,不同时从ram读取数据
	assign rdata_o = w_r_eq_flag? wdata_reg: ram_rdata_o;

ram 
#(
	.DW 		(DW 		),
	.DEPTH 		(DEPTH 		),
	.ADDR_BIT 	(ADDR_BIT 	)
) unit_ram
(
	.clk 			(clk 		),
	.rst			(rst		),

	.wen_i			(wen_i		),
	.waddr_i		(waddr_i	),
	.wdata_i		(wdata_i	),

	.ren_i			(ren_i		),
	.raddr_i		(raddr_i	),
	.rdata_o        (ram_rdata_o)
);

endmodule


module ram
#(
	parameter DW 		= 32	,
	parameter DEPTH 	= 4096	,
	parameter ADDR_BIT 	= 12
)
(
	input wire					clk 		,
	input wire					rst			,
		
	input wire					wen_i		,
	input wire[ADDR_BIT-1:0]	waddr_i		,
	input wire[DW-1:0]			wdata_i		,
	
	input wire					ren_i		,
	input wire[ADDR_BIT-1:0]	raddr_i		,
	output reg[DW-1:0]			rdata_o
);

	reg[DW-1:0]	memory[0:DEPTH-1]	;
	
	// Write
	always @ (posedge clk) begin
		if(rst && wen_i) begin
			memory[waddr_i] <= wdata_i;
		end 
	end
	
	//Read
	always @ (posedge clk) begin
		if(rst && ren_i) begin
			rdata_o <= memory[raddr_i];
		end
	end

endmodule
