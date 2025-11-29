/*------------------------------------------------------------------------------
 * File          : LOAD_STORE_UNIT_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 29, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LOAD_STORE_UNIT_WRAPPER #() (
	
	input 										clk,
	input 										reset,
	
	//Issue Interface
	input logic [`ROB_SIZE_WIDTH-1:0]			issued_tag,
	input logic 								issue_valid,
	input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	issue_reg_dst,
	input memory_op_t							issue_mem_op,
	
	//Connect to RS
	FU_IF.FU									rs_2_lsq_if,
	
	//Commit Interface 
	COMMIT_IF.slave								commit_if,
	
	//CDB interface
	CDB_IF.master								cdb_if,
	
	//Memory Interface
	MEM_IF.CPU									mem_if

);

	parameter MEMORY_CDB_IDX = `NUM_OF_ALUS;
	
	
		typedef enum logic [1:0]{
			WAIT_FOR_REQ,
			CALC_REQ_ADDR,
			SEND_TO_LSQ
		}	req_state_t;
		
		req_state_t								state, next_state;
		
		
		logic 									ld_st_ready						;									
		logic [`ROB_SIZE_WIDTH-1:0]				captured_req_tag				;
		logic [`REG_VAL_WIDTH-1:0]				captured_req_data				;
		logic [`D_MEMORY_ADDR_WIDTH-1:0]		captured_req_memory_addr		;
		logic 									req_valid						;
		logic									issue_mem_valid					;


	// ============================================ Load Store Unit Instantiation ============================================ //
	
		assign issue_mem_valid = issue_valid & (issue_mem_op == mem_write || issue_mem_op == mem_read);
		
		LOAD_STORE_UNIT load_store_unit(
			.clk					(clk),
			.reset					(reset),
			
			.issued_tag				(issued_tag),
			.issue_valid			(issue_mem_valid),
			.issue_reg_dst			(issue_reg_dst),
			.issue_mem_op			(issue_mem_op),
			
			.req_memory_addr		(captured_req_memory_addr),	
			.req_valid				(req_valid),										
			.req_tag				(captured_req_tag),							
			.req_data				(captured_req_data),										
			.ld_st_ready			(ld_st_ready),										
			
			.commited_tag			(commit_if.commit_tag),					 
			.commit_valid			(commit_if.commit_valid),				 
			
			.cdb_valid				(cdb_if.valid[MEMORY_CDB_IDX]),
			.cdb_register_addr		(cdb_if.register_addr[MEMORY_CDB_IDX]),
			.cdb_register_val		(cdb_if.register_val[MEMORY_CDB_IDX]),
			.cdb_inst_tag			(cdb_if.inst_tag[MEMORY_CDB_IDX]),
			
			.memory_ready			(mem_if.memory_ready),										
			.memory_ack				(mem_if.memory_ack),										
			.memory_data_return		(mem_if.memory_data_return),										
			.memory_req_valid		(mem_if.memory_req_valid),										
			.memory_req_op			(mem_if.memory_req_op),										
			.memory_req_address		(mem_if.memory_req_address),										
			.memory_req_data		(mem_if.memory_req_data)										

		);
		
		
	//===================================================== ALU Instantiation =================================================//
	
		logic									mem_alu_ready		;
		logic									alu_valid			;
		logic [`REG_VAL_WIDTH-1:0]				alu_result_val		;
		
		
		ALU 
			#(.LOW_LATENCY_CYCLES(1), 
			  .HIGH_LATENCY_CYCLES(1)
			) mem_address_alu  (
			
			.clk					(clk),
			.reset					(reset),
			.alu_ready				(mem_alu_ready),
			.rs_valid				(rs_2_lsq_if.valid[0]),
			.src_reg1_val			(rs_2_lsq_if.src1_reg_val[0]),
			.control				(rs_2_lsq_if.control[0]),
			.immediate				(rs_2_lsq_if.immediate[0]),
			
			.result_val				(alu_result_val),
			.alu_valid				(alu_valid),
			
			//TIEOFFS
			.src_reg2_val			('0),
			.dst_reg_addr			('0),
			.pc_in					('0),
			.new_inst_tag_in		('0),
			.result_addr			(),
			.pc_out					(),
			.branch_taken_out		(),
			.new_inst_tag_out		()
		
		);
		
	// ================================================== FSM to Handle Requests ============================================= //
	
		
		always_ff @(posedge clk or posedge reset) begin
			if(reset) begin
				state <= WAIT_FOR_REQ;
			end
			else begin
				state <= next_state;
			end
		end
		
		always_comb begin
			case (state)
				WAIT_FOR_REQ: begin
					next_state = (rs_2_lsq_if.valid[0])? CALC_REQ_ADDR : WAIT_FOR_REQ;
				end
				CALC_REQ_ADDR : begin
					next_state = (alu_valid)? SEND_TO_LSQ : CALC_REQ_ADDR;
				end
				SEND_TO_LSQ: begin
					next_state = WAIT_FOR_REQ ;
				end
				
			endcase
		end
		
		
	// =============================================== Assign Logic According to State ======================================= //
		
		// Ready 
		assign rs_2_lsq_if.ready[0]  = mem_alu_ready & ld_st_ready & (state == WAIT_FOR_REQ);
		
		//Capture Request
		always_ff  @(posedge clk or posedge reset) begin
			if(reset) begin
				captured_req_tag 			<= '0;
				captured_req_data 			<= '0;
				captured_req_memory_addr	<= '0;
			end
			else begin
				if(state == WAIT_FOR_REQ && rs_2_lsq_if.valid[0]) begin
					captured_req_tag 	<= rs_2_lsq_if.new_inst_tag[0]	;
					captured_req_data 	<= rs_2_lsq_if.src2_reg_val[0]	;
				end
				
				if(state == CALC_REQ_ADDR && alu_valid) begin
					captured_req_memory_addr <= alu_result_val		;
				end	
			end
		end
		
		//Send to CDB Valid
		assign req_valid 				= (state == SEND_TO_LSQ)	;
		
		
	

	// ======================================================== CDB tieoffs ================================================== //
	
		assign cdb_if.branch_taken_out[MEMORY_CDB_IDX] 		= 1'b0	;
		assign cdb_if.pc_out[MEMORY_CDB_IDX]				= '0	;
	

endmodule