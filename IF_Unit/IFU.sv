/*------------------------------------------------------------------------------
 * File          : IFU.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ns

module IFU #(
	FETCH_WIDTH = `FETCH_WIDTH, 				// Number of instruction to fetch
	INST_ADDR_WIDTH = `INST_ADDR_WIDTH			// Addess width of the instruction memory
) (
	input clk,
	input reset,
	//inputs for branch instructions
	input [1:0] next_pc_sel,
	input [INST_ADDR_WIDTH-1:0] SB_Type_addr,
	input [INST_ADDR_WIDTH-1:0] UJ_Type_addr,
	input [INST_ADDR_WIDTH-1:0] JALR_Type_addr,
	//outputs
	output [31:0] Instruction_Code [FETCH_WIDTH-1:0],
	output [INST_ADDR_WIDTH-1:0] pc_out,
	output [INST_ADDR_WIDTH-1:0] pc_plus_4_out
);

	
	reg [INST_ADDR_WIDTH-1 : 0] PC = {INST_ADDR_WIDTH{1'b0}};
	
	//assign pc outputs
	INST_MEM inst_mem(PC , reset , Instruction_Code);
	assign pc_out = PC;	
	assign pc_plus_4_out = PC+4;
	
	always @(posedge clk , posedge reset)
		begin
			if(reset) begin
				PC <= 0;
			end
			//selector for PC - branches or PC+4
			else begin
				case(next_pc_sel)
					`SB: PC <= SB_Type_addr;
					`UJ: PC <= UJ_Type_addr;
					`JALR: PC <= JALR_Type_addr;
					`PC_PLUS_4: PC <= PC+4*FETCH_WIDTH;
					default: PC <= 'x; 
				endcase
				
			end
			
		end

endmodule