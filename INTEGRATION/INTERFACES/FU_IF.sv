
`timescale 1ns/1ns

interface FU_IF #(
	parameter NUM_OF_FU 
);

	logic [NUM_OF_FU-1:0]				ready				 			;
	logic 								valid 		 [NUM_OF_FU-1:0]	;
	logic [`REG_VAL_WIDTH-1:0] 			src1_reg_val [NUM_OF_FU-1:0]	;
	logic [`REG_VAL_WIDTH-1:0] 			src2_reg_val [NUM_OF_FU-1:0]	;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr [NUM_OF_FU-1:0]	;
	control_t 							control		 [NUM_OF_FU-1:0]	;
	logic [`REG_VAL_WIDTH-1:0]			immediate	 [NUM_OF_FU-1:0]	;
	
	
	modport FU(
		output ready,
		input  valid,
		input  src1_reg_val,
		input  src2_reg_val,
		input  dst_reg_addr,
		input  control,
		input  immediate

	);
	
	modport RS(
		input   ready,
		output  valid,
		output  src1_reg_val,
		output  src2_reg_val,
		output  dst_reg_addr,
		output  control,
		output  immediate
	);

endinterface