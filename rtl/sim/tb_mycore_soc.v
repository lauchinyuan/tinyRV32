`timescale 1ns/1ns
`include "defines.v"
module tb_mycore_soc();
	reg		clk		;
	reg		rst		;
	wire[`RegBus]	x7 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[7];
	wire[`RegBus]	x27 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[27];
	wire[`RegBus]	x3 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[3];
	wire[`RegBus]	t4 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[29];
	wire[`RegBus]	x21 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[21];
	wire[`RegBus]	x6 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[6];
	wire[`RegBus]	x8 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[8];
	wire[`RegBus]	x5 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[5];
	wire[`RegBus]	x26 = tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[26];
	initial begin
		clk = 1'b1;
		rst <= 1'b0;
		# 20
		rst <= 1'b1;
	end
	
	always # 10 clk = ~clk;
	
	initial begin
		//写入指令内容
		$readmemh("inst.txt",tb_mycore_soc.mycore_soc_inst.unit_rom.unit_ram_rom.unit_ram.memory);
	end
//rv32ui-p-sb.txt
 	initial begin
 	/* 	while(1) begin
			@ (posedge clk) begin
				$display("x6 = %d",x6);
				$display("x5 = %d", x5);
				$display("x21 = %d", x21);
				//$display("x25 = %d", tb_mycore_soc.mycore_soc_inst.core.unit_regs.regs[25]);
				$display("********************END****************");
			end
		end  */ 

		wait(x26);
/* 		#200
		if (x27 == 32'b1) begin
			$display("pass");
			$display("step:%d",x3);
		end else begin
			$display("fail");
			$display("step:%d",x3);
		end */
		
		#5000
		$display("x5 = %b", x5);
		$display("x6 = %b", x6);
		$display("x7 = %b", x7);
		$display("x8 = %b", x8);
		if(x7[15:0] == x8[15:0]) begin
			$display("x7 == x8 = %b",x8);
			if(x5[15:0] == x6[15:0]) begin
				$display("x5 == x6 = %b",x6);
			end else begin
				$display("x5 != x6");
			end
		end else begin
			$display("x7 != x8");

		end
		
	end
	
/* 	initial begin
		while (1) begin
			@ (posedge clk) begin
				$display("step:%d",x3);
			end
		end
	end */

	mycore_soc mycore_soc_inst
	(
		.clk		(clk),
		.rst		(rst)
	);
	
	
endmodule