/*------------------------------------------------------------------------------
 * File          : ARCH_REG_FILE_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 2, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns


module ARCH_REG_FILE_TB #(
	ARCH_REG_NUM_WIDTH 	   = `ARCH_REG_NUM_WIDTH, 						// Number of architecture registers
	PHYSICAL_REG_NUM_WIDTH = `PHYSICAL_REG_NUM_WIDTH					// width (number of bits) of the number of physical registers
) ();

//******************************************** Wires For Inputs and Outputs ******************************************************//

	//DUT inputs
	logic clk , reset;
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num1;					
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num2;					
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_write_reg_num;					
	logic 						   regwrite;
			//inputs to free physical registers
	logic commit_valid;
	logic commit_with_write;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] commited_wr_register ;
	
	//DUT output
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num1; 				
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num2;				
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_write_reg_num;				
	
	
//******************************************** DUT Instantiation ******************************************************//	
	
	
	//DUT
	ARCH_REG_FILE #(
		.ARCH_REG_NUM_WIDTH(ARCH_REG_NUM_WIDTH), 	   				// Number of architecture registers
		.PHYSICAL_REG_NUM_WIDTH(PHYSICAL_REG_NUM_WIDTH) 			// width (number of bits) of the number of physical registers
	) arch_reg_file(
		 .clk(clk),
		 .reset(reset),
		 .arch_read_reg_num1(arch_read_reg_num1), 					// **************** architecture ************//
		 .arch_read_reg_num2(arch_read_reg_num2),					// ******************** W/R *****************//
		 .arch_write_reg_num(arch_write_reg_num),					// **************** registers****************//
		 .regwrite(regwrite),
		//inputs to free physical registers
		.commit_valid(commit_valid),
		.commit_with_write(commit_with_write),
		.commited_wr_register(commited_wr_register),
		
		.phy_read_reg_num1(phy_read_reg_num1), 						// ***************** physical ***************//
		.phy_read_reg_num2(phy_read_reg_num2),						// ******************** W/R *****************//
		.phy_write_reg_num(phy_write_reg_num)						// **************** registers****************//
	);
	
	//Setting Up waveform
	initial
		begin
			$dumpfile(" ARCH_REG_FILE_TB_output_wave.vcd");
			$dumpvars(0, ARCH_REG_FILE_TB);
		end
	
//******************************************** Drive Inputs  ******************************************************//	

	
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
	
	
	//drive inputs for the DUT
	initial
		begin
			#21 
			arch_read_reg_num1   = 1;					
			arch_read_reg_num2   = 30;					
			arch_write_reg_num   = 4;					
			regwrite 		   	 = 1;
			//inputs to free physical registers
			commit_valid 	     = 0;
			commit_with_write    = 0;
			commited_wr_register = 0 ;
			
			#40
			arch_read_reg_num1   = 1;					
			arch_read_reg_num2   = 30;					
			arch_write_reg_num   = 1;					
			regwrite 		   	 = 1;
		
			
			#40
			arch_read_reg_num1   = 2;					
			arch_read_reg_num2   = 30;					
			arch_write_reg_num   = 5;					
			regwrite 		   	 = 1;
			
			#40
			arch_read_reg_num1   = 2;					
			arch_read_reg_num2   = 30;					
			arch_write_reg_num   = 2;					
			regwrite 		   	 = 1;
	
		end
	
	//end test after 500ns
	initial 
		#500 $finish;
endmodule