/*------------------------------------------------------------------------------
 * File          : RS_UNIT_REG_STATUS.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 11, 2025
 * Description   : 
 *------------------------------------------------------------------------------*/

module RS_UNIT_REG_STATUS #(
	parameter PHYSICAL_REG_NUM = `PHYSICAL_REG_NUM
) (
	input  logic                      	clk,
	input  logic                      	reset,
	
	input	logic					  	new_valid_inst,
	input [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr, 						
	RS2REG_STATUS_IF.REG_STATUS       	reg_status_2_alu_rs_if,
	RS2REG_STATUS_IF.REG_STATUS       	reg_status_2_mem_rs_if,
	CDB_IF.slave						cdb_if
);

	logic phy_reg_status_table [PHYSICAL_REG_NUM-1:0];

	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			// On reset, mark all physical registers as valid
			for (int i = 0; i < PHYSICAL_REG_NUM; i++) begin
				phy_reg_status_table[i] <= valid;
			end
		end
		else begin
			
			// Update register status from CDB
			for(int cdb_idx=0 ; cdb_idx<`NUM_OF_FU ; cdb_idx++) begin
				if(cdb_if.valid[cdb_idx]) begin
					phy_reg_status_table[cdb_if.register_addr[cdb_idx]]  	<= valid 	 ;
				end
			end
			
			//If new instruction came TODO: check when to check if dst reg is used in certain instructions
			if(new_valid_inst) begin
				phy_reg_status_table[dst_reg_addr]  		<= not_valid 	 ;
			end
			
		end
	end


	always_comb begin
		for (int i = 0; i < PHYSICAL_REG_NUM; i++) begin
			reg_status_2_alu_rs_if.reg_status[i] = phy_reg_status_table[i];
			reg_status_2_mem_rs_if.reg_status[i] = phy_reg_status_table[i];
		end
	end

endmodule
