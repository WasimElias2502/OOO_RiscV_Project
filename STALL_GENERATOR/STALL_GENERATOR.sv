/*------------------------------------------------------------------------------
 * File          : STALL_GENERATOR.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 23, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module STALL_GENERATOR #() (

	input							clk,
	input 							reset,
	
	input 							rob_full,
	input 							cannot_rename,
	
	input 							branch_op_incoming,
	input  [`ROB_SIZE_WIDTH-1:0] 	branch_op_incoming_tag,
	input 							inst_valid,
	
	input 							commit_valid,
	input 							commited_branch_op,
	input  [`ROB_SIZE_WIDTH-1:0] 	commited_branch_tag,
	
	input							rs_full,

	output 							stall_fetch,
	output 							stall_decode,
	output							stall_phy_regfile
);

	// Internal signals
	logic 							wait_for_branch_to_commit;
	logic [`ROB_SIZE_WIDTH-1:0]		waiting_branch_tag;

	logic							branch_new_this_cycle;
	assign branch_new_this_cycle = inst_valid && branch_op_incoming;


	always @(posedge clk or posedge reset) begin
		if (reset) begin
			wait_for_branch_to_commit  	<= 1'b0;
			waiting_branch_tag			<= '0;
		end
		else begin

			// Branch incoming ? begin waiting for that specific branch to commit
			if (inst_valid && branch_op_incoming) begin
				wait_for_branch_to_commit 	<= 1'b1;
				waiting_branch_tag			<= branch_op_incoming_tag;
			end
			
			// Branch commit ? release stall only when the same branch commits
			else if (commit_valid && commited_branch_op &&
					 wait_for_branch_to_commit &&
					 (waiting_branch_tag == commited_branch_tag)) begin
				wait_for_branch_to_commit 	<= 1'b0;
				waiting_branch_tag			<= '0;
			end
		end
	end


	assign stall_fetch  =
			rob_full |
			cannot_rename |
			wait_for_branch_to_commit |
			branch_new_this_cycle |
			rs_full;

	assign stall_decode =
			wait_for_branch_to_commit |
			branch_new_this_cycle |
			rs_full;
	
	assign stall_phy_regfile = rs_full;

endmodule
