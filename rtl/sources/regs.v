`include "defines.v"
//需要注意零号寄存器的问题
//暂时只关注core
module regs
(
	input	wire					clk		,
	input	wire					rst		,
	
	// from ex
	input	wire					wen_i	,
	input	wire	[`RegAddrBus]	w_addr_i,
	input	wire	[`RegBus]		w_data_i,
	
	// from id
	input	wire	[`RegAddrBus]	r_addr1_i,
	input	wire	[`RegAddrBus]	r_addr2_i,
	
	// to id
	output	reg		[`RegBus]		r_data1_o,
	output	reg 	[`RegBus]		r_data2_o

);

reg [`RegBus] regs[0:`RegNum-1];

//Write Register
always@(posedge clk) begin
	if (rst == `RstDisable) begin
		if(wen_i == `WriteEnable && w_addr_i != `ZeroReg) begin  //需要注意零号寄存器的问题
			regs[w_addr_i] <= w_data_i;
		end
	end
end

//注意：读寄存器无需等待时钟
//Read Register data1
always@(*) begin
	if(r_addr1_i == `ZeroReg) begin
		r_data1_o = `ZeroWord;
		//如果写回的数据正在被读，则直接将写入的数据从读取端口输出
	end else if (r_addr1_i == w_addr_i && wen_i == `WriteEnable) begin
		r_data1_o = w_data_i;
	end else begin
		r_data1_o = regs[r_addr1_i];
	end
end

//Read Register data2
always@(*) begin
	if(r_addr2_i == `ZeroReg) begin
		r_data2_o = `ZeroWord;
		//如果写回的数据正在被读，则直接将写入的数据从读取端口输出
	end else if (r_addr2_i == w_addr_i && wen_i == `WriteEnable) begin
		r_data2_o = w_data_i;
	end else begin
		r_data2_o = regs[r_addr2_i];
	end
end


endmodule
