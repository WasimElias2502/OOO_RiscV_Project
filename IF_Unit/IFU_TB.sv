/*------------------------------------------------------------------------------
 * File          : IFU_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 27, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ns

module IFU_TB #() ();

	//DUT inputs
	logic clk , reset;
	reg[1:0] next_pc_sel;
	reg [`INST_ADDR_WIDTH-1:0] sb_type_addr , uj_type_addr , jalr_type_addr ;
	
	//DUT output
	reg [31:0] Instruction_Code [`FETCH_WIDTH-1:0];
	reg [`INST_ADDR_WIDTH-1:0] pc , pc_plus_4;
	reg stall;
	
	//DUT
	IFU inst_fetch_unit(clk,reset,next_pc_sel,sb_type_addr , uj_type_addr , jalr_type_addr , stall ,Instruction_Code , pc , pc_plus_4 );
	
	
	//Setting Up waveform
	initial
		begin
			$dumpfile("IFU_output_wave.vcd");
			$dumpvars(0,IFU_TB);
		end
	
	//clk
	
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#20 reset = 1'b0;
			#200 reset = 1'b1;
			#400 reset = 1'b0;
		end
	
	
	//drive inputs for the DUT
	initial
		begin
			//inital values
			next_pc_sel    = 0 ;
			sb_type_addr   = 0 ;
			uj_type_addr   = 0 ;
			jalr_type_addr = 0 ;
			stall 		   = 0 ;
			//first cycle pc+4
			#21 next_pc_sel = pc_plus_4_t;
			//second cycle sb_type
			#40 next_pc_sel = sb ;
				sb_type_addr = 20;
			//third cycle UJ type
			#40 next_pc_sel  = uj ;
				uj_type_addr = 24;
			//fourth cycle JALR type
			#40 next_pc_sel = jalr ;
				jalr_type_addr = 16;
			//fifth cycle UJ type
			#40 next_pc_sel = uj ;
				uj_type_addr = 0 ;
			#39 stall 		= 1	 ;
			#1
				next_pc_sel = uj ;
				uj_type_addr = 8 ;
			
			
		end
	
	//end test after 500ns
	initial 
		#500 $finish;
			
endmodule