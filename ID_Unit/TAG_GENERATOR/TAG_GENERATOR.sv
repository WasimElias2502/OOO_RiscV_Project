/*------------------------------------------------------------------------------
 * File          : RS_TAG_GENERATOR.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 6, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module TAG_GENERATOR #() (
	
	input 									clk												,
	input 									reset											,	
	input 									new_valid_inst									,
	input [`ROB_SIZE_WIDTH-1:0]				commited_tags		[`MAX_NUM_OF_COMMITS-1:0]	,
	input [`MAX_NUM_OF_COMMITS-1:0]			commited_tags_valid								,
	
	output [`ROB_SIZE_WIDTH-1:0]			new_inst_tag									,
	output 									new_inst_tag_valid								,
	output									rob_full										
);
	logic tag_fifo_empty;

	//************************* Synchronous FIFO instantiation **************************
	SYN_FIFO #(
		.DATA_WIDTH(`ROB_SIZE_WIDTH),
		.ADDR_WIDTH(`ROB_SIZE_WIDTH),
		.RESET_INITIAL_PUSH_EN(1),
		.RESET_INITIAL_PUSH_START(0),
		.RESET_INITIAL_PUSH_COUNT(`ROB_SIZE),
		.MAX_NUM_OF_WRITES_WIDTH(`MAX_NUM_OF_COMMITS_WIDTH)
		
		) free_tag_fifo (
			
			.clk			(clk),
			.reset			(reset),
			.wr_en 			(commited_tags_valid),
			.wr_data 		(commited_tags),
			.full			(),
			.rd_en 			(new_valid_inst),
			.rd_data		(new_inst_tag),
			.empty			(tag_fifo_empty),
			.next_empty		(rob_full)
		);
	
	assign new_inst_tag_valid = new_valid_inst & (~tag_fifo_empty);
	
	
		
endmodule