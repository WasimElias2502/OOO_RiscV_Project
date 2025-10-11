/*------------------------------------------------------------------------------
 * File          : INTEGRATION_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 23, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module INTEGRATION_TB #(
	GENERATED_IMMEDIATE_WIDTH = `REG_VAL_WIDTH
) ();


	//reset & clk
	logic 										clk , reset							;
	
	//Physical Regfile to Reservation station wires
	logic 	[`REG_VAL_WIDTH-1:0]				src_val1_phyRegfile_rs				;
	logic 	[`REG_VAL_WIDTH-1:0]				src_val2_phyRegfile_rs				;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_read_reg_num1_phyRegfile_rs		;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_read_reg_num2_phyRegfile_rs		;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_write_reg_num_phyRegfile_rs		;
	control_t						  			control_phyRegfile_rs				;
	logic 	[`INST_ADDR_WIDTH-1:0] 				pc_phyRegfile_rs					;
	logic	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_phyRegfile_rs 	;
	
	
	//Branch Misprediction Unit wires
	next_pc_t 									next_pc_sel							;
	logic										flush								;
	
	//**************************************** Testing Signals **********************************************//
	
	logic 										commit_valid_TEST					;
	logic 										commit_with_write_TEST				;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0] 		commited_wr_register_TEST			;
	logic										is_branch_op_TEST					;
	logic										is_branch_taken_TEST				;
	
			

	//******************************************* Interfaces ************************************************// 
	
	IF2IDU_IF						IF2IDU_if();
	IDU2PHY_REGFILE_IF 				IDU2PHY_REGFILE_if();
	
	
	
	//*********************************** IFU Wrapper Instantiation *****************************************//
	
	IFU_WRAPPER fetch_unit (
		.clk						(clk),
		.reset						(reset),
		.next_pc_sel				(next_pc_sel),
		.SB_Type_addr				(0),
		.UJ_Type_addr				(0),
		.JALR_Type_addr				(0),
		.stall						(~IF2IDU_if.can_rename),
		.Instruction_Code			(IF2IDU_if.Instruction_Code),
		.pc_out						(IF2IDU_if.pc),
		.pc_plus_4_out				(IF2IDU_if.pc_plus_4)
	);
	

	//*********************************** IDU Wrapper Instantiation *****************************************//
	
	IDU_WRAPPER decode_unit (
		.clk						(clk),
		.reset						(reset),
		.Instruction_Code			(IF2IDU_if.Instruction_Code),
		.pc_in						(IF2IDU_if.pc),
		.pc_plus_4_in				(IF2IDU_if.pc_plus_4),
		.commit_valid				(commit_valid_TEST),
		.commit_with_write			(commit_with_write_TEST),
		.commited_wr_register		(commited_wr_register_TEST),
		.flush						(flush),
		.control					(IDU2PHY_REGFILE_if.control),
		.pc_out						(IDU2PHY_REGFILE_if.pc),
		.phy_read_reg_num1			(IDU2PHY_REGFILE_if.phy_read_reg_num1),
		.phy_read_reg_num2			(IDU2PHY_REGFILE_if.phy_read_reg_num2),
		.phy_write_reg_num			(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.can_rename					(IF2IDU_if.can_rename),
		.generated_immediate		(IDU2PHY_REGFILE_if.generated_immediate)
	);
	
	
	//****************************** Physical Register file Instantiation *************************************//
	
	PHY_REGFILE_WRAPPER phy_regfile(
		.clk						(clk),
		.reset						(reset),
		.src_phy_reg1_in			(IDU2PHY_REGFILE_if.phy_read_reg_num1),
		.src_phy_reg2_in			(IDU2PHY_REGFILE_if.phy_read_reg_num2),
		.wr_commit_reg				(0),
		.commit_wr_en				(0),
		.commit_wr_val				(0),
		.dst_phy_reg_in				(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.control_in					(IDU2PHY_REGFILE_if.control),
		.pc_in						(IDU2PHY_REGFILE_if.pc),
		.generated_immediate_in		(IDU2PHY_REGFILE_if.generated_immediate),
		.flush						(flush),
		
		.src_val1					(src_val1_phyRegfile_rs),
		.src_val2					(src_val2_phyRegfile_rs),
		.src_phy_reg1_out			(phy_read_reg_num1_phyRegfile_rs),
		.src_phy_reg2_out			(phy_read_reg_num2_phyRegfile_rs),
		.dst_phy_reg_out			(phy_write_reg_num_phyRegfile_rs),
		.control_out				(control_phyRegfile_rs),
		.pc_out						(pc_phyRegfile_rs),
		.generated_immediate_out	(generated_immediate_phyRegfile_rs)

	);
	
	
	//***************************** Branch Misprediction Unit Instantiation***************************************//

	BRANCH_MISPRED_UNIT branch_mispred_unit(
		.is_branch_op				(is_branch_op_TEST),
		.branch_taken				(is_branch_taken_TEST),
		
		.flush						(flush),
		.next_pc_sel				(next_pc_sel)
	);

	//****************************************** Stimulus********************************************************//
	
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#20 reset = 1'b0;
			#400 reset = 1'b1;
		end
	

	
	initial 
		begin
			is_branch_op_TEST			= 1'b0		;
			is_branch_taken_TEST		= 1'b0		;
			commit_valid_TEST 			= 1'b0		;
			commit_with_write_TEST		= 1'b0		;
			commited_wr_register_TEST	= 0			;
			#101
			commit_valid_TEST 			= 1'b1		;
			commit_with_write_TEST		= 1'b1		;
			commited_wr_register_TEST	= 5			;
			#40
			commit_valid_TEST 			= 1'b1		;
			commit_with_write_TEST		= 1'b1		;
			commited_wr_register_TEST	= 6			;
			#40
			is_branch_op_TEST			= 1'b1		;
			is_branch_taken_TEST		= 1'b1		;
			#40
			is_branch_op_TEST			= 1'b1		;
			is_branch_taken_TEST		= 1'b0		;
	
		end
	
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("INTEGRATION_TB_output_wave.vcd");
			$fsdbDumpvars(0,INTEGRATION_TB);
		end
	
	//end test after 500ns
	initial 
		#500 $finish;

endmodule