/*------------------------------------------------------------------------------
 * File          : RETIRE_TAGS.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 13, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module RETIRE_TAGS #() (
	
	input 									clk,
	input									reset,
	
	COMMIT_IF.slave							commit_if,
	
	input logic 							issue_valid,
	input memory_op_t						issue_mem_op,
	input [`ROB_SIZE_WIDTH-1:0]				issue_tag,
	
	input logic								lsq_retire_valid,
	input logic [`ROB_SIZE_WIDTH-1:0]		lsq_retire_tag,
	
	
	output logic							retire_tag_valid,
	output logic [`ROB_SIZE_WIDTH-1:0]		retire_tag
);

	TAG_RETIRE_entry_t 						TAG_BUFFER [`ROB_SIZE-1:0];
	logic [`ROB_SIZE_WIDTH-1:0]				retire_ptr;
	
	logic 									can_retire;
	
	
	// logic for retire
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			for (int i=0 ; i<`ROB_SIZE_WIDTH ; i++) begin
				TAG_BUFFER[i].ready_to_retire				<= 1'b0;
			end
		end
		
		else begin
			
			//if tag is in lsq 
			if (lsq_retire_valid ) begin
				TAG_BUFFER[lsq_retire_tag].ready_to_retire 	<= 1'b1;
			end
			
			//if issue is not memory op
			if (issue_valid && issue_mem_op == no_mem_op) begin
				TAG_BUFFER[issue_tag].ready_to_retire		<= 1'b1;
			end
			
			// can retire
			if(can_retire) begin
				TAG_BUFFER[retire_ptr].ready_to_retire		<= 1'b0;
			end

		end
	end
	
	
	//logic commit
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			for (int i=0 ; i<`ROB_SIZE_WIDTH ; i++) begin
				TAG_BUFFER[i].commited						<= 1'b0;
			end
		end
		
		else begin
			for (int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			
				if(commit_if.commit_valid[i]) begin
					TAG_BUFFER[commit_if.commit_tag[i]].commited <= 1'b1 ;
				end
				
			end
			
			
			if(can_retire) begin
				TAG_BUFFER[retire_ptr].commited	<= 1'b0;
			end
			
		end
		
	end
	
	//issue tag
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			for (int i=0 ; i<`ROB_SIZE_WIDTH ; i++) begin
				TAG_BUFFER[i].mem_op						<= no_mem_op;
			end
		end
		else begin
			if (issue_valid) begin
				TAG_BUFFER[issue_tag].mem_op				<= issue_mem_op;
			end
			
			if(can_retire) begin
				TAG_BUFFER[retire_ptr].mem_op				<= no_mem_op;
			end
			
		end
	end
	
	//Retire logic
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			retire_ptr			<= '0;
		end
		else begin
			if (can_retire) begin
				retire_ptr			<= (retire_ptr + 1)%`ROB_SIZE;
			end
		end
	end
	
	
	
	// Check if tag at retire ptr is complete
	assign can_retire = TAG_BUFFER[retire_ptr].commited && TAG_BUFFER[retire_ptr].ready_to_retire;
	assign retire_tag_valid = can_retire ;
	assign retire_tag		= (can_retire)? retire_ptr : '0;



endmodule