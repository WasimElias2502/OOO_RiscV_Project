/*------------------------------------------------------------------------------
 * File          : RS_UNIT_REG_STATUS.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 11, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module RS_UNIT_REG_STATUS #(

) (

	input 						reset,
	input 						clk,
	RS2REG_STATUS_IF.REG_STATUS reg_status_2_alu_rs_if,
	RS2REG_STATUS_IF.REG_STATUS reg_status_2_mem_rs_if
);

	

	RS_reg_status  								phy_reg_status_table [`PHYSICAL_REG_NUM-1:0];
	
	always_comb begin
		if(reset == 1'b1) begin
			for (int i=0 ; i<`PHYSICAL_REG_NUM ; i++) begin
				phy_reg_status_table[i] = valid;
			end
		end
		else begin
			
			//Send status to Reservation stations
			for (int i=0 ; i<`PHYSICAL_REG_NUM ; i++) begin
				reg_status_2_alu_rs_if.reg_status[i] = phy_reg_status_table[i];
			end
			
			
			//Update come from reservation station
			for (int i=0 ; i<`PHYSICAL_REG_NUM ; i++) begin
				if(reg_status_2_alu_rs_if.valid[i]) begin
					phy_reg_status_table[i] = reg_status_2_alu_rs_if.update_reg_status[i];
				end
				else if (reg_status_2_mem_rs_if.valid[i]) begin
					phy_reg_status_table[i] = reg_status_2_mem_rs_if.update_reg_status[i];
				end
			end

		end
	end


endmodule