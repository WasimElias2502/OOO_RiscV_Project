/*------------------------------------------------------------------------------
 * File          : ROB_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ROB_TB #() ();


	logic										clk						;
	logic										reset					;
	
	//ALU , MEM results
	CDB_IF	 									cdb_if()				;
	
	//Register the INST TAG
	 logic [`ROB_SIZE_WIDTH-1:0]				inst_tag				;
	 logic [`ARCH_REG_NUM_WIDTH-1:0] 			dest_arch_register		;
	 logic										valid_inst_to_register	;
	 control_t						  			control_in				;
	
	//commit interface
	COMMIT_IF 									commit_if()				;
	
	
	//**************************** Re Order Buffer Instantiation **************************************//
	
	ROB rob(
		.clk					(clk),
		.reset					(reset),
		.cdb_if					(cdb_if.slave),
		.inst_tag				(inst_tag),
		.dest_arch_register 	(dest_arch_register),
		.valid_inst_to_register	(valid_inst_to_register),
		.control_in				(control_in),
		.commit_if				(commit_if.master)
	);
	
	//**************************************** Stimulus ************************************************//
	
	
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#35 reset = 1'b0;
			#1400 reset = 1'b1;
		end
	
	task automatic register_instruction_in_rob( int tag);
		
		#50ns
		@(posedge clk);
		
		inst_tag 				<= tag						;
		dest_arch_register 		<= $urandom % `ARCH_REG_NUM ; 
		valid_inst_to_register	<= 1'b1						;
		control_in.alu_op		<= add_op					;
		control_in.alu_src		<= src_reg2					;
		control_in.is_branch_op	<= 1'b0						;
		control_in.memory_op	<= no_mem_op				;
		control_in.reg_wb		<= 1'b1						;
		
		@(posedge clk);
		valid_inst_to_register	<= 1'b0						;

	endtask
	
	
	task automatic alu_done (int tag , int alu_idx);
		
		#50ns		
		@(posedge clk);
		
		cdb_if.valid[alu_idx] 			<= 1'b1 					;
		cdb_if.inst_tag[alu_idx]		<= tag						;
		cdb_if.register_addr[alu_idx]	<= $urandom % `ARCH_REG_NUM ; 
		cdb_if.register_val[alu_idx]	<= $urandom % `REG_VAL_WIDTH;
		
		@(posedge clk);
		cdb_if.valid[alu_idx] 			<= 1'b0 					;

	endtask

	//Stimulus
	initial begin
		for(int i=0; i<`NUM_OF_FU; i++) begin
			cdb_if.valid[i] 			<= 1'b0 					;
		end
		valid_inst_to_register	<= 1'b0								;

		register_instruction_in_rob(0);
		register_instruction_in_rob(1);
		register_instruction_in_rob(2);
		register_instruction_in_rob(3);
		
		alu_done(2 , 1);
		alu_done(0 , 0);
		alu_done(1 , 3);
		alu_done(3 , 3);

	end
	
	
	
	
	
	
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("ROB_TB_wave.vcd");
			$fsdbDumpvars(0,ROB_TB);
		end
	
	//end test after 500ns 
	initial 
		#1500 $finish;


endmodule