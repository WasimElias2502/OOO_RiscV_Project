interface CDB_IF;
	logic 								clk				;
	logic 								ready			;
	logic 								valid			;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] register_addr	;
	logic [`REG_VAL_WIDTH] 				register_val	;
	
	
	modport master(
		input 	clk 			,
		input 	ready			,
		output 	valid   		,
		output 	register_addr	,
		output 	register_val	
	);
	
	modport slave(
		input 	clk 			,
		output 	ready			,
		input 	valid   		,
		input 	register_addr	,
		input 	register_val	
	);
			
endinterface