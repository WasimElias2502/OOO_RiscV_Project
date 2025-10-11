`timescale 1ns/1ns

module RS_FU_SCHEDULER #(
	parameter int NUM_OF_RS,
	parameter int NUM_OF_FU ,
	parameter int FU_IDX_WIDTH = (NUM_OF_FU <= 1) ? 1 : $clog2(NUM_OF_FU)
) (
	input logic clk,
	input logic rst,
	input logic [NUM_OF_RS-1:0] rs_ready,
	input logic [NUM_OF_FU-1:0] fu_available,
	
	output logic [FU_IDX_WIDTH-1:0] rs_fu_assign [NUM_OF_RS-1:0],
	output logic [NUM_OF_RS-1:0] rs_dispatch_en
);

	logic [FU_IDX_WIDTH-1:0] rs_fu_idx_internal [NUM_OF_RS-1:0];
	logic [NUM_OF_FU-1:0] fu_assigned;


	always_comb begin
		
		if(rst) begin
			rs_dispatch_en = '0;
		end
	
		else begin
			
			//Default Values
			rs_dispatch_en = '0;
			fu_assigned    = '0;
			
			for (int i = 0; i < NUM_OF_RS; i++) begin
				rs_fu_idx_internal[i] = '0; 
			end
			
	
			for (int rs_idx = 0; rs_idx < NUM_OF_RS; rs_idx++) begin
	
				logic [FU_IDX_WIDTH-1:0] temp_fu_idx;
				logic                    assigned_to_rs; 
	
				temp_fu_idx    = '0;
				assigned_to_rs = 1'b0;
	
				if (rs_ready[rs_idx]) begin
					for (int fu_idx = 0; fu_idx < NUM_OF_FU; fu_idx++) begin
	
						if (fu_available[fu_idx] && !fu_assigned[fu_idx]) begin
							if (!assigned_to_rs) begin
								 temp_fu_idx = fu_idx;
								 assigned_to_rs = 1'b1;
							end
						end
					end 
				
					if (assigned_to_rs) begin
						rs_fu_idx_internal[rs_idx] = temp_fu_idx; 
						rs_dispatch_en[rs_idx] = 1'b1;
						fu_assigned[temp_fu_idx] = 1'b1; 
					end
				end 
			end 
	
			for (int i = 0; i < NUM_OF_RS; i++) begin
				rs_fu_assign[i] = rs_fu_idx_internal[i];
			end
		end
	end

endmodule