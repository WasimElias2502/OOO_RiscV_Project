`ifndef __RS_SCHEDULER_TB_SV__ 
`define __RS_SCHEDULER_TB_SV__ 



`timescale 1ns/1ns

module RS_SCHEDULER_TB #(
	
	parameter FU_IDX_WIDTH  = (`NUM_OF_ALUS <= 1) ? 1 : $clog2(`NUM_OF_ALUS)
	
)();


	//reset & clk
	logic 							clk;		 
	logic							reset;	
	
	// ******************************************** RS SCHEDULER **************************************************//
	
		logic [`RS_ALU_ENTRIES_NUM-1:0]  	rs_ready;
		logic [`NUM_OF_ALUS-1:0] 			fu_available;
		
		logic [FU_IDX_WIDTH-1:0]			rs_fu_assign [`RS_ALU_ENTRIES_NUM-1:0];
		logic [`RS_ALU_ENTRIES_NUM-1:0]	 	rs_dispatch_en;
	
	
	RS_FU_SCHEDULER# (
		.NUM_OF_RS (`RS_ALU_ENTRIES_NUM),
		.NUM_OF_FU (`NUM_OF_ALUS)
	) rs_scheduler (
		
		.rs_ready		(rs_ready),
		.fu_available	(fu_available),
		
		.rs_fu_assign	(rs_fu_assign),
		.rs_dispatch_en	(rs_dispatch_en)
	
	);
	
	//******************************************** Drive Inputs  **************************************************//
	
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
			
			//all RS not valid in the beginning and all FU are ready
			rs_ready 			= '0;
			fu_available 		= {`NUM_OF_ALUS{1'b1}};
			
					
			#41
			rs_ready[0]			= 1'b1	;
			rs_ready[3]			= 1'b1	;
			
			#40
			rs_ready[4]			= 1'b1	;
			rs_ready[0]			= 1'b0	;
			rs_ready[3]			= 1'b0	;
			
			fu_available[0]		= 1'b0	;
			fu_available[1]		= 1'b0	;
			
			
			#40
			rs_ready[1]			= 1'b1	;
			rs_ready[2]			= 1'b1	;
			rs_ready[3]			= 1'b1	;
			rs_ready[4]			= 1'b1	;
			
			#40
			rs_ready[1]			= 1'b1	;
			rs_ready[2]			= 1'b1	;
			rs_ready[3]			= 1'b1	;
			rs_ready[4]			= 1'b1	;
			rs_ready[5]			= 1'b1	;
			rs_ready[6]			= 1'b1	;
			
			fu_available[0]		= 1'b1	;
			fu_available[1]		= 1'b1	;


		end
	
	//end test after 500ns
	initial 
		#500 $finish;


endmodule


`endif