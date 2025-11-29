/*------------------------------------------------------------------------------
 * File          : MEM_CONTROLLER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 27, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module MEM_CONTROLLER #() (
	input 										clk,
	input 										reset,
	
	// LSQ interface
	input 										lsq_req_valid,
	input memory_op_t							lsq_req_op,
	input [`D_MEMORY_ADDR_WIDTH-1:0]			lsq_req_address,
	input [`REG_VAL_WIDTH-1:0]					lsq_req_data,
	

	output										mem_ctrl_ready,
	output										mem_ctrl_done,
	output [`REG_VAL_WIDTH-1:0]					mem_ctrl_data,	
	
	// Memory Interfcae
	input 										memory_ready,
	input 										memory_ack,
	input [`REG_VAL_WIDTH-1:0]					memory_data_return,
	
	output	logic								memory_req_valid,
	output memory_op_t							memory_req_op,
	output logic [`D_MEMORY_ADDR_WIDTH-1:0]		memory_req_address,
	output logic [`REG_VAL_WIDTH-1:0]			memory_req_data
);


	typedef enum logic [2:0]{
		IDLE,
		WAIT_FOR_REQ,
		SEND_TO_MEM,
		WAIT_FOR_DONE,
		CLEAR_LSQ_ENTRY
	}	mem_ctrl_state_t;

	
	mem_ctrl_state_t 						state , next_state;
	
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
				next_state = (lsq_req_valid)? SEND_TO_MEM : WAIT_FOR_REQ;
			end
		
			SEND_TO_MEM : begin
				next_state = (memory_ready)? WAIT_FOR_DONE : SEND_TO_MEM;
			end
			
			WAIT_FOR_DONE : begin
				next_state = (memory_ack)? CLEAR_LSQ_ENTRY : WAIT_FOR_DONE;
			end
			
			CLEAR_LSQ_ENTRY : begin
				next_state = WAIT_FOR_REQ;
			end
			
			default : next_state = IDLE;
		endcase
	end
	
	/////////////////////////////////////
	
	logic [`REG_VAL_WIDTH-1:0]	data_recieved_from_mem   ;
	
	memory_op_t							captured_lsq_req_op;
	logic [`D_MEMORY_ADDR_WIDTH-1:0]	captured_lsq_req_address;
	logic [`REG_VAL_WIDTH-1:0]			captured_lsq_req_data;
	
	assign mem_ctrl_ready 	= (state == WAIT_FOR_REQ	)								;
	assign mem_ctrl_done 	= (state == CLEAR_LSQ_ENTRY	)								;
	assign mem_ctrl_data	= (state == CLEAR_LSQ_ENTRY)? data_recieved_from_mem : '0	;
	 
	
	
	
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			data_recieved_from_mem 		<= '0					;
			memory_req_valid			<= 1'b0					;
			memory_req_op      			<= no_mem_op			;
			memory_req_address 			<= '0					;
			memory_req_data    			<= '0					;
			captured_lsq_req_op 		<= no_mem_op			;
			captured_lsq_req_address 	<= '0					;
			captured_lsq_req_data		<= '0					;

		end
		else begin
			memory_req_valid			 <= 1'b0				;
			
			//Capture Transaction from LSQ
			if(lsq_req_valid && state == WAIT_FOR_REQ) begin
				captured_lsq_req_op 	<= lsq_req_op			;
				captured_lsq_req_address <= lsq_req_address		;
				captured_lsq_req_data	<= lsq_req_data			;
			end
			
			
			//Send transaction to Memory
			if(memory_ready && state == SEND_TO_MEM) begin
				memory_req_valid		<= 1'b1							;
				memory_req_op			<= captured_lsq_req_op			;
				memory_req_address		<= captured_lsq_req_address		;
				memory_req_data			<= captured_lsq_req_data		;
			end
			
			
			//Capture Returned Data from Memory
			if(memory_ack && state == WAIT_FOR_DONE) begin
				data_recieved_from_mem 	<= memory_data_return	;
			end
		end
		
	end
	



endmodule