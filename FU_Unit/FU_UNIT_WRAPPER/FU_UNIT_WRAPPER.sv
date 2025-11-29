/*------------------------------------------------------------------------------
 * File          : FU_UNIT_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 4, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module FU_UNIT_WRAPPER #() (
	input 											clk,
	input											reset,
	FU_IF.FU										alu_if,
	FU_IF.FU										load_store_if,
	
	//Issue Interface
	input logic [`ROB_SIZE_WIDTH-1:0]				issued_tag,
	input logic 									issue_valid,
	input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 		issue_reg_dst,
	input memory_op_t								issue_mem_op,
	
	CDB_IF.master									cdb_if,
	COMMIT_IF.slave									commit_if,
	MEM_IF.CPU										mem_if
);



	//*********************************** ALUS Instantiation ********************************************//

	ALU_UNIT_WRAPPER alu_wrapper (
		.clk				(clk),
		.reset				(reset),
		.alu_if				(alu_if),
		.cdb_if				(cdb_if)
	);
	
	//***************************** Load Store Queue Instantiation ***************************************//
	
	LOAD_STORE_UNIT_WRAPPER load_store_unit_wrapper(
		.clk				(clk),
		.reset				(reset),
		.issued_tag			(issued_tag),
		.issue_valid		(issue_valid),
		.issue_reg_dst		(issue_reg_dst),
		.issue_mem_op		(issue_mem_op),
		
		.rs_2_lsq_if		(load_store_if),
		.commit_if			(commit_if),
		.cdb_if				(cdb_if),
		.mem_if				(mem_if)
		
	
	);
	
	



endmodule