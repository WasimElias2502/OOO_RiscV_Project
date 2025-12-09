/*------------------------------------------------------------------------------
 * File          : D_MEMORY.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module D_MEMORY #() (
	
	input logic 								clk,
	input logic 								reset,
	//Memory interface
	output logic								memory_ready,
	output logic								memory_ack,
	output logic [`REG_VAL_WIDTH-1:0]			memory_data_return,
	
	input logic									memory_req_valid,
	input memory_op_t							memory_req_op,
	input logic [`D_MEMORY_ADDR_WIDTH-1:0]		memory_req_address,
	input logic [`REG_VAL_WIDTH-1:0]			memory_req_data
);

	
	logic [`MEMORY_DELAY_WIDTH-1:0] 			delay_cntr			;
	logic 										inc_delay 			;
	logic 										cntr_maxed 			;
	
	logic [`D_MEMORY_ADDR_WIDTH-1:0]			captured_address 	;
	logic [`REG_VAL_WIDTH-1:0]					captured_store_data ;
	memory_op_t									captured_op			;
	
	// ***************************************** MemoryN ****************************************** //
	
	reg [`REG_VAL_WIDTH-1:0] MEMORY [`D_MEMORY_SIZE-1:0];
	
	// *********************************** FSM Instantiation ************************************* //
	
	typedef enum logic [1:0]{
		WAIT_FOR_REQ,
		FETCH_ADDR,
		VALUE_READY
	}	mem_state_t;
		
	mem_state_t 						state , next_state;
	
	
	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			state <= WAIT_FOR_REQ;
		end
		else begin
			state <= next_state;
		end
	end
	
	//FSM state transition
	always_comb begin
		case (state)
			WAIT_FOR_REQ : begin
				next_state = (memory_req_valid)? FETCH_ADDR : state;
			end
		
			FETCH_ADDR : begin
				next_state = (delay_cntr == `MEMORY_DELAY-1)? VALUE_READY : state;
			end
			
			VALUE_READY : begin
				next_state = WAIT_FOR_REQ;
			end
			default : next_state = WAIT_FOR_REQ;
		endcase
	end
	
	// ************************************* Logic Implementation ************************************* //
	
	//COUNTER implementation
	COUNTER #(.WIDTH(`MEMORY_DELAY_WIDTH))
		delay_counter( 
			.clk				(clk),
			.reset				(reset),
			.en					(inc_delay),
			.init_cntr			(cntr_maxed),
			.count				(delay_cntr)
	
		);
	
	assign cntr_maxed 	= (state == VALUE_READY);
	assign inc_delay	= (state == FETCH_ADDR);
	assign memory_ready = (state == WAIT_FOR_REQ ) && (next_state == WAIT_FOR_REQ );
	assign memory_ack	= (state == VALUE_READY);
	
	assign memory_data_return = MEMORY[captured_address];
	
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			captured_address 		<= '0			;
			captured_store_data		<= '0			;
			captured_op				<= no_mem_op	;
		end
		else begin
			if(state == WAIT_FOR_REQ) begin
				if(memory_req_valid) begin
					captured_address 		<= memory_req_address			;
					captured_store_data		<= memory_req_data				;
					captured_op				<= memory_req_op				;
				end
			end
		end
	end
	
	always_ff @(posedge clk or posedge reset) begin
		
		if(reset) begin
			for (int i=0 ; i< `D_MEMORY_SIZE ; i++) begin
				MEMORY[i] 			<= '0			;	
			end
		end
		
		else begin
			if(captured_op == mem_write && state == VALUE_READY) begin
				MEMORY[captured_address] 	<= captured_store_data;
			end
		end
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

endmodule