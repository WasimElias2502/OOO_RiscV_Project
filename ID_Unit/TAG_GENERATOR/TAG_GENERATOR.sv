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
	
	input logic								retire_tag_valid								,
	input logic [`ROB_SIZE_WIDTH-1:0]		retire_tag										,
	
	output [`ROB_SIZE_WIDTH-1:0]			new_inst_tag									,
	output 									new_inst_tag_valid								,
	output									rob_full										,
	output									rob_empty
);
	logic tag_fifo_empty;
	logic [`ROB_SIZE_WIDTH-1:0]		retire_tag_in[1];

	//************************* Synchronous FIFO instantiation **************************
	SYN_FIFO #(
		.DATA_WIDTH(`ROB_SIZE_WIDTH),
		.ADDR_WIDTH(`ROB_SIZE_WIDTH),
		.RESET_INITIAL_PUSH_EN(1),
		.RESET_INITIAL_PUSH_START(0),
		.RESET_INITIAL_PUSH_COUNT(`ROB_SIZE),
		.MAX_NUM_OF_WRITES_WIDTH(0)
		
		) free_tag_fifo (
			
			.clk			(clk),
			.reset			(reset),
			.wr_en 			(retire_tag_valid),
			.wr_data 		(retire_tag_in),
			.full			(rob_empty),
			.rd_en 			(new_valid_inst),
			.rd_data		(new_inst_tag),
			.empty			(tag_fifo_empty),
			.next_empty		(rob_full)
		);
	
	assign new_inst_tag_valid = new_valid_inst & (~tag_fifo_empty);
	assign retire_tag_in[0]	  = retire_tag	;
	
		
endmodule