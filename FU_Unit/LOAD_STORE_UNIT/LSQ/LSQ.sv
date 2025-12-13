/*------------------------------------------------------------------------------
 * File          : LSQ.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LSQ #() (
	
	input logic									clk,
	input logic									reset,
	
	//Issue Interface
	input logic [`ROB_SIZE_WIDTH-1:0]			issued_tag,
	input logic 								issue_valid,
	input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	issue_reg_dst,
	input memory_op_t							issue_mem_op,
	
	//Request Memory Operation 
	input logic [`D_MEMORY_ADDR_WIDTH-1:0]		req_memory_addr,
	input logic									req_valid,
	input logic [`ROB_SIZE_WIDTH-1:0]			req_tag,
	input logic [`REG_VAL_WIDTH-1:0]			req_data,
	
	//Commit Interface
	input logic	[`ROB_SIZE_WIDTH-1:0]			commited_tag [`MAX_NUM_OF_COMMITS-1:0],
	input logic	[`MAX_NUM_OF_COMMITS-1:0]		commit_valid ,
	
	output logic 								lsq_ready,
	
	//Memory Controller Interface
	output 										lsq_req_valid,
	output memory_op_t							lsq_req_op,
	output [`D_MEMORY_ADDR_WIDTH-1:0]			lsq_req_address,
	output [`REG_VAL_WIDTH-1:0]					lsq_req_data,
	
	input 										mem_ctrl_ready,
	input										mem_ctrl_done,
	input [`REG_VAL_WIDTH-1:0]					mem_ctrl_data,
	
	//CDB interface
	output logic								cdb_valid,
	output logic[`PHYSICAL_REG_NUM_WIDTH-1:0] 	cdb_register_addr,
	output logic [`REG_VAL_WIDTH-1:0] 			cdb_register_val,
	output logic [`ROB_SIZE_WIDTH-1:0]			cdb_inst_tag,
	
	output logic 								clear_lsq_entry_valid,
	output logic [`ROB_SIZE_WIDTH-1:0]			clear_lsq_entry_tag
);

	typedef enum logic [1:0]{
		IDLE,
		WAIT_FOR_REQ,
		FORAWRD
	}	req_state_t;
	
	typedef enum logic [2:0] {
		WAIT_FOR_EXECUTE,
		EXECUTE_MEM_OP,
		WAIT_TO_FINISH_TRANS,
		SEND_TO_CDB,
		CLEAR_EXECUTE_ENTRY
	}	execute_state_t;
	
	
	req_state_t 							state , next_state					;
	execute_state_t							execute_state , next_execute_state	;
	logic [`ROB_SIZE_WIDTH-1:0]				curr_tag_req_forward				;
	logic									forward_req							;

	logic [`ROB_SIZE_WIDTH-1:0]				fill_ptr							;
	logic [`ROB_SIZE_WIDTH-1:0]				execute_ptr							;
	logic [`ROB_SIZE-1 :0] 					hit_address_indices					;
	memory_op_t [`ROB_SIZE-1 :0]			req_op_indices						;
	logic [`ROB_SIZE-1:0]					forward_indices						;
	
	logic									clear_entry							;

	//================================== Buffer Instantiation ======================================== //
	
	LSQ_entry_t 							LSQ_BUFFER [`ROB_SIZE-1:0];
	
	//=================================== Issue Instruction ========================================== //
			
		
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			for (int i = 0; i<`ROB_SIZE ; i++) begin
				LSQ_BUFFER[i].occupied 							<= 1'b0							;
				LSQ_BUFFER[i].req_mem_op_type					<= no_mem_op					;
				LSQ_BUFFER[i].req_reg_dst						<= '0							;			
				fill_ptr										<= '0							;

			end
		end
		else begin
			
			//Clear Entry
			if(clear_entry) begin
				LSQ_BUFFER[execute_ptr].occupied			<= 1'b0							;
			end
			
			//Issue
			if(issue_valid && !LSQ_BUFFER[issued_tag].occupied) begin
				LSQ_BUFFER[issued_tag].occupied					<= 1'b1							;
				LSQ_BUFFER[issued_tag].req_mem_op_type			<= issue_mem_op 				;
				LSQ_BUFFER[issued_tag].req_reg_dst				<= issue_reg_dst				;
				fill_ptr										<= (issued_tag + 1)%(`ROB_SIZE)	;
				
			end
						
		end
	end
	
	// =================================== FSM to process new Request ================================= //
	
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end
	end
	
	//FSM state transition
	always_comb begin
			case (state)
				
				IDLE : begin
					next_state = WAIT_FOR_REQ;
				end
				
				WAIT_FOR_REQ : begin
					next_state = (req_valid)? FORAWRD : WAIT_FOR_REQ;
				end
			
				FORAWRD : begin
					next_state = WAIT_FOR_REQ;
				end
				default : next_state = IDLE;
			endcase
	end
	
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			for (int i = 0; i<`ROB_SIZE ; i++) begin
				LSQ_BUFFER[i].dispatched								<= 1'b0							;
				LSQ_BUFFER[i].was_forwarded								<= 1'b0							;
				LSQ_BUFFER[i].req_address								<= '0							;
				LSQ_BUFFER[i].store_req_data							<= '0							;
				LSQ_BUFFER[i].fw_load_req_data							<= '0							;
				curr_tag_req_forward									<= '0							;
				
			end
		end
		
		else begin
			
			//Clear Entry
			if(clear_entry) begin
				LSQ_BUFFER[execute_ptr].dispatched					<= 1'b0							;
				LSQ_BUFFER[execute_ptr].was_forwarded				<= 1'b0							;
			end
			
			case (state)
				IDLE		: begin
					for(int i=0 ; i<`ROB_SIZE ; i++) begin
						LSQ_BUFFER[i].dispatched						<= 	1'b0						;
						LSQ_BUFFER[i].was_forwarded						<= 	1'b0						;
					end
				end
				WAIT_FOR_REQ: begin
					
					if(req_valid) begin
						LSQ_BUFFER[req_tag].req_address					<= req_memory_addr				;
						LSQ_BUFFER[req_tag].store_req_data				<= req_data						;
						LSQ_BUFFER[req_tag].dispatched					<= 1'b1							;
						curr_tag_req_forward							<= req_tag						;
					end
				end
				
				FORAWRD: begin
						
						//forward for Load
						if(LSQ_BUFFER[curr_tag_req_forward].req_mem_op_type == mem_read) begin
							for(int i = 0; i < `ROB_SIZE; i = i + 1) begin
								if(forward_indices[i]) begin
									LSQ_BUFFER[curr_tag_req_forward].fw_load_req_data		<= LSQ_BUFFER[i].store_req_data		;
									LSQ_BUFFER[curr_tag_req_forward].was_forwarded			<= 1'b1								;
								end
							end
						end
						
						//forward store
						if(LSQ_BUFFER[curr_tag_req_forward].req_mem_op_type == mem_write) begin
							for(int i=0 ; i<`ROB_SIZE ; i = i+1) begin
								
								//forward instruction store to load
								if(forward_indices[i]) begin
									LSQ_BUFFER[i].fw_load_req_data						<= LSQ_BUFFER[curr_tag_req_forward].store_req_data 	;
									LSQ_BUFFER[i].was_forwarded							<= 1'b1													;
								end
							end
						end
				end
			
			
			endcase
		end
	end
	
	assign forward_req = (state == FORAWRD);
	assign lsq_ready  = (next_state != FORAWRD);
	
	
	//================================== LSQ Forward Unit Instantiation ======================================== //
	
	
	generate
		for (genvar i = 0; i < `ROB_SIZE; i = i + 1) begin : HIT_ADDR_CMP
			assign hit_address_indices[i] 	= LSQ_BUFFER[i].occupied & (LSQ_BUFFER[i].req_address == req_memory_addr);
			assign req_op_indices[i] 		= LSQ_BUFFER[i].req_mem_op_type;
		end
	endgenerate
	
	
	LSQ_FORWARD_UNIT lsq_forward_unit(
	
		.hit_address_indices(hit_address_indices),
		.req_op_indices		(req_op_indices),
		.fill_ptr			(fill_ptr),
		.req_tag			(curr_tag_req_forward),
		.req_valid			(forward_req),
		.req_op				(LSQ_BUFFER[curr_tag_req_forward].req_mem_op_type),
		.forward_indices	(forward_indices)
	
	);
	
	

	
	// ========================================= Update execute pointer =================================================== //
	
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			execute_ptr <= '0;
		end
		
		else begin
			
			bit found_execute;
			found_execute = 1'b0;
			
			for(int i=0 ; i<`ROB_SIZE ; i++) begin
				
				bit [`ROB_SIZE_WIDTH-1:0] idx ;
				idx = (execute_ptr + i) % (`ROB_SIZE);
				
				if(LSQ_BUFFER[idx].occupied  && !found_execute) begin
					found_execute 	= 1; //Stop Searching for executed instruction
					execute_ptr 	<= idx;
				end
				
			end
			
		end
	end
	
	
	
	// =========================================== Update Ready to execute ================================================= //
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			for (int i = 0; i<`ROB_SIZE ; i++) begin
				LSQ_BUFFER[i].ready_to_execute						<= 1'b0;
			end
		end
		else begin
			//Load 
			if(LSQ_BUFFER[execute_ptr].occupied && LSQ_BUFFER[execute_ptr].dispatched && (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_read)) begin
				LSQ_BUFFER[execute_ptr].ready_to_execute			<= 1'b1;
			end	
			
			//Store
			for(int i=0 ; i< `MAX_NUM_OF_COMMITS ; i++) begin
				if(LSQ_BUFFER[commited_tag[i]].occupied && LSQ_BUFFER[commited_tag[i]].dispatched && LSQ_BUFFER[commited_tag[i]].req_mem_op_type == mem_write && commit_valid[i]) begin
						LSQ_BUFFER[commited_tag[i]].ready_to_execute		<= 1'b1;
				end
			end
			
			//Clear Entry
			if(clear_entry) begin
				LSQ_BUFFER[execute_ptr].ready_to_execute		<= 1'b0							;
			end
			
		end
		
	end
	
	//============================================= Send To Mem Controller ==================================================== //
	logic  ready_to_send_memory ;
	assign ready_to_send_memory = LSQ_BUFFER[execute_ptr].ready_to_execute && !LSQ_BUFFER[execute_ptr].was_forwarded && mem_ctrl_ready;
		
	//Mem Controller Interface
	assign lsq_req_valid 	= (execute_state == EXECUTE_MEM_OP);
	assign lsq_req_op	 	= (execute_state == EXECUTE_MEM_OP)? LSQ_BUFFER[execute_ptr].req_mem_op_type :	no_mem_op	;
	assign lsq_req_address 	= (execute_state == EXECUTE_MEM_OP)? LSQ_BUFFER[execute_ptr].req_address	 : '0			;
	assign lsq_req_data		= (execute_state == EXECUTE_MEM_OP)? LSQ_BUFFER[execute_ptr].store_req_data	 : '0			;
		
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			for (int i = 0; i<`ROB_SIZE ; i++) begin
				LSQ_BUFFER[i].completed				<= 1'b0					;
				LSQ_BUFFER[i].load_req_data			<= '0					;
			end
		end
		else begin

				LSQ_BUFFER[execute_ptr].completed			<= 1'b0				;
				
			if(execute_state == WAIT_TO_FINISH_TRANS) begin
				
				if(LSQ_BUFFER[execute_ptr].was_forwarded && LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_read) begin
					LSQ_BUFFER[execute_ptr].completed		<= 1'b1				;
				end
				
				else if(mem_ctrl_done && LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_read) begin
					LSQ_BUFFER[execute_ptr].load_req_data 	<= mem_ctrl_data 	;
					LSQ_BUFFER[execute_ptr].completed		<= 1'b1				;
				end
				
				else if(mem_ctrl_done && LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write) begin
					LSQ_BUFFER[execute_ptr].completed		<= 1'b1				;
				end
			end
			
			if(clear_entry) begin
				LSQ_BUFFER[execute_ptr].completed	<= 1'b0				;
			end
		end
	end
	
	
	//============================================ Send Result to Result to CDB ================================================= //
	logic  can_send_store_to_cdb;
	assign can_send_store_to_cdb = (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write)
									&& LSQ_BUFFER[execute_ptr].dispatched 
									&& LSQ_BUFFER[execute_ptr].occupied
									&& mem_ctrl_ready;
	
	logic  store_wait_to_exe;

	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			cdb_valid					<= 1'b0	;
			cdb_register_addr			<= '0	;
			cdb_register_val			<= '0	;
			cdb_inst_tag				<= '0	;
		end
		else begin
			
			cdb_valid					<= 1'b0	;
			cdb_register_addr			<= '0	;
			cdb_register_val			<= '0	;
			cdb_inst_tag				<= '0	;
			
			if(execute_state == SEND_TO_CDB) begin
				cdb_inst_tag				<= execute_ptr	;
				cdb_valid					<= 1'b1 		;
				cdb_register_val 			<= (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write)? '0 : 
													( LSQ_BUFFER[execute_ptr].was_forwarded )? LSQ_BUFFER[execute_ptr].fw_load_req_data 
														: LSQ_BUFFER[execute_ptr].load_req_data;
				
				cdb_register_addr 			<= (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write)? '0 :  LSQ_BUFFER[execute_ptr].req_reg_dst;
			end
		end
	end
	
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			store_wait_to_exe <= 1'b0;
		end
		
		else begin
			if(execute_state == SEND_TO_CDB) begin
					store_wait_to_exe <= (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write) ;
			end
			
			else if (execute_state == EXECUTE_MEM_OP) begin
				store_wait_to_exe	 <= ~(LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write)  ;
			end
		end
		
		
	end
	
	// ===================================================== Clear Entry ========================================================= //
	
	assign clear_entry = (execute_state == CLEAR_EXECUTE_ENTRY);
	
	assign clear_lsq_entry_valid = clear_entry;
	assign clear_lsq_entry_tag  = (clear_entry)? execute_ptr : '0;
	
	// ================================================ FSM for Execute State =================================================== // 


	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			execute_state					<= WAIT_FOR_EXECUTE;
		end
		else begin
			execute_state 					<= next_execute_state;
		end
	end
	
	always_comb begin
		
		case(execute_state)
			
			
			WAIT_FOR_EXECUTE: begin

				if(LSQ_BUFFER[execute_ptr].was_forwarded) begin
					next_execute_state = WAIT_TO_FINISH_TRANS;
				end
				else if(ready_to_send_memory) begin
					next_execute_state = EXECUTE_MEM_OP ;
				end
				else if (can_send_store_to_cdb && !store_wait_to_exe) begin
					next_execute_state = SEND_TO_CDB	;
				end
				else begin
					next_execute_state = WAIT_FOR_EXECUTE;
				end
			end
			EXECUTE_MEM_OP: begin
				next_execute_state = (LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write)? CLEAR_EXECUTE_ENTRY : WAIT_TO_FINISH_TRANS;
			end
			
			WAIT_TO_FINISH_TRANS: begin
				next_execute_state = (LSQ_BUFFER[execute_ptr].completed)? SEND_TO_CDB : WAIT_TO_FINISH_TRANS ;
			end
			
			SEND_TO_CDB: begin
				if(LSQ_BUFFER[execute_ptr].req_mem_op_type == mem_write) begin
					next_execute_state = WAIT_FOR_EXECUTE;
				end
				else begin
					next_execute_state = CLEAR_EXECUTE_ENTRY;
				end
			end
			CLEAR_EXECUTE_ENTRY: begin
				next_execute_state = WAIT_FOR_EXECUTE;
			end
			
		endcase	
	end
	
	
	
	
endmodule