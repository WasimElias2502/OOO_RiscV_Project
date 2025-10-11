`ifndef __RS_TB_SV__ 
`define __RS_TB_SV__ 



`timescale 1ns/1ns

module RS_TB #(
	
	parameter FU_IDX_WIDTH  = (`NUM_OF_ALUS <= 1) ? 1 : $clog2(`NUM_OF_ALUS)
	
)();


	//reset & clk
	logic 							clk;		 
	logic							reset;	
	
	//FU_IF             			fu_mem_out [`NUM_OF_MEM](); 			// FU inputs from mem
	//logic [`RS_ENTRIES_NUM-1:0] 	rs_pop; 
	
	
	//************************************ RS ALU instantiation ******************************************//
	
	FU_IF#(.NUM_OF_FU(`NUM_OF_ALUS))    fu_alu_if()						; // FU inputs from alu
	CDB_IF								cdb_if ()						; // TODO: CHECK CDB WIDTH
	control_t							control		  					;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg1_val					;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg2_val					;
	logic [`REG_VAL_WIDTH-1:0] 			dst_reg_val						;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr					;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg1_addr					;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg2_addr					;
	logic [`REG_VAL_WIDTH-1:0]			immediate_in					;
	logic 								new_valid_inst					;	
	RS2REG_STATUS_IF alu_rs2reg_status_table_if();
	RS2REG_STATUS_IF mem_rs2reg_status_table_if();
	
	
	//Reg status table
	RS_UNIT_REG_STATUS#() register_status_table(
		.reset						(reset)									,
		.clk						(clk)									,
		.reg_status_2_alu_rs_if		(alu_rs2reg_status_table_if.REG_STATUS)	,
		.reg_status_2_mem_rs_if		(mem_rs2reg_status_table_if.REG_STATUS)
	);
	
	
	RS#(
		.RS_ENTRIES_NUM(`RS_ALU_ENTRIES_NUM),
		.FU_NUM(`NUM_OF_ALUS)	
	)
	alu_reservation_stations(
		
		.clk					(clk),
		.reset					(reset),
		.control				(control),
		.src_reg1_val			(src_reg1_val),
		.src_reg2_val			(src_reg2_val),
		.dst_reg_addr			(dst_reg_addr),
		.src_reg1_addr			(src_reg1_addr),
		.src_reg2_addr			(src_reg2_addr),
		.immediate				(immediate_in),
		.new_valid_inst			(new_valid_inst),
		.cdb_if					(cdb_if.slave),
		.fu_if					(fu_alu_if.RS),
		.reg_status_table_if	(alu_rs2reg_status_table_if.RS)
	);

	
	//******************************************** Drive Inputs  **************************************************//


	localparam CLK_PERIOD = 20; // 20ns half-cycle, 40ns period
	
	initial begin
		clk = 1'b0; 
		new_valid_inst = 1'b0; // Initialize control inputs
		fu_alu_if.ready = {`NUM_OF_ALUS{1'b1}}; // All FUs are ready by default
	end
	
	always #(CLK_PERIOD) clk = ~clk ; // 40ns clock period
		
	
	// Reset Sequence
	initial begin
		reset = 1'b1;
		repeat (2) @(posedge clk);
		reset = 1'b0;
	end
	
	
	//******************************************** Synchronous Input Driver **************************************************//
	
	task drive_rs_inputs(
			input control_t p_control,
			input logic [`REG_VAL_WIDTH-1:0] p_src1_val,
			input logic [`REG_VAL_WIDTH-1:0] p_src2_val,
			input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] p_dst_addr,
			input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] p_src1_addr,
			input logic [`PHYSICAL_REG_NUM_WIDTH-1:0] p_src2_addr,
			input logic [`REG_VAL_WIDTH-1:0] p_imm
		);
			

					// Inputs change on the negative edge or start of cycle
					control 		<= p_control;
					src_reg1_val 	<= p_src1_val;
					src_reg2_val 	<= p_src2_val;
					dst_reg_addr 	<= p_dst_addr;
					src_reg1_addr 	<= p_src1_addr;
					src_reg2_addr 	<= p_src2_addr;
					immediate_in 		<= p_imm;
					
					// Assert valid signal synchronously
					new_valid_inst 	<= 1'b1;
					
					@(posedge clk); // Hold for one full cycle (RS allocates here)
					
					// Deassert valid signal
					new_valid_inst <= 1'b0; 

	endtask
	
	
	//******************************************** 2. FU Lifecycle (Long, Concurrent) *********************************//
	
	task automatic simulate_single_alu(input int fu_id);
		
		
		$display("[%0t] Task forked for FU_ID = %0d. Now waiting for valid signal...", $time, fu_id);
		forever begin
			//if ALU is asserted with  inst
			@(posedge fu_alu_if.valid[fu_id]);
			
			//Make fu not ready for a couple of cycles starting from next cycle
			fu_alu_if.ready[fu_id] <= 1'b0;
			
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
	
	
			fu_alu_if.ready[fu_id] <= 1'b1;
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
		
		
		//simulate FU
		fork
			run_alus_parallel();
		join_none	
		
		
		// Wait for reset to deassert
		@(negedge reset); 
		fu_alu_if.ready =  {`NUM_OF_ALUS{1'b1}};
		
		// ============================ Cycle 1: Issue Instruction 1 (Add R3 = R2 + R1) ======================================
		
		// Set input data
		drive_rs_inputs(
			.p_control		('{is_branch_op: 1'b0, alu_src: src_reg2, alu_op: add_op, memory_op: no_mem_op, reg_wb: 1'b1}),
			.p_src1_val		(64'd15),
			.p_src2_val		(64'd9),
			.p_dst_addr		(5'd3),
			.p_src1_addr	(5'd2), 
			.p_src2_addr	(5'd1), 
			.p_imm			(64'd0)
		);
		
	
		// ============================ Cycle 2: Issue Instruction 2 (Add R4 = R3 + R0) ======================================
		drive_rs_inputs(
			.p_control		('{is_branch_op: 1'b0, alu_src: immediate, alu_op: add_op, memory_op: no_mem_op, reg_wb: 1'b1}),
			.p_src1_val		(64'd0), 
			.p_src2_val		(64'd0),
			.p_dst_addr		(5'd4),
			.p_src1_addr	(5'd3), 
			.p_src2_addr	(5'd0), 
			.p_imm			(64'd33)
		);
		
		
		// Issue Instruction 3 (Add R5 = R2 + Imm)
		// ============================ Cycle 3: Issue Instruction 3 (Add R5 = R2 + Imm) ======================================

		drive_rs_inputs(
			.p_control		('{is_branch_op: 1'b0, alu_src: immediate, alu_op: add_op, memory_op: no_mem_op, reg_wb: 1'b1}),
			.p_src1_val		(64'd3), 
			.p_src2_val		(64'd6),
			.p_dst_addr		(5'd5),
			.p_src1_addr	(5'd2), 
			.p_src2_addr	(5'd2), 
			.p_imm			(64'd33)
		);
		
		
		#1000 $finish; 
	end



	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("RS_TB_output_wave.vcd");
			$fsdbDumpvars(0,RS_TB);
		end
	

	initial 
		#1000 $finish;


endmodule


`endif