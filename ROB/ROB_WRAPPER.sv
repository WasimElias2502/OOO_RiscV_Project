/*------------------------------------------------------------------------------
 * File          : ROB_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ROB_WRAPPER #() (

	input logic										clk,
	input logic										reset,

	//ALU , MEM results
	CDB_IF.slave 									cdb_if,
	
	//Register the INST TAG
	input logic [`ROB_SIZE_WIDTH-1:0]				inst_tag,
	input logic [`ARCH_REG_NUM_WIDTH-1:0] 			dest_arch_register,
	input logic	[`PHYSICAL_REG_NUM_WIDTH]			dest_phy_register,
	input logic										valid_inst_to_register,
	input control_t						  			control_in,
	
	//commit interface
	COMMIT_IF.master 								commit_if,
	output logic[`INST_ADDR_WIDTH-1:0] 				total_of_commits
);


 //**************************** Re Order Buffer Instantiation **************************************//
	ROB rob(
		.clk					(clk),
		.reset					(reset),
		.cdb_if					(cdb_if),
		.inst_tag				(inst_tag),
		.dest_arch_register 	(dest_arch_register),
		.valid_inst_to_register	(valid_inst_to_register),
		.dest_phy_register		(dest_phy_register),
		.control_in				(control_in),
		
		.commit_if				(commit_if)
	);
	
 //**************************** Calculate Sum of Commited instructions *****************************//
 
	logic [`MAX_NUM_OF_COMMITS_WIDTH-1:0] num_of_valid_commits;

	always_comb begin
		num_of_valid_commits = '0;
		
		for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			num_of_valid_commits += commit_if.commit_valid[i];
		end
	end
 
	
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			total_of_commits <= '0;
		end
		else begin
			total_of_commits <= total_of_commits + num_of_valid_commits;
		end

	end


endmodule