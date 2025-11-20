/*------------------------------------------------------------------------------
 * File          : IMM_GENERATOR_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 21, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


module IMM_GENERATOR_TB #() ();
	
	//clk
	logic 						clk;
	
	//DUT inputs
	logic [31:0]				Instruction_code;
	
	//DUT outputs
	logic [31:0]				generated_immediate;
	
	
	//DUT instantiation
	IMM_GENERATOR imm_gen (
		
		//input
		.Instruction_code	(Instruction_code),
		//output
		.generated_immediate(generated_immediate)
	);
	
	
	//clk
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;	
	
	//drive inputs for the DUT
	initial
		begin
			//inital values      								------- IMM = 0 -------
			Instruction_code[`OPCODE_WIDTH-1:0] = R_type;
			Instruction_code[11:7] 	= 7;
			Instruction_code[31:20] = 66;
			//      											------- IMM = 24 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = I_type_load;
			Instruction_code[11:7] 	= 11;
			Instruction_code[31:20] = 24;
			//      											------- IMM = 44 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = S_type;
			Instruction_code[11:7] 	= 5'b01100;
			Instruction_code[31:20] = 12'b100100;
			//      											------- IMM = 2152 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = SB_type;
			Instruction_code[11:7] 	= 5'b01001;
			Instruction_code[31:20] = 12'b000001111000;
			//      											------- IMM = -4 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = I_type_load;
			Instruction_code[11:7] 	= 5'b101;
			Instruction_code[31:20] = 12'b111111111100;
			//      											------- IMM = 12 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = S_type;
			Instruction_code[11:7] 	= 5'b01100;
			Instruction_code[31:20] = 16;
			//      											------- IMM = 5 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = I_type_arth;
			Instruction_code[11:7] 	= 2;
			Instruction_code[31:20] = 5;
			//													------- IMM = -20 -------
		#40 Instruction_code[`OPCODE_WIDTH-1:0] = SB_type;
			Instruction_code[11:7] 	= 5'b01101;
			Instruction_code[31:20] = 12'b111111100000;

		end

	//end test after 500ns
	initial 
		#500 $finish;
	
	//Setting Up waveform
	initial
		begin
			$dumpfile("IMM_GENERATOR_TB_output_wave.vcd");
			$dumpvars(0,IMM_GENERATOR_TB);
		end
		
	
	
	
endmodule