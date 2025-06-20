/*------------------------------------------------------------------------------
 * File          : CONTROL_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module CONTROL_TB #() ();

	//clk
	logic 						clk;

	//DUT inputs
	opcode_t	 				opcode;
	func3_t						func3;
	func7_t						func7;
	  
	//DUT outputs
	control_t					control;
	
	
	//DUT instantiation
	CONTROL_UNIT control_unit (
		//inputs
		.opcode(opcode),
		.func3 (func3),
		.func7 (func7),
		
		//output
		.control(control)
	);
	
	//clk
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
	
	
	//drive inputs for the DUT
	initial
		begin
			//inital values      			------- xor -------
			opcode = R_type;
			func3  = 4;
			func7  = 15;
			//       						------- add -------
		#40 opcode = R_type;
			func3  = 0;
			func7  = 0;
			//       						------- sub -------
		#40 opcode = R_type;
			func3  = 0;
			func7  = 32;
			//       						------- sw -------
		#40 opcode = S_type;
			func3  = 2;
			func7  = 32;
			//      						------- bge -------
		#40 opcode = SB_type;
			func3  = 5;
			func7  = 3;
			//      						------- lw -------
		#40 opcode = I_type_load;
			func3  = 2;
			func7  = 3;
			//      						------- srli -------
		#40 opcode = I_type_arth;
			func3  = 5;
			func7  = 0;
			//      						------- srai -------
		#40 opcode = I_type_arth;
			func3  = 5;
			func7  = 32;
			//       						------- andi -------
		#40 opcode = I_type_arth;
			func3  = 7;
			func7  = 0;
		end
	
	//end test after 500ns
	initial 
		#500 $finish;
	
	//Setting Up waveform
	initial
		begin
			$dumpfile("CONTROL_TB_output_wave.vcd");
			$dumpvars(0,CONTROL_TB);
		end
		


endmodule