/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jul 12, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module PHY_REGFILE_TB #() ();
	
	//******************************************** Wires For Inputs and Outputs ******************************************************//
	
		//DUT inputs
		
		logic 										clk								;
		logic 										reset							;
		logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1					;
		logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2					;
		logic 										dst_wr_en	 [`NUM_OF_FU-1:0]	;
		logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg  [`NUM_OF_FU-1:0]	;
		logic 	[`REG_VAL_WIDTH-1:0]    			dst_val 	 [`NUM_OF_FU-1:0]	;
		
		//DUT output
		logic 	[`REG_VAL_WIDTH-1:0]				src_val1						;
		logic 	[`REG_VAL_WIDTH-1:0]				src_val2						;	
	
	
	//*************************************************** DUT Instantiation **********************************************************//
	
		PHY_REGFILE phy_regfile (
			
			//inputs
			.clk			(clk),
			.reset			(reset),
			.src_phy_reg1	(src_phy_reg1),
			.src_phy_reg2	(src_phy_reg2),
			.dst_wr_en		(dst_wr_en),
			.dst_phy_reg	(dst_phy_reg),
			.dst_val		(dst_val),
			
			//output
			.src_val1		(src_val1),
			.src_val2		(src_val2)
		);
	
	
	//****************************************************** Drive Inputs  ************************************************************//	

	
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
				#700 reset = 1'b1;
			end

		//Setting Up waveform
		initial
			begin
				$dumpfile("PHY_REGFILE_TB_output_wave.vcd");
				$dumpvars(0, PHY_REGFILE_TB);
			end
		
		
		
		//drive inputs for the DUT
		initial
			begin
				src_phy_reg1 		= 0;
				src_phy_reg2 		= 0;
				dst_wr_en[0]	 	= 0;
				dst_phy_reg[0]		= 0;
				dst_val[0]			= 0;
	
				#21
				src_phy_reg1 		= 21;
				src_phy_reg2 		= 23;
				
				#40
				src_phy_reg1 		= 6;
				src_phy_reg2 		= 5;
				dst_wr_en[0]	 	= 1;
				dst_phy_reg[0]		= 23;
				dst_val[0]			= 144;
				
				#40
				src_phy_reg1 		= 23;
				src_phy_reg2 		= 22;
				dst_wr_en[0]	 	= 1;
				dst_phy_reg[0]		= 22;
				dst_val[0]			= 109;
				
				#40
				src_phy_reg1 		= 23;
				src_phy_reg2 		= 22;
				dst_wr_en[0]	 	= 0;
				dst_phy_reg[0]		= 5;
				dst_val[0]			= 109;
					
			end
		
		//end test after 500ns
		initial 
			#500 $finish;
	
endmodule