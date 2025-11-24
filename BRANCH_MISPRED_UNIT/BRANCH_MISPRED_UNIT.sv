/*------------------------------------------------------------------------------
 * File          : BRANCH_MISPRED_UNIT.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Aug 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module BRANCH_MISPRED_UNIT #() (

	input 							is_branch_op	,
	input 							branch_taken	,
	input [`INST_ADDR_WIDTH-1:0] 	pc_in			,	
	
	output 							flush			,
	output [`INST_ADDR_WIDTH-1:0] 	pc_out			,	
	output next_pc_t 				next_pc_sel		

);
	 
	assign flush 		=	(is_branch_op && branch_taken)? 1'b1 	: 1'b0 			;
	assign next_pc_sel 	=	(is_branch_op && branch_taken)? sb	 	: pc_plus_4_t	;
	assign pc_out		=   (is_branch_op && branch_taken)? pc_in	: 'x			;


endmodule