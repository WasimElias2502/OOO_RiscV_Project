/*------------------------------------------------------------------------------
 * File          : IFU.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module IFU #(
	FETCH_WIDTH = `FETCH_WIDTH, 				// Number of instruction to fetch
	INST_ADDR_WIDTH = `INST_ADDR_WIDTH			// Addess width of the instruction memory
) (
	input clk,
	input reset,
	//inputs for branch instructions
	input next_pc_t next_pc_sel,
	input [INST_ADDR_WIDTH-1:0] SB_Type_addr,
	input [INST_ADDR_WIDTH-1:0] UJ_Type_addr,
	input [INST_ADDR_WIDTH-1:0] JALR_Type_addr,
	input 						stall,
	//outputs
	output [31:0] Instruction_Code [FETCH_WIDTH-1:0],
	output [INST_ADDR_WIDTH-1:0] pc_out,
	output [INST_ADDR_WIDTH-1:0] pc_plus_4_out,
	output						 new_valid_inst
);

	
	reg [INST_ADDR_WIDTH-1 : 0] PC = {INST_ADDR_WIDTH{1'b0}};
	logic [31:0] Instruction_Code_from_mem [FETCH_WIDTH-1:0];
	logic stop_fetch;
	
	//FLUSH if next pc sel is not pc+4
	genvar i;
	generate
		for (i = 0; i < FETCH_WIDTH; i++) begin : assign_instr
			assign Instruction_Code[i] = 
				(next_pc_sel != pc_plus_4_t) ? {25'b0, NOP} : Instruction_Code_from_mem[i]; // flush with NOP
		end
	endgenerate
	
	//assign pc outputs
	INST_MEM inst_mem(PC , reset , Instruction_Code_from_mem);
	assign pc_out = PC;	
	assign pc_plus_4_out = PC+4;
	
	
	//assign valid for new instruction (the IF is not in stall mode)
	assign new_valid_inst = ~stall & ~stop_fetch;
	
	
	//Logic to detect End of code in the memory TODO: change to something synthesizable
	always_comb begin
		stop_fetch = 0;
		for (int i = 0; i < FETCH_WIDTH; i++) begin
			if (Instruction_Code_from_mem[i] === 32'bx)
				stop_fetch = 1;
		end
	end
	
	
	always @(posedge clk , posedge reset)
		begin
			if(reset) begin
				PC <= 0;
			end
			//selector for PC - branches or PC+4
			else begin
				if(!stall && !stop_fetch) begin
					case(next_pc_sel)
						sb		 	: PC <= SB_Type_addr;
						uj		 	: PC <= UJ_Type_addr;
						jalr	 	: PC <= JALR_Type_addr;
						pc_plus_4_t	: PC <= PC+4*FETCH_WIDTH;
						default  	: PC <= 'x; 
					endcase
				end // if(!stall)
				
				else begin // stall is asserted 
					PC <= PC;
				end
				
			end // else begin 
		end // always @(posedge clk , posedge reset)

endmodule