/*------------------------------------------------------------------------------
 * File          : FU_UNIT_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 4, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module FU_UNIT_WRAPPER #() (
	input 					clk,
	input					reset,
	FU_IF.FU				alu_if,
	CDB_IF.master			cdb_if
);



//***************************** ALUS Instantiation ***************************************//

	ALU_UNIT_WRAPPER alu_wrapper (
		.clk				(clk),
		.reset				(reset),
		.alu_if				(alu_if),
		.cdb_if				(cdb_if)
	);
	
	



endmodule