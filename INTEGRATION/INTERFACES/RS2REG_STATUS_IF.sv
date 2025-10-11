/*------------------------------------------------------------------------------
 * File          : RS2REG_STATUS_IF.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 11, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

interface RS2REG_STATUS_IF #();

	logic [`PHYSICAL_REG_NUM-1:0]		valid 				;
	logic [`PHYSICAL_REG_NUM-1:0]		reg_status			;
	logic [`PHYSICAL_REG_NUM-1:0]		update_reg_status	;

	modport RS(
		output valid,
		output update_reg_status,
		input reg_status
	);
	
	
	modport REG_STATUS(
		input valid,
		input update_reg_status,
		output reg_status
	);

endinterface