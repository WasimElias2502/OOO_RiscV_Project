`timescale 1ns/1ns

interface RS_SCHEDULER_IF;

	logic 								valid			;
	logic 								ready			;
	control_t							control		  	;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg1_val	;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg2_val	;
	logic [`REG_VAL_WIDTH-1:0] 			dst_reg_val		;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr	;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg1_addr	;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg2_addr	;
	logic [`REG_VAL_WIDTH-1:0]			immediate		;
	
	
	modport RS(
		output 	valid,
		output 	control,
		output 	src_reg1_val,
		output 	src_reg2_val,
		output 	dst_reg_val,
		output 	dst_reg_addr,
		output 	src_reg1_addr,
		output 	src_reg2_addr,
		output 	immediate
	);
	
	modport SCHEDULER(
		input 	valid,
		output 	ready,
		input 	control,
		input 	src_reg1_val,
		input 	src_reg2_val,
		input 	dst_reg_val,
		input 	dst_reg_addr,
		input 	src_reg1_addr,
		input 	src_reg2_addr,
		input 	immediate
	);


endinterface