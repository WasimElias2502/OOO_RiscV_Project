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

	
	//IFU to IDU wires
	bit 	[31:0] 								Instruction_Code [`FETCH_WIDTH-1:0]	;
	bit 	[`INST_ADDR_WIDTH-1:0] 				pc_ifu_idu							;
	bit 	[`INST_ADDR_WIDTH-1:0] 				pc_plus_4							; 
	
	//IDU to IFU wires
	logic 						      			can_rename;
	
	//IDU to Physical register wires
	logic 	[`INST_ADDR_WIDTH-1:0] 				pc_idu_phyRegfile					;
	control_t						  			control_idu_phyRegfile				;	
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0] 		phy_read_reg_num1_idu_phyRegfile	; 			// ***************** physical ***************//
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0] 		phy_read_reg_num2_idu_phyRegfile	;			// ******************** W/R *****************//
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0] 		phy_write_reg_num_idu_phyRegfile	;			// **************** registers****************//
	logic 	[GENERATED_IMMEDIATE_WIDTH-1:0] 		generated_immediate_idu_phyRegfile	;
	
	//Physical Regfile to Reservation station wires
	logic 	[`REG_VAL_WIDTH-1:0]				src_val1_phyRegfile_rs				;
	logic 	[`REG_VAL_WIDTH-1:0]				src_val2_phyRegfile_rs				;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_read_reg_num1_phyRegfile_rs		;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_read_reg_num2_phyRegfile_rs		;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	phy_write_reg_num_phyRegfile_rs		;
	control_t						  			control_phyRegfile_rs				;
	logic 	[`INST_ADDR_WIDTH-1:0] 				pc_phyRegfile_rs					;
	logic	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_phyRegfile_rs 	;
	
	
	//ALU to IFU wires
	reg[1:0] 									next_pc_sel;
	
	//**************************************** Testing Signals **********************************************//
	
	logic 										commit_valid_TEST					;
	logic 										commit_with_write_TEST				;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0] 		commited_wr_register_TEST			;
			

	
	
	
	
	
	//*********************************** IFU Wrapper Instantiation *****************************************//
	
	IFU_WRAPPER fetch_unit (
		.clk						(clk),
		.reset						(reset),
		.next_pc_sel				(next_pc_sel),
		.SB_Type_addr				(0),
		.UJ_Type_addr				(0),
		.JALR_Type_addr				(0),
		.stall						(~can_rename),
		.Instruction_Code			(Instruction_Code),
		.pc_out						(pc_ifu_idu),
		.pc_plus_4_out				(pc_plus_4)
	);
	

	//*********************************** IDU Wrapper Instantiation *****************************************//
	
	IDU_WRAPPER decode_unit (
		.clk						(clk),
		.reset						(reset),
		.Instruction_Code			(Instruction_Code),
		.pc_in						(pc_ifu_idu),
		.pc_plus_4_in				(pc_plus_4),
		.commit_valid				(commit_valid_TEST),
		.commit_with_write			(commit_with_write_TEST),
		.commited_wr_register		(commited_wr_register_TEST),
		.control					(control_idu_phyRegfile),
		.pc_out						(pc_idu_phyRegfile),
		.phy_read_reg_num1			(phy_read_reg_num1_idu_phyRegfile),
		.phy_read_reg_num2			(phy_read_reg_num2_idu_phyRegfile),
		.phy_write_reg_num			(phy_write_reg_num_idu_phyRegfile),
		.can_rename					(can_rename),
		.generated_immediate		(generated_immediate_idu_phyRegfile)
	);
	
	
	//****************************** Physical Register file Instantiation *************************************//
	
	PHY_REGFILE_WRAPPER phy_regfile(
		.clk						(clk),
		.reset						(reset),
		.src_phy_reg1_in			(phy_read_reg_num1_idu_phyRegfile),
		.src_phy_reg2_in			(phy_read_reg_num2_idu_phyRegfile),
		.wr_commit_reg				(0),
		.commit_wr_en				(0),
		.commit_wr_val				(0),
		.dst_phy_reg_in				(phy_write_reg_num_idu_phyRegfile),
		.control_in					(control_idu_phyRegfile),
		.pc_in						(pc_idu_phyRegfile),
		.generated_immediate_in		(generated_immediate_idu_phyRegfile),
		
		.src_val1					(src_val1_phyRegfile_rs),
		.src_val2					(src_val2_phyRegfile_rs),
		.src_phy_reg1_out			(phy_read_reg_num1_phyRegfile_rs),
		.src_phy_reg2_out			(phy_read_reg_num2_phyRegfile_rs),
		.dst_phy_reg_out			(phy_write_reg_num_phyRegfile_rs),
		.control_out				(control_phyRegfile_rs),
		.pc_out						(pc_phyRegfile_rs),
		.generated_immediate_out	(generated_immediate_phyRegfile_rs)

	);


	//****************************************** Stimulus************** *****************************************//
	
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
			next_pc_sel = pc_plus_4_t;	
		end
	
	initial 
		begin
			commit_valid_TEST 			= 1'b0		;
			commit_with_write_TEST		= 1'b0		;
			commited_wr_register_TEST	= 0			;
			#261
			commit_valid_TEST 			= 1'b1		;
			commit_with_write_TEST		= 1'b1		;
			commited_wr_register_TEST	= 5			;
			#40
			commit_valid_TEST 			= 1'b1		;
			commit_with_write_TEST		= 1'b1		;
			commited_wr_register_TEST	= 6			;
				
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