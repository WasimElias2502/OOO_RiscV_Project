/*------------------------------------------------------------------------------
 * File          : CPU_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module CPU_TB #() ();

	//reset & clk
	logic 										clk , reset							;
	ARCH_REG_READ_IF							ARCH_REG_READ_if()					;
	
	
	
	
	CPU cpu(
		.clk				(clk),
		.reset				(reset),
		.ARCH_REG_READ_if	(ARCH_REG_READ_if.slave) 
	
	);
	
	
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#35 reset = 1'b0;
			#1400 reset = 1'b1;
		end
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("CPU_TB_wave.vcd");
			$fsdbDumpvars(0,CPU_TB);
		end
	
	//end test after 500ns 
	initial 
		#1500 $finish;


endmodule