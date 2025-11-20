/*------------------------------------------------------------------------------
 * File          : ROB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ROB #() (
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
	COMMIT_IF.master 								commit_if
);

	
	//**************************** Re Order Buffer Entries Instantiation **************************************//
	
	ROB_entry_t 									rob_entries		 [`ROB_SIZE-1:0];		
	logic [`ROB_SIZE_WIDTH-1:0] 					next_commit_ptr					;
	
	
	
	// ************************************ Always FF Logic ****************************************************//
	
		// ========================================= insert new inst to ROB ===================================== //
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			next_commit_ptr <= 0;
			
			// initialize ROB
			for(int i=0 ; i<`ROB_SIZE ; i++) begin
				rob_entries[i].occupied <= 0;
				rob_entries[i].can_commit <= 0;
			end 
			
			for (int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
				commit_if.commit_valid[i] <= 1'b0 ;
			end
			
		end 
		
		else begin
			
			bit stop_commit;
			
			// new inst entry added
			if(valid_inst_to_register && !(rob_entries[inst_tag].occupied) ) begin
				rob_entries[inst_tag].occupied			 	<= 1					;
				rob_entries[inst_tag].can_commit 			<= 0					;
				rob_entries[inst_tag].dest_arch_register 	<= dest_arch_register	;
				rob_entries[inst_tag].dest_phy_register 	<= dest_phy_register	;
				
				//decide commit type
				if(control_in.reg_wb && control_in.memory_op != mem_write) begin
					rob_entries[inst_tag].commit_type <= reg_commit;
				end
				else if(!control_in.reg_wb && control_in.memory_op == mem_write) begin
					rob_entries[inst_tag].commit_type <= mem_commit;
				end
				else if(control_in.is_branch_op) begin
					rob_entries[inst_tag].commit_type <= branch_commit;
				end
				
				
			end
			
			// ===================================== inst done from cdb ==========================================//
			for(int i=0 ; i< `NUM_OF_FU ; i++) begin
				if(cdb_if.valid[i]) begin
					
					rob_entries[cdb_if.inst_tag[i]].dest_arch_val <= cdb_if.register_val[i]	;
					rob_entries[cdb_if.inst_tag[i]].can_commit	  <= 1'b1					;
					
				end
			end
			
			// ====================================== Commit instructions ========================================//
			
			stop_commit = 1'b0;
			
			//Defualt
			for (int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
				commit_if.commit_valid[i] <= 1'b0 ;
			end

			for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
				
				int curr_ind;
				curr_ind = (next_commit_ptr + i)%(`ROB_SIZE);
				if(!stop_commit) begin
					if(rob_entries[curr_ind].can_commit && rob_entries[curr_ind].occupied ) begin
						commit_if.commit_tag[i] 			<= curr_ind									;
						commit_if.commit_arch_reg_addr[i] 	<= rob_entries[curr_ind].dest_arch_register	;
						commit_if.commit_valid[i]			<= 1'b1										;
						commit_if.commit_value[i]			<= rob_entries[curr_ind].dest_arch_val		;
						commit_if.commit_type[i]			<= rob_entries[curr_ind].commit_type		;
						commit_if.commit_phy_reg_addr[i]	<= rob_entries[curr_ind].dest_phy_register	;
						
						//free entry
						rob_entries[curr_ind].can_commit	<= 1'b0										;
						rob_entries[curr_ind].occupied		<= 1'b0										;
					end
					else begin
						stop_commit 						= 1'b1										;
						next_commit_ptr 					<= curr_ind									;
					end
				end
			end
		end
	end
	

	

endmodule
