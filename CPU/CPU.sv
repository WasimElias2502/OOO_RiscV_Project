/*------------------------------------------------------------------------------
 * File          : CPU.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module CPU #() (
	//reset & clk
	input 										clk ,
	input 										reset,
	ARCH_REG_READ_IF.slave						ARCH_REG_READ_if

);

	//Branch Misprediction Unit wires
	next_pc_t 									next_pc_sel							;
	logic										flush								;
	
	//**************************************** Testing Signals **********************************************//
	logic										is_branch_op_TEST										;
	logic										is_branch_taken_TEST									;
	logic										stall_TEST												; //TODO: rs_full or branch or rob full
	
	assign is_branch_op_TEST = 1'b0;
	assign is_branch_taken_TEST = 1'b0;
	
			
	
	//******************************************* Interfaces ************************************************// 
	
	IF2IDU_IF									IF2IDU_if();
	IDU2PHY_REGFILE_IF 							IDU2PHY_REGFILE_if();
	PHY_REGFILE2RS_IF							PHY_REGFILE2RS_if();
	FU_IF# ( .NUM_OF_FU(`NUM_OF_ALUS))			ALU_if();
	FU_IF# ( .NUM_OF_FU(`NUM_OF_MEM))			MEM_if();
	CDB_IF										CDB_if();
	COMMIT_IF 									COMMIT_if();
	logic										rob_full; 	
	
	
	//*********************************** IFU Wrapper Instantiation *****************************************//
	
	IFU_WRAPPER fetch_unit (
		.clk						(clk),
		.reset						(reset),
		.next_pc_sel				(next_pc_sel),
		.SB_Type_addr				(0),
		.UJ_Type_addr				(0),
		.JALR_Type_addr				(0),
		.stall						(~IF2IDU_if.can_rename | rob_full),
		.Instruction_Code			(IF2IDU_if.Instruction_Code),
		.pc_out						(IF2IDU_if.pc),
		.pc_plus_4_out				(IF2IDU_if.pc_plus_4),
		.new_valid_inst				(IF2IDU_if.valid_inst)
	);
	
	
	//*********************************** IDU Wrapper Instantiation *****************************************//
	
	IDU_WRAPPER decode_unit (
		.clk						(clk),
		.reset						(reset),
		.Instruction_Code			(IF2IDU_if.Instruction_Code),
		.pc_in						(IF2IDU_if.pc),
		.pc_plus_4_in				(IF2IDU_if.pc_plus_4),
		.commit_valid				(COMMIT_if.commit_valid),
		.commit_type				(COMMIT_if.commit_type),								
		.commited_wr_register		(COMMIT_if.commit_phy_reg_addr),
		.commit_tag					(COMMIT_if.commit_tag),
		.flush						(flush),
		.new_valid_in				(IF2IDU_if.valid_inst),
		.stall						(0),
		
		.rob_full					(rob_full),
		.inst_tag					(IDU2PHY_REGFILE_if.inst_tag),
		.control					(IDU2PHY_REGFILE_if.control),
		.pc_out						(IDU2PHY_REGFILE_if.pc),
		.phy_read_reg_num1			(IDU2PHY_REGFILE_if.phy_read_reg_num1),
		.phy_read_reg_num2			(IDU2PHY_REGFILE_if.phy_read_reg_num2),
		.phy_write_reg_num			(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.dest_arch_register			(IDU2PHY_REGFILE_if.dest_arch_register),
		.can_rename					(IF2IDU_if.can_rename),
		.generated_immediate		(IDU2PHY_REGFILE_if.generated_immediate),
		.new_valid_inst_out			(IDU2PHY_REGFILE_if.valid_inst)
	);
	
	
	//****************************** Architecture Register file Instantiation *************************************//
	
	ARCH_REGFILE_WRAPPER arch_regfile(
		.clk						(clk),
		.reset						(reset),
		.commit_if					(COMMIT_if.slave),
		.read_regs_if				(ARCH_REG_READ_if)
	);
	
	
	//****************************** Physical Register file Instantiation *************************************//
	
	PHY_REGFILE_WRAPPER phy_regfile(
		.clk						(clk),
		.reset						(reset),
		.src_phy_reg1_in			(IDU2PHY_REGFILE_if.phy_read_reg_num1),
		.src_phy_reg2_in			(IDU2PHY_REGFILE_if.phy_read_reg_num2),
		.CDB_if						(CDB_if.slave),
		.dst_phy_reg_in				(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.control_in					(IDU2PHY_REGFILE_if.control),
		.pc_in						(IDU2PHY_REGFILE_if.pc),
		.generated_immediate_in		(IDU2PHY_REGFILE_if.generated_immediate),
		.inst_tag_in				(IDU2PHY_REGFILE_if.inst_tag),
		.flush						(flush),
		.valid_inst_in				(IDU2PHY_REGFILE_if.valid_inst),
		.stall						(0),
		
		
		.src_val1					(PHY_REGFILE2RS_if.src_reg1_val),
		.src_val2					(PHY_REGFILE2RS_if.src_reg2_val),
		.src_phy_reg1_out			(PHY_REGFILE2RS_if.src_reg1_addr),
		.src_phy_reg2_out			(PHY_REGFILE2RS_if.src_reg2_addr),
		.dst_phy_reg_out			(PHY_REGFILE2RS_if.dst_reg_addr),
		.control_out				(PHY_REGFILE2RS_if.control),
		.pc_out						(PHY_REGFILE2RS_if.pc),
		.generated_immediate_out	(PHY_REGFILE2RS_if.immediate),
		.valid_inst_out				(PHY_REGFILE2RS_if.new_valid_inst),
		.inst_tag_out				(PHY_REGFILE2RS_if.inst_tag)
	
	);
	
	//************************************ Reservation Station Unit **********************************************//
	
	RS_UNIT_WRAPPER reservation_stations_unit(
		.clk						(clk),
		.reset						(reset),
		.control					(PHY_REGFILE2RS_if.control),
		.src_reg1_val				(PHY_REGFILE2RS_if.src_reg1_val),
		.src_reg2_val				(PHY_REGFILE2RS_if.src_reg2_val),
		.dst_reg_addr				(PHY_REGFILE2RS_if.dst_reg_addr),
		.src_reg1_addr				(PHY_REGFILE2RS_if.src_reg1_addr),
		.src_reg2_addr				(PHY_REGFILE2RS_if.src_reg2_addr),
		.new_inst_tag				(PHY_REGFILE2RS_if.inst_tag),
		.immediate					(PHY_REGFILE2RS_if.immediate),
		.new_valid_inst				(PHY_REGFILE2RS_if.new_valid_inst),
		.pc_in						(PHY_REGFILE2RS_if.pc),
		.cdb_if						(CDB_if.slave),
		.alu_if						(ALU_if.RS),
		.mem_if						(MEM_if.RS)		
	);
	
	//***************************************** Functional Units *************************************************//
	
	FU_UNIT_WRAPPER functional_units(
		.clk						(clk),
		.reset						(reset),
		.alu_if						(ALU_if.FU),
		.cdb_if						(CDB_if.master)
	);
	
	//************************************* Re Order Buffer Unit *************************************************//
	
	ROB rob (
		.clk						(clk),
		.reset						(reset),
		.cdb_if						(CDB_if.slave),
		.inst_tag					(IDU2PHY_REGFILE_if.inst_tag),
		.dest_arch_register			(IDU2PHY_REGFILE_if.dest_arch_register),
		.dest_phy_register			(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.valid_inst_to_register		(IDU2PHY_REGFILE_if.valid_inst),
		.control_in					(IDU2PHY_REGFILE_if.control),
		
		.commit_if					(COMMIT_if.master)
	);

	//***************************** Branch Misprediction Unit Instantiation***************************************//
	
	BRANCH_MISPRED_UNIT branch_mispred_unit(
		.is_branch_op				(is_branch_op_TEST),
		.branch_taken				(is_branch_taken_TEST),
		
		.flush						(flush),
		.next_pc_sel				(next_pc_sel)
	);


endmodule