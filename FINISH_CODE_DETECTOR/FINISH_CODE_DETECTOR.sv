/*------------------------------------------------------------------------------
 * File          : FINISH_CODE_DETECTOR.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module FINISH_CODE_DETECTOR #() (

	input 									clk,
	input 									reset,
	
	input 									seen_last_inst,
	
	input logic 							issue_valid,
	input [`ROB_SIZE_WIDTH-1:0]				issue_tag,
	
	input [`ROB_SIZE_WIDTH-1:0]				commit_tag		[`MAX_NUM_OF_COMMITS-1:0],
	input [`MAX_NUM_OF_COMMITS-1:0]			commit_valid,

	
	output logic 							finish_code
);

	logic [`ROB_SIZE_WIDTH-1:0] 			last_issued_tag ;
	logic 									finish_issue;
	logic									commited_last_inst;
	
	
	//Remember last issued tag
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			last_issued_tag			<= '0;
		end
		else begin
			if(issue_valid) begin
				last_issued_tag		<= issue_tag;
			end
		end
	end
	
	//Remember that seen_last_inst asserted
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			finish_issue			<= 1'b0;
		end
		else begin
			if(!finish_issue && seen_last_inst) begin
				finish_issue  <= 1'b1;		
			end
		end
	end
	
	//commited last inst
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			commited_last_inst	<= 1'b0;
		end
		else begin
			for (int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
				if ( commit_valid[i] && commit_tag[i] == last_issued_tag) begin
					commited_last_inst	<= 1'b1;
				end
				
			end
		end
	end
	
	assign finish_code = commited_last_inst & finish_issue ;

endmodule