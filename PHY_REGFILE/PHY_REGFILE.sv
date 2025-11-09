/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jul 12, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module PHY_REGFILE #(
	REG_VAL_WIDTH 	= `REG_VAL_WIDTH			,
	NUM_OF_REGS		= 1<<`PHYSICAL_REG_NUM_WIDTH
) (
	//inputs
	input 										clk			,
	input 										reset		,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2,
	
	input 										dst_wr_en	,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg ,
	input 	[`REG_VAL_WIDTH-1:0]    			dst_val 	,
	
	//output
	output 	[`REG_VAL_WIDTH-1:0]				src_val1	,
	output 	[`REG_VAL_WIDTH-1:0]				src_val2	
);

	logic [REG_VAL_WIDTH-1:0] registers [NUM_OF_REGS];
	
	// ************************************ Always FF Logic ****************************************************//
	
	always_ff@(posedge clk or posedge reset) begin
		
		if(reset) begin
			//initialize registers
			for(int i=0 ; i< NUM_OF_REGS; i++) begin 
				registers[i] <= i;
			end 	
		end
		
		else begin
			//write for destination register
			if(dst_wr_en) begin
				registers[dst_phy_reg] <= dst_val;
			end
		end
	end	
	
	// ************************************ Always Comb Logic **************************************************//
	
	assign src_val1 = registers[src_phy_reg1];
	assign src_val2 = registers[src_phy_reg2];
	
	

endmodule