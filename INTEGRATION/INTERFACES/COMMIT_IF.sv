
`timescale 1ns/1ns

interface COMMIT_IF #();

	logic [`ROB_SIZE_WIDTH-1:0]				commited_tags		[`MAX_NUM_OF_COMMITS-1:0]	;
	logic [`MAX_NUM_OF_COMMITS-1:0]			commited_tags_valid								;	 
	logic [`ROB_SIZE_WIDTH-1:0]				new_inst_tag									;
	logic 									new_inst_tag_valid								;





	modport master(
		output 		commited_tags,
		output 		commited_tags_valid,
		input		new_inst_tag,
		input		new_inst_tag_valid

	);
	
	modport slave(
		input 		commited_tags,
		input 		commited_tags_valid,
		output		new_inst_tag,
		output		new_inst_tag_valid
	);


endinterface