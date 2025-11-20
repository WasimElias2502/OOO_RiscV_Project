/*------------------------------------------------------------------------------
 * File          : ARCH_REGFILE_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ARCH_REGFILE_WRAPPER #() (
	
	//inputs
	input 										clk										,
	input 										reset									,
	
	COMMIT_IF.slave								commit_if								,
	ARCH_REG_READ_IF.slave						read_regs_if				
);




	//**************************** Architecture Regfile Instantiation **********************************//
	
	logic [`REG_VAL_WIDTH-1:0]					read_value_d;
	logic										read_valid_d;
	logic [`MAX_NUM_OF_COMMITS-1:0]				arch_regfile_wr_en;
	
	
	
	always_comb begin
		for (int i=0 ; i< `MAX_NUM_OF_COMMITS ; i++) begin
			arch_regfile_wr_en[i] = commit_if.commit_valid[i] & (commit_if.commit_type[i] == reg_commit);
		end
	end
	
	
	ARCH_REGFILE regfile(
		.clk				(clk),
		.reset				(reset),
		.read_red_addr_req 	(read_regs_if.read_red_addr_req),
		.rd_en				(read_regs_if.rd_en),
		.dst_wr_en			(arch_regfile_wr_en),
		.dst_reg			(commit_if.commit_arch_reg_addr),
		.dst_val			(commit_if.commit_value),
		
		.read_value			(read_value_d),
		.read_valid			(read_valid_d)
	);
	
	DFF #(`REG_VAL_WIDTH) 	read_value_ff (.clk(clk) , .rst(rst) , .enable(1) , .in(read_value_d) , .out(read_regs_if.read_value));	
	DFF #(1) 				read_valid_ff (.clk(clk) , .rst(rst) , .enable(1) , .in(read_valid_d) , .out(read_regs_if.read_valid));		


endmodule