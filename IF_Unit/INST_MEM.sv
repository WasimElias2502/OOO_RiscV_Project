/*------------------------------------------------------------------------------
 * File          : INST_MEM.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module INST_MEM #(
	INST_ADDR_WIDTH 				= `INST_ADDR_WIDTH,						// Addess width of the instruction memory
	FETCH_WIDTH 					= `FETCH_WIDTH,							// Number of instruction to fetch
	parameter string INIT_FILE 		= `INIT_INST_MEM_FILE 					// File to initialize the memory
) (
	input [INST_ADDR_WIDTH-1:0] PC,
	input reset,
	output [31:0] Instruction_Code [FETCH_WIDTH-1:0]
);
	
	reg[7:0] Memory [(1<<INST_ADDR_WIDTH)-1:0];
	reg[31:0] Fetched_instructions [FETCH_WIDTH-1:0];
	
	// assign output to fetched instructions
	assign Instruction_Code = Fetched_instructions;
	
	// get FETCH WIDTH instructions from Memory
	always_comb
	begin
		for(int i=0; i<FETCH_WIDTH; i++) 
		begin
			Fetched_instructions[i] = { Memory[PC+4*i+3] , Memory[PC+4*i+2], Memory[PC+4*i+1], Memory[PC+4*i]};
		end
	end
	
	//Load the INST Memory
	always @(reset) 
	begin
		if(reset)
			begin
				
			if(INIT_FILE != "") begin
				$display("Initializing Memory with %s" , INIT_FILE);
				$readmemh("INIT_INST_MEM.hex" , Memory);
			end else begin
				$display("Did not find INIT_FILE for Instruction Memory" , INIT_FILE);
			end		
			
			end
	end
endmodule