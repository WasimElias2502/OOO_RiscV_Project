/*------------------------------------------------------------------------------
 * File          : BRANCH_MISPRED_UNIT_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 22, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module BRANCH_MISPRED_UNIT_WRAPPER #() (
	
	COMMIT_IF.slave 	commit_if,
	
	output 							flush			,
	output next_pc_t 				next_pc_sel		,
	output [`INST_ADDR_WIDTH-1:0] 	pc_out			

);
	logic							is_branch_op;
	logic							is_branch_taken;
	logic [`INST_ADDR_WIDTH-1:0] 	pc_in;

	always_comb begin
		
		bit found_branch_op;
		found_branch_op = 1'b0;
		
		for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			if(!found_branch_op) begin
				is_branch_op 	= (commit_if.commit_type[i] == branch_commit_taken || commit_if.commit_type[i] == branch_commit_not_taken) && commit_if.commit_valid[i];
				is_branch_taken	= (commit_if.commit_type[i] == branch_commit_taken);
				pc_in 			= (commit_if.commit_type[i] == branch_commit_taken)? commit_if.commit_value[i] : 'x;
				
				found_branch_op = ((commit_if.commit_type[i] == branch_commit_taken) && commit_if.commit_valid[i]);
			end
		end
	end
	
	

	BRANCH_MISPRED_UNIT branch_mispred_unit(
		.is_branch_op				(is_branch_op),
		.branch_taken				(is_branch_taken),
		.pc_in						(pc_in),
		
		.flush						(flush),
		.next_pc_sel				(next_pc_sel),
		.pc_out						(pc_out)
	);

endmodule