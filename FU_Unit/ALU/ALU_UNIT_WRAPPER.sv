/*------------------------------------------------------------------------------
 * File          : ALU_UNIT_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 4, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ALU_UNIT_WRAPPER #() (
	
	input 					clk,
	input					reset,
	FU_IF.FU				alu_if,
	CDB_IF.master			cdb_if
);

	
	//***************************** ALUS Instantiation ***************************************//
	
	
	generate
		genvar i;
		for (i = 0; i < `NUM_OF_ALUS ; i = i + 1) begin : alu_instances
			ALU alu_inst (
				//IN
				.clk				(clk),
				.reset				(reset),
				.alu_ready			(alu_if.ready[i]),
				.rs_valid			(alu_if.valid[i]),	
				.src_reg1_val 		(alu_if.src1_reg_val[i]),
				.src_reg2_val		(alu_if.src2_reg_val[i]),
				.dst_reg_addr		(alu_if.dst_reg_addr[i]),
				.control			(alu_if.control[i]),
				.immediate			(alu_if.immediate[i]),
				.pc_in				(alu_if.pc[i]),	//TODO: connect from RS_UNIT
				.new_inst_tag_in	(alu_if.new_inst_tag[i]),
				
				//OUT
				.result_val			(cdb_if.register_val[i]), 		//TODO: remeber that CDB is common for ALU's and D_MEM's
				.result_addr		(cdb_if.register_addr[i]),
				.alu_valid			(cdb_if.valid[i]),
				.new_inst_tag_out	(cdb_if.inst_tag[i]),
				.pc_out				(cdb_if.pc_out[i]), 			//TODO: connect to  branch misprediction unit
				.branch_taken_out	(cdb_if.branch_taken_out[i]) 	//TODO: connect to  branch misprediction unit
			);
		end
	endgenerate

endmodule