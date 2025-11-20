

interface CDB_IF;

	logic 								ready							;
	logic 								valid			[`NUM_OF_FU-1:0];
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] register_addr	[`NUM_OF_FU-1:0];
	logic [`REG_VAL_WIDTH] 				register_val	[`NUM_OF_FU-1:0];
	logic [`ROB_SIZE_WIDTH-1:0]			inst_tag		[`NUM_OF_FU-1:0];
	
	modport master(
		input 	ready			,
		output 	valid   		,
		output 	register_addr	,
		output 	register_val	,
		output  inst_tag		
	);
	
	modport slave(
		output 	ready			,
		input 	valid   		,
		input 	register_addr	,
		input 	register_val	,
		input   inst_tag		
	);
			
endinterface