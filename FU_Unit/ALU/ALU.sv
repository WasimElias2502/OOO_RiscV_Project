/*------------------------------------------------------------------------------
 * File          : ALU.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ALU #(

	parameter LOW_LATENCY_CYCLES = `LOW_LATENCY_CYCLES,
	parameter HIGH_LATENCY_CYCLES = `HIGH_LATENCY_CYCLES, //TODO: not in use right now 
	parameter int HIGH_LATENCY_CYCLES_WIDTH = (HIGH_LATENCY_CYCLES <= 1) ? 1 : $clog2(HIGH_LATENCY_CYCLES)
	

) (
	
	input	logic	   							  	clk			,
	input 	logic									reset		,

	output	logic 									alu_ready	,
	input 	logic									rs_valid	,
	input 	logic [`REG_VAL_WIDTH-1:0]				src_reg1_val,
	input 	logic [`REG_VAL_WIDTH-1:0] 				src_reg2_val,
	input 	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]		dst_reg_addr,
	input 	control_t								control		,
	input 	logic [`REG_VAL_WIDTH-1:0]				immediate	,
	input 	logic [`INST_ADDR_WIDTH-1:0] 			pc_in		,
	input	logic [`ROB_SIZE_WIDTH-1:0]				new_inst_tag_in,
	

	// to CDB and next stage - ROB
	output 	logic [`REG_VAL_WIDTH-1:0]				result_val	,
	output 	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]		result_addr	,
	output 	logic									alu_valid	,
	
	// to branch misprediction unit
	output 	logic [`INST_ADDR_WIDTH-1:0] 			pc_out 		,
	output 	logic									pc_out_valid,// TODO: CHECK VALID
	output	logic [`ROB_SIZE_WIDTH-1:0]				new_inst_tag_out


	
);
		
	logic [`REG_VAL_WIDTH-1:0] 						curr_result_val;
	logic 											curr_inst_valid;
	
	logic											curr_inst_is_branch;
	logic [`INST_ADDR_WIDTH-1:0] 					curr_pc_out;
	logic											is_branch_taken;
	logic											is_curr_branch_taken; 
	
	logic [HIGH_LATENCY_CYCLES_WIDTH-1:0]			counter; 
		
		
	// ************************************ Always FF Logic ****************************************************//
	
	always_ff@(posedge clk or posedge reset) begin
		
		if(reset) begin
			counter 				<= 0		;
			curr_inst_valid 		<= 1'b0		;
			result_val				<= 0		;
			result_addr				<= 0		;
			new_inst_tag_out		<= 0		;
			
			is_curr_branch_taken 	<= 1'b0 	;
			curr_inst_is_branch 	<= 1'b0		;
			pc_out					<= 0		;
		end
		
		else begin
			
			if (counter > 0) begin
				counter 			<= counter - 1	; 
			end
					
			//new instruction incoming
			if(rs_valid) begin	
				counter 			<= LOW_LATENCY_CYCLES-1	;
				curr_inst_valid 	<= 1'b1					;
				result_val  		<= curr_result_val		; 
				pc_out				<= curr_pc_out			;
				is_curr_branch_taken<= is_branch_taken 		;
				result_addr			<= dst_reg_addr			;
				new_inst_tag_out	<= new_inst_tag_in		;
				
				if(control.is_branch_op) begin
					curr_inst_is_branch <= 1'b1;
				end
			end
			
			//Instruction done calculating
			if(counter == 0 && curr_inst_valid) begin
				curr_inst_valid 	<= 1'b0					;
			end
		end
	end	
	
	

	// ************************************ Comb Logic ****************************************************//
	
	
	//Instruction done calculating
	always_comb begin
		
		if(reset) begin
			alu_valid		 		= 1'b0						;
		end
		else begin
			if(counter == 0 && curr_inst_valid) begin
				if(curr_inst_is_branch) begin
					pc_out_valid 		= is_curr_branch_taken	;
				end
				else begin
					alu_valid		= 1'b1				  		;
				end
			end	
			
			else begin
				pc_out_valid 		= 1'b0						;
				alu_valid		 	= 1'b0				  		;
			end
			
		end
	end
	
	

	logic [`REG_VAL_WIDTH-1:0] src2_val; 
	logic [`REG_VAL_WIDTH-1:0] src1_val;

	assign src2_val = (control.alu_src == src_reg2)? src_reg2_val :  immediate;
	assign src1_val = src_reg1_val;
	
	
	//Calculate ALU results
	always_comb begin
		
		if(reset) begin
			alu_ready = 1'b1;
		end
		
		else begin
			
			if(rs_valid) begin	
				
				alu_ready 			= 1'b0;
				
				case(control.alu_op)
					
					add_op: begin
						curr_result_val = src1_val + src2_val;
					end
					sub_op: begin
						curr_result_val = src1_val - src2_val;
					end
					sll_op: begin
						curr_result_val = src1_val << src2_val;
					end
					slt_op: begin
						curr_result_val = (src1_val < src2_val)? 1 : 0;
					end
					sltu_op: begin
						curr_result_val = (src1_val < src2_val)? 1 : 0;
					end
					xor_op: begin
						curr_result_val = src1_val ^ src2_val;
					end
					srl_op: begin
						curr_result_val = src1_val >> src2_val;
					end
					sra_op: begin
						curr_result_val = src1_val >> src2_val;
					end
					or_op: begin
						curr_result_val = src1_val | src2_val;
					end
					and_op: begin
						curr_result_val = src1_val & src2_val;
					end
					eq_op: begin
						if(src1_val == src2_val && control.is_branch_op) begin
							curr_pc_out = pc_in + {immediate,1'b0};
							is_branch_taken = 1'b1;
						end
					end
					not_eq_op: begin
						if(src1_val != src2_val && control.is_branch_op) begin
							curr_pc_out = pc_in + {immediate,1'b0};
							is_branch_taken = 1'b1;
						end
					end
					less_than_op: begin
						if(src1_val < src2_val && control.is_branch_op) begin
							curr_pc_out = pc_in + {immediate,1'b0};
							is_branch_taken = 1'b1;
						end
					end
					greater_equal_than_op: begin
						if(src1_val >= src2_val && control.is_branch_op) begin
							curr_pc_out = pc_in + {immediate,1'b0};
							is_branch_taken = 1'b1;
						end
					end
					default begin
						is_branch_taken = 1'b0;
						curr_pc_out 	= 0;
						curr_result_val = 0;
					end
				endcase
			end
			
			else begin
				
				//alu ready when there is no instruction in the ALU
				alu_ready = ~curr_inst_valid;
				
			end
		
		end
	end
	
endmodule