/*------------------------------------------------------------------------------
 * File          : CONTROL_UNIT.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


module CONTROL_UNIT #() (
	
	//inputs
	input  opcode_t	 					opcode,
	input  func3_t						func3,
	input  func7_t						func7,
	
	//output
	output control_t					control
);


	always @(func3 or func7 or opcode) begin
	
	//******************** NOP ****************************************//
	
		if(opcode == NOP) begin
			control.alu_src 		= src_reg2;
			control.is_branch_op 	= 1'b0;
			control.memory_op 		= no_mem_op;
			control.reg_wb 			= 1'b0;
			control.alu_op 			= add_op;
					
			
		end//else if(opcode == NOP)
	
		
	//****************** R_type ***************************************//
	
		else if(opcode == R_type) begin
			
			control.alu_src 		= src_reg2;
			control.is_branch_op 	= 1'b0;
			control.memory_op 		= no_mem_op;
			control.reg_wb 			= 1'b1;
			
			//decide which operation
			case(func3) 
				0: begin 
					if (func7 == 0) 
						control.alu_op = add_op;
					else if (func7 == 32) 
						control.alu_op = sub_op;
					end
				1: control.alu_op = sll_op;
				2: control.alu_op = slt_op;
				3: control.alu_op = sltu_op;
				4: control.alu_op = xor_op;
				5: begin 
					if (func7 == 0) 
						control.alu_op = srl_op;
					else if (func7 == 32) 
						control.alu_op = sra_op;
					end
				6: control.alu_op = or_op;
				7: control.alu_op = and_op;
						
			endcase
			
		end //if(opcode == R_type)
		
		
		
	//****************** I_type ***************************************//
		
		else if(opcode == I_type_load || opcode == I_type_arth) begin
			
			control.alu_src 		= immediate;
			control.is_branch_op 	= 1'b0;
			control.reg_wb 			= 1'b1;
			control.alu_op 			= add_op;
			
			if (opcode == I_type_load) begin
				control.memory_op = mem_read;
			end
			else begin
				control.memory_op = no_mem_op;
			end
			
			if (opcode == I_type_arth) begin
				case(func3) 
					0: begin 
						if (func7 == 0) 
							control.alu_op = add_op;
						else if (func7 == 32) 
							control.alu_op = sub_op;
						end
					1: control.alu_op = sll_op;
					2: control.alu_op = slt_op;
					3: control.alu_op = sltu_op;
					4: control.alu_op = xor_op;
					5: begin 
						if (func7 == 0) 
							control.alu_op = srl_op;
						else if (func7 == 32) 
							control.alu_op = sra_op;
						end
					6: control.alu_op = or_op;
					7: control.alu_op = and_op;
							
				endcase
			end //if (opcode == I_type_arth)	
		end //else if(opcode == I_type_load)
		
	//****************** S_type ***************************************//
		
		else if(opcode == S_type) begin
			control.alu_src 		= immediate;
			control.is_branch_op 	= 1'b0;
			control.memory_op 		= mem_write;
			control.reg_wb 			= 1'b0;
			control.alu_op 			= add_op;
					
			
		end//else if(opcode == S_type)
		
		
	//****************** SB_type **************************************//
		
		else if(opcode == SB_type) begin
			control.alu_src 		= src_reg2;
			control.is_branch_op 	= 1'b1;
			control.memory_op 		= no_mem_op;
			control.reg_wb 			= 1'b0;
			
			case(func3) 
				0: control.alu_op 	= eq_op;
				1: control.alu_op 	= not_eq_op;
				4: control.alu_op 	= less_than_op;
				5: control.alu_op 	= greater_equal_than_op;			
			endcase	
			
		end//else if(opcode == SB_type)	
		
		
		
	end //always @(funct3 or funct7 or opcode)

endmodule