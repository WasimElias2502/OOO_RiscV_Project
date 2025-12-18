


interface COMMIT_IF #();

	logic [`ROB_SIZE_WIDTH-1:0]				commit_tag				[`MAX_NUM_OF_COMMITS-1:0]					;
	logic [`ARCH_REG_NUM_WIDTH-1:0]			commit_arch_reg_addr	[`MAX_NUM_OF_COMMITS-1:0]					;
	logic [`REG_VAL_WIDTH-1:0]				commit_value			[`MAX_NUM_OF_COMMITS-1:0]					;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]		commit_phy_reg_addr		[`MAX_NUM_OF_COMMITS-1:0]					;
	logic [`MAX_NUM_OF_COMMITS-1:0]			commit_valid														;
	commit_type_t							commit_type				[`MAX_NUM_OF_COMMITS-1:0]					;


	modport master(
		output 		commit_tag,
		output 		commit_valid,
		output		commit_arch_reg_addr,
		output		commit_value,
		output		commit_type,
		output 		commit_phy_reg_addr
	);
	
	modport slave(
		input 		commit_tag,
		input 		commit_valid,
		input 		commit_arch_reg_addr,
		input		commit_value,
		input		commit_type,
		output		commit_phy_reg_addr
	);


endinterface