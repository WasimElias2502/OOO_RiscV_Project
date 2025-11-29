/*------------------------------------------------------------------------------
 * File          : LSQ_FORWARD_UNIT.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 27, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LSQ_FORWARD_UNIT #() (

	//Buffer Data
	input logic [`ROB_SIZE-1 :0] 					hit_address_indices,
	input memory_op_t [`ROB_SIZE-1 :0]				req_op_indices,
	input logic [`ROB_SIZE_WIDTH-1:0]				fill_ptr,
	
	//Request Data - Dispatched Inst
	input logic [`ROB_SIZE_WIDTH-1:0]				req_tag,
	input logic 									req_valid,
	input memory_op_t								req_op,
	
	output logic [`ROB_SIZE-1:0]					forward_indices	

);

	
	always_comb  begin
		//Default
		forward_indices 	= '0;
		
		for(int i=0 ; i<`ROB_SIZE ; i++) begin
			bit [`ROB_SIZE_WIDTH-1:0]  	curr_idx ;
			bit 						is_before_req;

			curr_idx= (fill_ptr + i) % (`ROB_SIZE);
						
			//Determine if index is before the current request tag			
			if((fill_ptr > req_tag && (curr_idx > fill_ptr || curr_idx < req_tag))
					|| (fill_ptr < req_tag && (curr_idx > fill_ptr && curr_idx < req_tag))) begin
				is_before_req 		= 1'b1;
			end
			
			else begin
				is_before_req 		= 1'b0;
			end
			
			//If request is Load look for older Stores
			if(req_op == mem_read) begin
				//Determine which tag to forward
				if(hit_address_indices[curr_idx] && is_before_req && req_op_indices[curr_idx] == mem_write && req_valid) begin
					forward_indices 				= 1 << curr_idx;
				end
			end
			
			//If request is store update younger loads
			else if (req_op == mem_write) begin
				if(hit_address_indices[curr_idx] && !is_before_req && req_op_indices[curr_idx] == mem_read && req_valid) begin
					forward_indices[curr_idx]		= 1'b1;
				end
			end
			
		end
		
	end



endmodule