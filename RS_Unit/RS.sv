/*------------------------------------------------------------------------------
 * File          : RS.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module RS #() (
	
	//inputs
	//input opcode_t	 					opcode,      //TODO: should replace it
	input [31:0] 						src_val1,
	input [31:0] 						src_val2,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg,
	input [`REG_VAL_WIDTH-1:0]			immediate,
	
	//outputs
	input 								valid_add_inst,
	input 								valid_mul_inst,
	
	


);

endmodule