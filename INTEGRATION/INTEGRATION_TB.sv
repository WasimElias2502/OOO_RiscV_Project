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
	
	IF2IDU_IF									IF2IDU_if();
	IDU2PHY_REGFILE_IF 							IDU2PHY_REGFILE_if();
	PHY_REGFILE2RS_IF							PHY_REGFILE2RS_if();
	FU_IF# ( .NUM_OF_FU(`NUM_OF_ALUS))			ALU_if();
	FU_IF# ( .NUM_OF_FU(`NUM_OF_MEM))			MEM_if();
	CDB_IF										CDB_if();
	
	
	
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
		.commit_valid				(commit_valid_TEST),
		.commit_with_write			(commit_with_write_TEST),
		.commited_wr_register		(commited_wr_register_TEST),
		.flush						(flush),
		.new_valid_in				(IF2IDU_if.valid_inst),
		
		.control					(IDU2PHY_REGFILE_if.control),
		.pc_out						(IDU2PHY_REGFILE_if.pc),
		.phy_read_reg_num1			(IDU2PHY_REGFILE_if.phy_read_reg_num1),
		.phy_read_reg_num2			(IDU2PHY_REGFILE_if.phy_read_reg_num2),
		.phy_write_reg_num			(IDU2PHY_REGFILE_if.phy_write_reg_num),
		.can_rename					(IF2IDU_if.can_rename),
		.generated_immediate		(IDU2PHY_REGFILE_if.generated_immediate),
		.new_valid_inst_out			(IDU2PHY_REGFILE_if.valid_inst)
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
		.valid_inst_in				(IDU2PHY_REGFILE_if.valid_inst),
		
		.src_val1					(PHY_REGFILE2RS_if.src_reg1_val),
		.src_val2					(PHY_REGFILE2RS_if.src_reg2_val),
		.src_phy_reg1_out			(PHY_REGFILE2RS_if.src_reg1_addr),
		.src_phy_reg2_out			(PHY_REGFILE2RS_if.src_reg2_addr),
		.dst_phy_reg_out			(PHY_REGFILE2RS_if.dst_reg_addr),
		.control_out				(PHY_REGFILE2RS_if.control),
		.pc_out						(pc_phyRegfile_rs),
		.generated_immediate_out	(PHY_REGFILE2RS_if.immediate),
		.valid_inst_out				(PHY_REGFILE2RS_if.new_valid_inst)

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
		.immediate					(PHY_REGFILE2RS_if.immediate),
		.new_valid_inst				(PHY_REGFILE2RS_if.new_valid_inst),
		.cdb_if						(CDB_if.slave),
		.alu_if						(ALU_if.RS),
		.mem_if						(MEM_if.RS)
	);
	
	
	//***************************** Branch Misprediction Unit Instantiation***************************************//

	BRANCH_MISPRED_UNIT branch_mispred_unit(
		.is_branch_op				(is_branch_op_TEST),
		.branch_taken				(is_branch_taken_TEST),
		
		.flush						(flush),
		.next_pc_sel				(next_pc_sel)
	);

	//****************************************** Stimulus********************************************************//
	
	task automatic simulate_single_alu(input int fu_id);
		
		
		$display("[%0t] Task forked for FU_ID = %0d. Now waiting for valid signal...", $time, fu_id);
		forever begin
			//if ALU is asserted with  inst
			@(posedge ALU_if.valid[fu_id]);
			
			//Make fu not ready for a couple of cycles starting from next cycle
			ALU_if.ready[fu_id] <= 1'b0;
			
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
	
	
			ALU_if.ready[fu_id] <= 1'b1;
		end
		
		
	endtask
	
	
	task automatic run_alus_parallel();
		fork
		  for (int i = 0; i < `NUM_OF_ALUS; i++) begin
			automatic int id = i; // needed to isolate loop variable
			fork
				simulate_single_alu(id);
			join_none
		  end
		join
	  endtask

	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#35 reset = 1'b0;
			#1000 reset = 1'b1;
		end
	

	
	initial 
		begin
			
			int i;
			
			ALU_if.ready =  {`NUM_OF_ALUS{1'b1}};
			MEM_if.ready =  {`NUM_OF_MEM{1'b1}};
			
			
			is_branch_op_TEST			= 1'b0		;
			is_branch_taken_TEST		= 1'b0		;
			commit_valid_TEST 			= 1'b0		;
			commit_with_write_TEST		= 1'b0		;
			commited_wr_register_TEST	= 0			;
		
			
			
			
			run_alus_parallel();
			 
			
		
			//#101
			//commit_valid_TEST 			= 1'b1		;
			//commit_with_write_TEST		= 1'b1		;
			//commited_wr_register_TEST	= 5			;
			//#40
			//commit_valid_TEST 			= 1'b1		;
			//commit_with_write_TEST		= 1'b1		;
			//commited_wr_register_TEST	= 6			;
			//#40
			//is_branch_op_TEST			= 1'b1		;
			//is_branch_taken_TEST		= 1'b1		;
			//#40
			//is_branch_op_TEST			= 1'b1		;
			//is_branch_taken_TEST		= 1'b0		;
		
			
			
			wait fork;

		end
	
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("INTEGRATION_TB_output_wave.vcd");
			$fsdbDumpvars(0,INTEGRATION_TB);
		end
	
	//end test after 500ns
	initial 
		#1500 $finish;

endmodule