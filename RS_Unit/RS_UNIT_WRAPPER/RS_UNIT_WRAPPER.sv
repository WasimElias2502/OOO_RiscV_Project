/*------------------------------------------------------------------------------
 * File          : RS_UNIT.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 11, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module RS_UNIT_WRAPPER #() (
	
	input 								reset							,
	input								clk								,
	input control_t						control		  					,
	input [`REG_VAL_WIDTH-1:0] 			src_reg1_val					,
	input [`REG_VAL_WIDTH-1:0] 			src_reg2_val					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg1_addr					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg2_addr					,
	input [`REG_VAL_WIDTH-1:0]			immediate						,
	input								new_valid_inst					,
	input [`INST_ADDR_WIDTH-1:0]		pc_in							,
	input [`ROB_SIZE_WIDTH-1:0]			new_inst_tag					,
		
	
	CDB_IF.slave						cdb_if							,//TODO : CHECK WHERE CDB come from & decide it width
	FU_IF.RS							alu_if 	 						,
	FU_IF.RS							mem_if 	 						
);
	//TODO: add if RS are full then stall the pipe
	

	//========================================= Register Status Instatiation ============================== //
	
	RS2REG_STATUS_IF alu_rs2reg_status_table_if();
	RS2REG_STATUS_IF mem_rs2reg_status_table_if();
	
	
	RS_UNIT_REG_STATUS#() register_status_table(
		.reset						(reset)									,
		.clk						(clk)									,
		.new_valid_inst				(new_valid_inst)						,
		.dst_reg_addr				(dst_reg_addr)							,
		.reg_status_2_alu_rs_if		(alu_rs2reg_status_table_if.REG_STATUS)	,
		.reg_status_2_mem_rs_if		(mem_rs2reg_status_table_if.REG_STATUS)	,
		.cdb_if						(cdb_if)
	);
	
	
	// =================================== Mux for choosing RS kind for instruction ======================== //
	
	logic alu_inst_valid;
	logic mem_inst_valid;
	logic alu_cdb_ready;
	logic mem_cdb_ready;
	
	assign cdb_if.ready = alu_cdb_ready & mem_cdb_ready;
	
	
	//TODO: check if this is correct
	always_comb begin
		if(control.memory_op == no_mem_op) begin
			alu_inst_valid = new_valid_inst	;
			mem_inst_valid = 1'b0			;
		end
		else begin
			alu_inst_valid = 1'b0			;
			mem_inst_valid = new_valid_inst	;
		end
	end
	
	
	
	// ========================================= ALU Reservation Stations =================================== //
	
	RS#(	.RS_ENTRIES_NUM	(`RS_ALU_ENTRIES_NUM), 
			.FU_NUM			(`NUM_OF_ALUS)			
	) ALU_RS (
		.clk					(clk)			,
		.reset					(reset)			,
		.control				(control)		,
		.src_reg1_val			(src_reg1_val)	,
		.src_reg2_val			(src_reg2_val)	,
		.dst_reg_addr			(dst_reg_addr)	,
		.src_reg1_addr			(src_reg1_addr)	,
		.src_reg2_addr  		(src_reg2_addr) ,
		.immediate				(immediate)		,
		.new_valid_inst			(alu_inst_valid),
		.pc_in					(pc_in)			,
		.new_inst_tag			(new_inst_tag)	,
		
		.cdb_ready				(alu_cdb_ready)	,
		.cdb_if					(cdb_if)		,
		.fu_if					(alu_if)		,
		.reg_status_table_if	(alu_rs2reg_status_table_if.RS)
	
	);
	
	
	// ========================================= MEM Reservation Stations =================================== //
	
	RS#(	.RS_ENTRIES_NUM	(`RS_MEM_ENTRIES_NUM), 
			.FU_NUM			(`NUM_OF_MEM)			
	) MEM_RS (
		.clk					(clk)			,
		.reset					(reset)			,
		.control				(control)		,
		.src_reg1_val			(src_reg1_val)	,
		.src_reg2_val			(src_reg2_val)	,
		.dst_reg_addr			(dst_reg_addr)	,
		.src_reg1_addr			(src_reg1_addr)	,
		.src_reg2_addr  		(src_reg2_addr) ,
		.immediate				(immediate)		,
		.new_valid_inst			(mem_inst_valid),
		.pc_in					(pc_in)			,
		.new_inst_tag			(new_inst_tag)	,
		
		.cdb_ready				(mem_cdb_ready)	,
		.cdb_if					(cdb_if)		,
		.fu_if					(mem_if)		,
		.reg_status_table_if	(mem_rs2reg_status_table_if.RS)
	
	);

endmodule