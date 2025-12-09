/*------------------------------------------------------------------------------
 * File          : MEM_IF.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

interface MEM_IF ();

	logic								memory_ready;
	logic								memory_ack;
	logic [`REG_VAL_WIDTH-1:0]			memory_data_return;
	
	logic								memory_req_valid;
	memory_op_t							memory_req_op;
	logic [`D_MEMORY_ADDR_WIDTH-1:0]	memory_req_address;
	logic [`REG_VAL_WIDTH-1:0]			memory_req_data;
	
	modport CPU (
		
		input 			memory_ready,
		input 			memory_ack,
		input 			memory_data_return,
		
		output		 	memory_req_valid,
		output			memory_req_op,
		output			memory_req_address,
		output			memory_req_data
	);
	
	modport MEM (
		
		output 			memory_ready,
		output 			memory_ack,
		output 			memory_data_return,
		
		input		 	memory_req_valid,
		input			memory_req_op,
		input			memory_req_address,
		input			memory_req_data
	);

endinterface

