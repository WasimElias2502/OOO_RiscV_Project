/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jul 12, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


module PHY_REGFILE #(
	REG_VAL_WIDTH 	= `REG_VAL_WIDTH			,
	NUM_OF_REGS		= 1<<`PHYSICAL_REG_NUM_WIDTH
) (
	//inputs
	input 										clk								,
	input 										reset							,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1					,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2					,
	
	input 										dst_wr_en	[`NUM_OF_FU-1:0]	,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg [`NUM_OF_FU-1:0]	,
	input 	[`REG_VAL_WIDTH-1:0]    			dst_val 	[`NUM_OF_FU-1:0]	,
	
	//output
	output 	[`REG_VAL_WIDTH-1:0]				src_val1						,
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
			for (int i=0 ; i< `NUM_OF_FU ; i++) begin
				if(dst_wr_en[i]) begin
					registers[dst_phy_reg[i]] <= dst_val[i];
				end
			end
		end
	end	
	
	// ************************************ Always Comb Logic **************************************************//
	
	//Forward write values to read registers
	logic 										forward_reg1_en;
	logic 										forward_reg2_en;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	forward_reg1_idx;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	forward_reg2_idx;
	
	always_comb begin
		
		//Default
		forward_reg1_en 	= 0;
		forward_reg2_en 	= 0;
		forward_reg1_idx 	= 0;
		forward_reg2_idx	= 0;
		
		for(int i=0 ; i<`NUM_OF_FU ; i++) begin
			//forward to reg1
			if(dst_wr_en[i] && dst_phy_reg[i] == src_phy_reg1) begin
				forward_reg1_en 	= 1'b1;
				forward_reg1_idx 	= i;
			end
			
			//forward to reg2
			if(dst_wr_en[i] && dst_phy_reg[i] == src_phy_reg2) begin
				forward_reg2_en 	= 1'b1;
				forward_reg2_idx 	= i;
			end
			
		end
	end
	
	//Mux to read from forwarded register or regfile 
	assign src_val1 = (forward_reg1_en)? dst_val[forward_reg1_idx] : registers[src_phy_reg1];
	assign src_val2 = (forward_reg2_en)? dst_val[forward_reg2_idx] : registers[src_phy_reg2];
	
	

endmodule