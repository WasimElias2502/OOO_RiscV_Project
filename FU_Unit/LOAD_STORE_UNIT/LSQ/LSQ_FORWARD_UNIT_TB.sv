/*------------------------------------------------------------------------------
 * File          : LSQ_FORWARD_UNIT_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 27, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LSQ_FORWARD_UNIT_TB #() ();

	
	//Buffer Data
	 logic 			[`ROB_SIZE-1 :0] 					hit_address_indices;
	 memory_op_t 	[`ROB_SIZE-1 :0]				req_op_indices;
	 logic 			[`ROB_SIZE_WIDTH-1:0]				fill_ptr;
	
	//Request Data - Dispatched Inst
	 logic 			[`ROB_SIZE_WIDTH-1:0]				req_tag;
	 logic 												req_valid;
	 memory_op_t										req_op;
	
	 logic 			[`ROB_SIZE-1:0]						forward_indices	;
	 
	 
	 
	 
	 // Instantiate the Unit Under Test (DUT)
	 LSQ_FORWARD_UNIT lsq_forward_unit (
		 .hit_address_indices (hit_address_indices),
		 .req_op_indices      (req_op_indices),
		 .fill_ptr            (fill_ptr),
		 .req_tag             (req_tag),
		 .req_valid           (req_valid),
		 .req_op              (req_op),
		 .forward_indices         (forward_indices)
	 );
	 
	 
	 task set_lsq_op;
		 input [`ROB_SIZE_WIDTH-1:0] index;
		 input memory_op_t op;
		 input logic hit;
		 begin
			 req_op_indices[index] = op;
			 hit_address_indices[index] = hit;
		 end
	 endtask
	 
	 initial begin
		 // Initialize all signals
		 fill_ptr            = 0;
		 req_tag             = 0;
		 req_valid           = 0;
		 req_op              = no_mem_op;
		 hit_address_indices = 0;
		 req_op_indices      = 0;
		 
		 #10; // Initial state settling

		 // =========================================================================
		 // No Forwarding
		 // =========================================================================
		 
		 fill_ptr = 7; // Indices 4, 5, 6 are valid. 7 is empty.
		 req_tag  = 3; // The Load instruction itself is at index 3 (Oldest in this view)
		 req_op   = mem_read;
		 req_valid = 1;
		 
		 // 1. Setup Store at Index 4 (Older, Low Priority)
		 set_lsq_op(4, mem_write, 1); 
		 
		 // 2. Setup Store at Index 5 (Middle Priority)
		 set_lsq_op(5, mem_write, 1); 

		 // 3. Setup Store at Index 6 (Youngest, Highest Priority)
		 set_lsq_op(6, mem_write, 1); 
		 
		 #10;
		 hit_address_indices = 0;
		 #10;
		 // =========================================================================
		 // Forward to load operation with no wrap around
		 // =========================================================================
			
		 fill_ptr = 7; // Indices 4, 5, 6 are valid. 7 is empty.
		 req_tag  = 3; // The Load instruction itself is at index 3 (Oldest in this view)
		 req_op   = mem_read;
		 req_valid = 1;
		 
		 // 1. Setup Store at Index 4 (Older, Low Priority)
		 set_lsq_op(4, mem_write, 1); 
		 
		 // 2. Setup Store at Index 5 (Middle Priority)
		 set_lsq_op(5, mem_write, 1); 

		 // 3. Setup Store at Index 6 (Youngest, Highest Priority)
		 set_lsq_op(6, mem_write, 1); 
		 
		 // 3. Setup Store at Index 6 (Youngest, Highest Priority)
		 set_lsq_op(2, mem_write, 1);
		 
		 // 3. Setup Store at Index 6 (Youngest, Highest Priority)
		 set_lsq_op(1, mem_write, 1);
		 
		 #10;
		 hit_address_indices = 0;
		 #10;
		 
		 // =========================================================================
		 // Forward to load operation with wrap around
		 // =========================================================================
			
		 fill_ptr = 5; // Indices 4, 5, 6 are valid. 7 is empty.
		 req_tag  = 2; // The Load instruction itself is at index 3 (Oldest in this view)
		 req_op   = mem_read;
		 req_valid = 1;
		 
		 // 1. Setup Store at Index 4 (Older, Low Priority)
		 set_lsq_op(4, mem_write, 1); 
		 
		 // 2. Setup Store at Index 5 (Middle Priority)
		 set_lsq_op(7, mem_write, 1); 

		 // 3. Setup Store at Index 6 (Youngest, Highest Priority)
		 set_lsq_op(6, mem_write, 1); 
		 
		 #10
		 hit_address_indices = 0;
		 #10;
		 
		 // =========================================================================
		 // Forward to load operation with wrap around
		 // =========================================================================
			
		 fill_ptr = 2; // Indices 4, 5, 6 are valid. 7 is empty.
		 req_tag  = 0; // The Load instruction itself is at index 3 (Oldest in this view)
		 req_op   = mem_read;
		 req_valid = 1;
		 
		 // 1. Setup Store at Index 4 (Older, Low Priority)
		 set_lsq_op(5, mem_write, 1); 
		 set_lsq_op(1, mem_write, 1); 
		 set_lsq_op(2, mem_write, 1);
		 set_lsq_op(3, mem_write, 1); 
		 set_lsq_op(4, mem_write, 1); 
		 set_lsq_op(7, mem_read, 1); 
		 set_lsq_op(6, mem_read, 1); 



		 #10
		 hit_address_indices = 0;
		 #10;
		 
		 
		 // =========================================================================
		 // Forward to load operation with wrap around
		 // =========================================================================
			
		 fill_ptr = 6; // Indices 4, 5, 6 are valid. 7 is empty.
		 req_tag  = 3; // The Load instruction itself is at index 3 (Oldest in this view)
		 req_op   = mem_write;
		 req_valid = 1;
		 
		 set_lsq_op(5, mem_read, 1); 
		 set_lsq_op(2, mem_read, 1);
		 set_lsq_op(4, mem_read, 1);
		 set_lsq_op(1, mem_write, 1);
		 
		 #10;



		 $finish;
	 end

	

endmodule