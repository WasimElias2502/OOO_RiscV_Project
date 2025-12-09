/*------------------------------------------------------------------------------
 * File          : RS.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module RS #(
	
	parameter RS_ENTRIES_NUM ,
	parameter FU_NUM,
	parameter int FU_IDX_WIDTH = (FU_NUM <= 1) ? 1 : $clog2(FU_NUM)
	
) (
	
	//inputs
	input								clk								,
	input								reset							,
	input control_t						control		  					,
	input [`REG_VAL_WIDTH-1:0] 			src_reg1_val					,
	input [`REG_VAL_WIDTH-1:0] 			src_reg2_val					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg1_addr					,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg2_addr					,
	input [`REG_VAL_WIDTH-1:0]			immediate						,
	input								new_valid_inst					,
	input [`INST_ADDR_WIDTH-1:0]		pc_in							,
	input [`ROB_SIZE_WIDTH-1:0]			new_inst_tag					,
	
	output								cdb_ready						,
	CDB_IF.slave						cdb_if							,//TODO : CHECK WHERE CDB come from & decide it width
	FU_IF.RS							fu_if 	 						,
	RS2REG_STATUS_IF.RS					reg_status_table_if

);

	//Instantiate Reservation stations
	reservation_station_t 						RS_entries[RS_ENTRIES_NUM]	;
	bit[RS_ENTRIES_NUM-1:0]						RS_busy						;
	
	//Instantiate Physical Register Status Table
	bit 										found_empty_RS_entry;
	
	// *************************************** Assignments *****************************************************//
	
	assign cdb_ready = 1'b1; // TODO: change to correct logic
	
	// ************************************ Always Comb Logic **************************************************//
	
	//assign busy RS 
	always_comb begin
		
		if(reset == 1'b1) begin
			for (int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				RS_busy[i] 	= 1'b0 ;
			end
		end
		else begin
			for (int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				
				//if need register src2 and src1 and both are valid
				if(reg_status_table_if.reg_status[RS_entries[i].src_reg1_addr] == valid && reg_status_table_if.reg_status[RS_entries[i].src_reg2_addr] == valid 
						&& RS_entries[i].control.alu_src == src_reg2 && RS_entries[i].control.memory_op == no_mem_op) begin
					RS_busy[i] 	= 1'b0 ;
				end
				//if need just src1 and it is valid and ALU operation
				else if(reg_status_table_if.reg_status[RS_entries[i].src_reg1_addr] == valid && RS_entries[i].control.alu_src != src_reg2 && RS_entries[i].control.memory_op == no_mem_op) begin
					RS_busy[i] 	= 1'b0 ;
				end
				//if store word
				else if (RS_entries[i].control.memory_op == mem_write && reg_status_table_if.reg_status[RS_entries[i].src_reg1_addr] == valid 
						&& reg_status_table_if.reg_status[RS_entries[i].src_reg2_addr] == valid) begin
					RS_busy[i] 	= 1'b0 ;
				end
				//if load word
				else if (RS_entries[i].control.memory_op == mem_read && reg_status_table_if.reg_status[RS_entries[i].src_reg1_addr] == valid) begin
					RS_busy[i] 	= 1'b0 ;
				end
				
				//if it is branch operation should not wait
				else if(RS_entries[i].control.is_branch_op && reg_status_table_if.reg_status[RS_entries[i].src_reg1_addr] == valid  
						&& reg_status_table_if.reg_status[RS_entries[i].src_reg2_addr] == valid) begin
					RS_busy[i] 	= 1'b0 ;
				end
				else begin
					RS_busy[i] 	= 1'b1 ;
				end
			end
		end

	end

  // **************************************** RS FU SCHEDULER ************************************************//
  
	logic [RS_ENTRIES_NUM-1:0]     	rs_ready_to_dispatch;
	logic [ FU_NUM-1:0]     		fu_available;
	logic [FU_IDX_WIDTH-1:0] 		rs_fu_assign [RS_ENTRIES_NUM-1:0];
	logic [RS_ENTRIES_NUM-1:0]     	rs_dispatch_en ;  
	
	always_comb begin
		//assign rs ready
		for (int i=0 ; i < RS_ENTRIES_NUM ; i++) begin
			rs_ready_to_dispatch[i] = ~RS_busy[i] && RS_entries[i].valid_entry ;
		end
		
		//assign reay fu
		for (int j=0 ; j < FU_NUM ;j++) begin
			fu_available[j] = fu_if.ready[j];
		end
	end
  
	RS_FU_SCHEDULER #(
		.NUM_OF_RS(RS_ENTRIES_NUM),
		.NUM_OF_FU(FU_NUM)
	)rs_fu_scheduler (
		
		//ins
		.clk(clk),
		.rst(reset),
		.rs_ready(rs_ready_to_dispatch),
		.fu_available(fu_available),
		
		//outs
		.rs_fu_assign(rs_fu_assign),
		.rs_dispatch_en(rs_dispatch_en)
	);
	
	
	// ************************************ Always FF Logic ****************************************************//
	
	// Got New instruction  and Dispatch Instructions
	always_ff @(posedge clk or posedge reset) begin
		
		// Make all reservation stations not busy and all reg status valid
		if(reset == 1'b1 ) begin
			for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				RS_entries[i].valid_entry <= 1'b0;
			end

			
			
		end
		else begin
			
			
			// =============================== Dispatch instruction from RS ==========================================
			for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				if(rs_dispatch_en[i]) begin
					RS_entries[i].valid_entry					<= 1'b0					;

				end
			end
			
			
			// ================================== New instruction coming ==============================================
			found_empty_RS_entry = 0;
			
			for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				
				//TODO: add ready signal when all RS are busy the ready = 0
				if (!RS_entries[i].valid_entry && !found_empty_RS_entry && new_valid_inst) begin
					RS_entries[i].dest_reg_addr 							<= dst_reg_addr			;
					RS_entries[i].control									<= control				;
					RS_entries[i].src_reg1_addr 							<= src_reg1_addr		;
					RS_entries[i].src_reg2_addr 							<= src_reg2_addr		;
					RS_entries[i].src_reg1_val								<= src_reg1_val			;
					RS_entries[i].src_reg2_val								<= src_reg2_val			;
					RS_entries[i].valid_entry								<= 1'b1					;
					RS_entries[i].immediate									<= immediate			;
					RS_entries[i].pc										<= pc_in				;
					RS_entries[i].new_inst_tag								<= new_inst_tag			;
					
					//if CDB give new values
					for(int cdb_idx=0 ; cdb_idx<`NUM_OF_FU ; cdb_idx++) begin
						//REG1
						if((src_reg1_addr == cdb_if.register_addr[cdb_idx]) && cdb_if.valid[cdb_idx]) begin
							RS_entries[i].src_reg1_val <= cdb_if.register_val[cdb_idx];
						end	
						//REG2
						if((src_reg2_addr == cdb_if.register_addr[cdb_idx]) && cdb_if.valid[cdb_idx]) begin
							RS_entries[i].src_reg2_val <= cdb_if.register_val[cdb_idx];
						end	
					end
				
					
					found_empty_RS_entry 				= 1'b1;
				end //if (!RS_busy[i] && !found_empty_RS_entry) 
			end //for(int i=0 ; i<RS_ENTRIES_NUM ; i++)
			
			
			//  ======================= Got new executed command -- update register ====================================
			for(int cdb_idx=0 ; cdb_idx<`NUM_OF_FU ; cdb_idx++) begin
				

				if(cdb_if.valid[cdb_idx] && cdb_ready) begin
					
					// update RS
					for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
						if((cdb_if.register_addr[cdb_idx] == RS_entries[i].src_reg1_addr ) && RS_entries[i].valid_entry) begin
							RS_entries[i].src_reg1_val <= cdb_if.register_val[cdb_idx];
						end
						if((cdb_if.register_addr[cdb_idx] == RS_entries[i].src_reg2_addr)  && RS_entries[i].valid_entry) begin
							RS_entries[i].src_reg2_val <= cdb_if.register_val[cdb_idx];
						end
					end //for
				end// if(CDB_IF.valid && CDB_IF.ready)
			end
		end //else
	end// always_ff @(posedge clk or posedge reset) begin
	

	
	
	//Dispatch Instruction to FU
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset == 1'b1 ) begin
			for(int i=0 ; i<FU_NUM ; i++) begin
				fu_if.valid[i]		<= 1'b0;
			end
		end
		
		else begin
			
			//Defaule vals
			for(int i=0 ; i<FU_NUM ; i++) begin
				fu_if.valid[i] <= 1'b0;
		    end
			
			for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
				if(rs_dispatch_en[i]) begin
					fu_if.valid[rs_fu_assign[i]]			<= 1'b1							;
					fu_if.control[rs_fu_assign[i]]			<= RS_entries[i].control		;
					fu_if.src1_reg_val[rs_fu_assign[i]]		<= RS_entries[i].src_reg1_val	;
					fu_if.src2_reg_val[rs_fu_assign[i]]		<= RS_entries[i].src_reg2_val	;
					fu_if.dst_reg_addr[rs_fu_assign[i]]		<= RS_entries[i].dest_reg_addr	;
					fu_if.immediate[rs_fu_assign[i]]		<= RS_entries[i].immediate		;	
					fu_if.pc[rs_fu_assign[i]]				<= RS_entries[i].pc				;
					fu_if.new_inst_tag[rs_fu_assign[i]]		<= RS_entries[i].new_inst_tag	;
				end
			end // for(int i=0 ; i<RS_ENTRIES_NUM ; i++) begin
		end //else begin
	end // always_ff @(posedge clk or posedge reset)


endmodule