/*------------------------------------------------------------------------------
 * File          : IMM_GENERATOR.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 17, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module IMM_GENETOR #(
	IMM_WIDTH          		  = `IMM_WIDTH,
	ARCH_REG_NUM_WIDTH 		  = `ARCH_REG_NUM_WIDTH,
	GENERATED_IMMEDIATE_WIDTH = `REG_VAL_WIDTH
) (
	input  [IMM_WIDTH-1:0] 					immediate_input,
	output [GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate
);

 localparam SIGN_EXTENSION_WIDTH = GENERATED_IMMEDIATE_WIDTH - IMM_WIDTH;
 
 assign generated_immediate = {{(SIGN_EXTENSION_WIDTH){immediate_input[IMM_WIDTH-1]}} , immediate_input };


endmodule