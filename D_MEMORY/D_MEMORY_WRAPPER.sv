/*------------------------------------------------------------------------------
 * File          : D_MEMORY_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module D_MEMORY_WRAPPER #() (
	
	input 					clk,
	input 					reset,
	MEM_IF.MEM				mem_if

);


	D_MEMORY data_memory(
		.clk					(clk),
		.reset					(reset),
		.memory_ready			(mem_if.memory_ready),
		.memory_ack				(mem_if.memory_ack),
		.memory_data_return		(mem_if.memory_data_return),
		
		.memory_req_valid		(mem_if.memory_req_valid),
		.memory_req_op			(mem_if.memory_req_op),
		.memory_req_address		(mem_if.memory_req_address),
		.memory_req_data		(mem_if.memory_req_data)
	);

endmodule