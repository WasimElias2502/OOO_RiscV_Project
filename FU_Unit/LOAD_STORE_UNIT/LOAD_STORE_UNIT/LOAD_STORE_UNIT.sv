/*------------------------------------------------------------------------------
 * File          : LOAD_STORE_UNIT.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 29, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LOAD_STORE_UNIT #() (
	
	input 										clk			,
	input 										reset		,
	
	//Issue Interface
	input logic [`ROB_SIZE_WIDTH-1:0]			issued_tag,
	input logic 								issue_valid,
	input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	issue_reg_dst,
	input memory_op_t							issue_mem_op,
	
	//Request Memory Operation 
	input logic [`D_MEMORY_ADDR_WIDTH-1:0]		req_memory_addr,
	input logic									req_valid,
	input logic [`ROB_SIZE_WIDTH-1:0]			req_tag,
	input logic [`REG_VAL_WIDTH-1:0]			req_data,
	
	//Commit Interface
	input logic	[`ROB_SIZE_WIDTH-1:0]			commited_tag [`MAX_NUM_OF_COMMITS-1:0],
	input logic	[`MAX_NUM_OF_COMMITS-1:0]		commit_valid,
								
	
	output 										ld_st_ready	,
	
	//CDB interface
	output logic								cdb_valid,
	output logic[`PHYSICAL_REG_NUM_WIDTH-1:0] 	cdb_register_addr,
	output logic [`REG_VAL_WIDTH-1:0] 			cdb_register_val,
	output logic [`ROB_SIZE_WIDTH-1:0]			cdb_inst_tag,
	
	//Memory interface
	input logic									memory_ready,
	input logic									memory_ack,
	input logic [`REG_VAL_WIDTH-1:0]			memory_data_return,
	
	output	logic								memory_req_valid,
	output memory_op_t							memory_req_op,
	output logic [`D_MEMORY_ADDR_WIDTH-1:0]		memory_req_address,
	output logic [`REG_VAL_WIDTH-1:0]			memory_req_data,
	
	//Send to Retire Tag Unit
	output logic 								clear_lsq_entry_valid,
	output logic [`ROB_SIZE_WIDTH-1:0]			clear_lsq_entry_tag				

);

	//=========================================== Interconnect Between LSQ and Mem Controller ===================================== //
		
		LSQ_2_MEM_CTRL_IF LSQ_2_MEM_CTRL_IF_if();
	

	// ================================================ Load Store Queue Instantiation ============================================ //
	
		LSQ lsq (
			.clk				(clk),
			.reset				(reset),
			
			.issued_tag			(issued_tag),
			.issue_valid		(issue_valid),
			.issue_reg_dst		(issue_reg_dst),
			.issue_mem_op		(issue_mem_op),
			.lsq_ready			(ld_st_ready),
			
			.req_memory_addr	(req_memory_addr),
			.req_valid			(req_valid),
			.req_tag			(req_tag),
			.req_data			(req_data),
			
			.commited_tag		(commited_tag),
			.commit_valid		(commit_valid),
			
			.lsq_req_valid		(LSQ_2_MEM_CTRL_IF_if.lsq_req_valid),
			.lsq_req_op			(LSQ_2_MEM_CTRL_IF_if.lsq_req_op),
			.lsq_req_address	(LSQ_2_MEM_CTRL_IF_if.lsq_req_address),
			.lsq_req_data		(LSQ_2_MEM_CTRL_IF_if.lsq_req_data),
			
			.mem_ctrl_ready		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_ready),
			.mem_ctrl_done		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_done),
			.mem_ctrl_data		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_data),
			
			.cdb_valid			(cdb_valid),
			.cdb_register_addr	(cdb_register_addr),
			.cdb_register_val	(cdb_register_val),
			.cdb_inst_tag		(cdb_inst_tag),
			
			.clear_lsq_entry_valid	(clear_lsq_entry_valid),
			.clear_lsq_entry_tag	(clear_lsq_entry_tag)
		);
		
		
		// ============================================ Memory Controller Instantiation =========================================== //
		
		MEM_CONTROLLER memory_controller (
			
			.clk				(clk),
			.reset				(reset),
			.lsq_req_valid		(LSQ_2_MEM_CTRL_IF_if.lsq_req_valid),
			.lsq_req_op			(LSQ_2_MEM_CTRL_IF_if.lsq_req_op),
			.lsq_req_address	(LSQ_2_MEM_CTRL_IF_if.lsq_req_address),
			.lsq_req_data		(LSQ_2_MEM_CTRL_IF_if.lsq_req_data),
			
			.mem_ctrl_ready		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_ready),
			.mem_ctrl_done		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_done),
			.mem_ctrl_data		(LSQ_2_MEM_CTRL_IF_if.mem_ctrl_data),
			
			.memory_ready		(memory_ready),
			.memory_ack			(memory_ack),
			.memory_data_return	(memory_data_return),
			.memory_req_valid	(memory_req_valid),
			.memory_req_op		(memory_req_op),
			.memory_req_address	(memory_req_address),
			.memory_req_data	(memory_req_data)
		);
		
		
		
	
endmodule