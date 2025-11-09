/*------------------------------------------------------------------------------
 * File          : ALU_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 4, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ALU_TB #() ();

	logic	   							  	clk			;
	logic									reset		;
	
	logic 									alu_ready	;
	logic									rs_valid	;
	logic [`REG_VAL_WIDTH-1:0]				src_reg1_val;
	logic [`REG_VAL_WIDTH-1:0] 				src_reg2_val;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]		dst_reg_addr;
	control_t								control		;
	logic [`REG_VAL_WIDTH-1:0]				immediate	;
	logic [`INST_ADDR_WIDTH-1:0] 			pc_in		;
	
	// to CDB and next stage - ROB
	logic [`REG_VAL_WIDTH-1:0]				result_val	;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]		result_addr	;
	logic									alu_valid	;
	
	// to branch misprediction unit
	logic [`INST_ADDR_WIDTH-1:0] 			pc_out 		;
	logic									pc_out_valid;// TODO: CHECK VALID
	
	
	
	//***************************** ALU Instantiation***************************************//
	
	ALU#(
		.LOW_LATENCY_CYCLES(3)	
		
	) alu (
		.clk				(clk),
		.reset				(reset),
		.alu_ready			(alu_ready),
		.rs_valid			(rs_valid),
		.src_reg1_val		(src_reg1_val),
		.src_reg2_val		(src_reg2_val),
		.dst_reg_addr		(dst_reg_addr),
		.control			(control),
		.immediate			(immediate),
		.pc_in				(pc_in),
		.result_val			(result_val),
		.result_addr		(result_addr),
		.alu_valid			(alu_valid),
		.pc_out				(pc_out),
		.pc_out_valid		(pc_out_valid)
	);
	
	
	//********************************* Testbench Stimuli ************************************//
	
	task automatic simulate_single_RS_calculate_inst();
		
		alu_op_t alu_op_num;
		alu_op_num = alu_op_num.last;
		
		$display("[%0t] Task forked for RS...", $time);
		forever begin
			//if ALU is asserted with  inst
			@(posedge clk);
			
			//if alu_ready then push new instruction to ALU
			if(alu_ready && !reset) begin
				
				@(posedge clk);
				rs_valid 				<= 1'b1										;
				src_reg1_val 			<= $urandom	% `REG_VAL_WIDTH				;
				src_reg2_val 			<= $urandom	% `REG_VAL_WIDTH				;
				dst_reg_addr 			<= $urandom % `PHYSICAL_REG_NUM				;
				control.alu_op			<=	alu_op_t'($urandom % alu_op_num)		;
				control.alu_src			<= src_reg2 								;
				control.is_branch_op 	<= 1'b0 									;
				control.memory_op		<= no_mem_op								;
				control.reg_wb			<= 1'b1										;
				immediate				<= $urandom	% `REG_VAL_WIDTH				;
				pc_in					<= 16										;
				
				@(posedge clk);
				rs_valid 				<= 1'b0										;
			end
		end
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
			#2000 reset = 1'b1;
		end
	
	//
	initial 
		begin
		//initial values
		rs_valid 				= 1'b0		;
		src_reg1_val 			= 0			;
		src_reg2_val 			= 0			;
		dst_reg_addr 			= 0			;
		control.alu_op			=	add_op	;
		control.alu_src			= src_reg2 	;
		control.is_branch_op 	= 1'b0 		;
		control.memory_op		= no_mem_op;
		control.reg_wb			= 1'b0		;
		immediate				= 0			;
		pc_in					= 0			;
	
			fork
				simulate_single_RS_calculate_inst();
			join_none
		end
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("ALU_TB_output_wave.vcd");
			$fsdbDumpvars(0,ALU_TB);
		end
	
	//end test after 500ns
	initial 
		#1500 $finish;

endmodule