`timescale 1ns/1ns
`include "defines.v"
module tb_div();
	reg					clk			;
	reg					rst			;
	reg[`RegBus]		dividend	;
	reg[`RegBus]		divisor		;
	reg[2:0]			op			;
	reg					start_flag	;
	reg[`RegAddrBus]	reg_waddr	;
	
	wire[`RegBus]		div_result	;
	wire				div_ready	;
	wire				div_busy	;
	wire[`RegAddrBus]	reg_waddr_o	;
	
	initial begin
		clk = 1'b1;
		rst <= 1'b0;
		op  <= 3'b100;  //div
		dividend <= 32'h0000000a;  //10
		divisor <= 32'h00000003;  //3
		reg_waddr <= 5'b10010;
		start_flag <= 1'b0;
		#200
		rst <= 1'b1;
		#20
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;
		
		
		#20
		dividend <= 32'hfffffff6;  //-10
		divisor <= 32'h00000003;  //3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
		
		#20
		dividend <= 32'h0000000a;  //10
		divisor <= 32'hfffffffd;  //-3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
		
		#20
		dividend <= 32'hfffffff6;  //-10
		divisor <= 32'hfffffffd;  //-3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
		
		
		op <= 3'b110;
		#20
		dividend <= 32'h0000000a;  //-10
		divisor <= 32'h00000003;  //3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;			
		
		#20
		dividend <= 32'hfffffff6;  //-10
		divisor <= 32'h00000003;  //3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
		
		#20
		dividend <= 32'h0000000a;  //10
		divisor <= 32'hfffffffd;  //-3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
		
		#20
		dividend <= 32'hfffffff6;  //-10
		divisor <= 32'hfffffffd;  //-3
		start_flag <= 1'b1;
		#720
		start_flag <= 1'b0;	
	
	end
	
	
	div div_inst
(
	.clk				(clk),
	.rst				(rst),

	.dividend_i			(dividend),
	.divisor_i			(divisor),
	.op_i				(op),
	.reg_waddr_i		(reg_waddr),
	.start_i			(start_flag),

	.reg_waddr_o		(reg_waddr_o),
	.div_res_o			(div_result),
	.ready_o			(div_ready),
	.busy_o             (div_busy)
);
	//clk
	always #10 clk = ~clk;


endmodule 