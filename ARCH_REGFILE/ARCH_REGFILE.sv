/*------------------------------------------------------------------------------
 * File          : ARCH_REGFILE.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ARCH_REGFILE #() (
	
	//inputs
	input 										clk										,
	input 										reset									,
	input 	[`ARCH_REG_NUM_WIDTH-1:0]    		read_red_addr_req						,
	input 										rd_en									,
	
	
	input 	[`MAX_NUM_OF_COMMITS-1:0]			dst_wr_en		,//TODO: check if match width in commit COMMIT_IF
	input 	[`ARCH_REG_NUM_WIDTH-1:0]    		dst_reg 	[`MAX_NUM_OF_COMMITS-1:0]	,
	input 	[`REG_VAL_WIDTH-1:0]    			dst_val 	[`MAX_NUM_OF_COMMITS-1:0]	,
	
	output 	[`REG_VAL_WIDTH-1:0]				read_value								,
	output 										read_valid

);

	logic [`REG_VAL_WIDTH-1:0] registers[`ARCH_REG_NUM];
	
	// ************************************ Always FF Logic ****************************************************//
	always_ff@(posedge clk or posedge reset) begin
		
		if(reset) begin
			//initialize registers
			for(int i=0 ; i< `ARCH_REG_NUM; i++) begin 
				registers[i] <= i;
			end 	
		end
		
		else begin
			//write for destination register
			for (int i=0 ; i< `MAX_NUM_OF_COMMITS ; i++) begin
				if(dst_wr_en[i]) begin
					registers[dst_reg[i]] <= dst_val[i];
				end
			end
		end
	end
	
	
	
	// ************************************ Always Comb Logic **************************************************//
	
	//Forward write values to read registers
	logic 										forward_en;
	logic 	[`ARCH_REG_NUM_WIDTH-1:0]    		forward_reg_idx;
	
	always_comb begin
		
		//Default
		forward_en 		= 0;
		forward_reg_idx = 0;
		
		for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			//forward to read request
			if(dst_wr_en[i] && dst_reg[i] == read_red_addr_req) begin
				forward_en 			= 1'b1;
				forward_reg_idx 	= i;
			end		
		end
	end
	
	//Mux to read from forwarded register or regfile 
	assign read_value = (forward_en)? dst_val[forward_reg_idx] : registers[read_red_addr_req];
	assign read_valid = rd_en;
	

endmodule