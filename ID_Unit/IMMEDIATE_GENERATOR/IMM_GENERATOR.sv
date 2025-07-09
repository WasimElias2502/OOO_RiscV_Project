/*------------------------------------------------------------------------------
 * File          : IMM_GENERATOR.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 17, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module IMM_GENERATOR #(
	ARCH_REG_NUM_WIDTH 		  = `ARCH_REG_NUM_WIDTH,
	GENERATED_IMMEDIATE_WIDTH = `REG_VAL_WIDTH,
	FETCH_WIDTH 			  = `FETCH_WIDTH	
) (
	input  [31:0] 							Instruction_code,
	output [GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate
);

	opcode_t  	opcode 	  ;
	bit [31:0]	immediate ;	
	bit [4:0]   imm_width ;
	bit 	  	twelve_bit;

	always_comb
		begin
			
		opcode = Instruction_code[`OPCODE_WIDTH-1:0];
		
			if(opcode == R_type) begin
				immediate = 0;
				imm_width = 1;
			end
			
			else if(opcode == I_type_load || opcode == I_type_arth) begin
				immediate = Instruction_code[31:20];
				imm_width = 12;
			end
			
			else if(opcode == S_type) begin
				immediate = {Instruction_code[31:25] , Instruction_code[11:7] };
				imm_width = 12;
			end
			
			else if(opcode == SB_type) begin
				immediate = {Instruction_code[31],Instruction_code[7],Instruction_code[30:25],Instruction_code[11:8],1'b0};
				imm_width = 13;
			end
		end
 
 
 assign generated_immediate = {{(19){twelve_bit}},twelve_bit, immediate[11:0]};
 assign twelve_bit = (imm_width == 13)? Instruction_code[31] : immediate[11] ;


endmodule