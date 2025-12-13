/*------------------------------------------------------------------------------
 * File          : STALL_GENERATOR_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 23, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module STALL_GENERATOR_WRAPPER #() (

	input							clk,
	input 							reset,
	
	input 							rob_full,
	input 							can_rename,
	
	input 							branch_op_incoming,
	input  [`ROB_SIZE_WIDTH-1:0] 	branch_op_incoming_tag,
	input 							inst_valid,
	input							rs_full,
	
	COMMIT_IF.slave 				commit_if,

	output 							stall_fetch,
	output 							stall_decode,
	output							stall_phy_regfile
);

	logic							commit_valid;
	logic							commited_branch_op;
	logic [`ROB_SIZE_WIDTH-1:0]		commited_branch_tag;

	always_comb begin
		
		bit found_branch_op;
		found_branch_op = 1'b0;
		
		//Default
		commited_branch_op			= 1'b0	;
		commited_branch_tag			= '0	;
		commit_valid				= 1'b0	;
		
		for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			if(!found_branch_op && commit_if.commit_valid[i] && (commit_if.commit_type[i] == branch_commit_taken || commit_if.commit_type[i] == branch_commit_not_taken)) begin
				commit_valid		= 1'b1;
				commited_branch_op 	= 1'b1;
				commited_branch_tag = commit_if.commit_tag[i];
				found_branch_op 	= 1'b1;
			end
		end
	end
	
	 

	STALL_GENERATOR stall_gen (
	
		.clk					(clk),
		.reset					(reset),
		.rob_full				(rob_full),
		.cannot_rename			(~can_rename),
		.branch_op_incoming		(branch_op_incoming),
		.branch_op_incoming_tag (branch_op_incoming_tag),
		.inst_valid				(inst_valid),
		.rs_full				(rs_full),
		
		.commit_valid			(commit_valid),
		.commited_branch_op		(commited_branch_op),
		.commited_branch_tag	(commited_branch_tag),
		
		.stall_fetch			(stall_fetch),
		.stall_decode			(stall_decode),
		.stall_phy_regfile		(stall_phy_regfile)
	);
	



endmodule