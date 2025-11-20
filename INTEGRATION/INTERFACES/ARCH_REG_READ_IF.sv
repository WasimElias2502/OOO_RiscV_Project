/*------------------------------------------------------------------------------
 * File          : ARCH_REG_READ_IF.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


interface ARCH_REG_READ_IF  ();

	logic 	[`ARCH_REG_NUM_WIDTH-1:0]    		read_red_addr_req						;
	logic 										rd_en									;
	logic 	[`REG_VAL_WIDTH-1:0]				read_value								;
	logic 										read_valid								;
	
	modport slave (
		input  read_red_addr_req	,
		input  rd_en				,
		output read_value			,
		output read_valid			
	);
	
	modport master (
		output read_red_addr_req	,
		output rd_en				,
		input  read_value			,
		input  read_valid			
	);


endinterface