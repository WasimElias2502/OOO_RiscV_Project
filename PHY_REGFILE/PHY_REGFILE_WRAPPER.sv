/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jul 13, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


module PHY_REGFILE_WRAPPER #(
	GENERATED_IMMEDIATE_WIDTH 	= `REG_VAL_WIDTH				// value width for generated immediate
) 
(
	//inputs
	input 										clk						,
	input 										reset					,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1_in			,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2_in			,
	CDB_IF.slave								CDB_if					,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg_in 			,
	input 	control_t						  	control_in				,
	input 	[`INST_ADDR_WIDTH-1:0] 				pc_in					, 
	input 	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_in	,
	input										flush					,
	input										valid_inst_in			,
	input 										stall					,
	input 	[`ROB_SIZE_WIDTH-1:0]				inst_tag_in				,
	
	//output
	output 	[`REG_VAL_WIDTH-1:0]				src_val1				,
	output 	[`REG_VAL_WIDTH-1:0]				src_val2				,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1_out		,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2_out		,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg_out 		,
	output 	control_t						  	control_out				,
	output 	[`INST_ADDR_WIDTH-1:0] 				pc_out					,
	output	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_out ,
	output 	[`ROB_SIZE_WIDTH-1:0]				inst_tag_out			,
	output										valid_inst_out				

);



//******************************************** PHY REGFILE outputs -> FF ********************************************

	logic 	[`REG_VAL_WIDTH-1:0]				src_val1_d	;
	logic 	[`REG_VAL_WIDTH-1:0]				src_val2_d	;
	

	
//************************************************ Instruction Stall ************************************************
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	stalled_src_phy_reg1_in			;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	stalled_src_phy_reg2_in			;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	stalled_dst_phy_reg_in 			;
	control_t						  			stalled_control_in				;
	logic 	[`INST_ADDR_WIDTH-1:0] 				stalled_pc_in					; 
	logic 	[GENERATED_IMMEDIATE_WIDTH-1:0] 	stalled_generated_immediate_in	;
	logic										stalled_valid					;
	logic  [`ROB_SIZE_WIDTH-1:0]				stalled_inst_tag				;
	
	//TODO: check tag stall
	
	
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			stalled_valid       			<= 1'b0;
			stalled_src_phy_reg1_in			<= '0;
			stalled_src_phy_reg2_in			<= '0;
			stalled_dst_phy_reg_in 			<= '0;
			stalled_control_in.alu_src 	  	<= src_reg2 ;
			stalled_control_in.alu_op 		 <= add_op	;
			stalled_control_in.is_branch_op  <= 1'b0;
			stalled_control_in.memory_op	 <= no_mem_op;
			stalled_control_in.reg_wb 		 <= 1'b0;
			stalled_pc_in					<= '0;
			stalled_generated_immediate_in	<= '0;
			stalled_inst_tag				<= '0;
			
			
		end else begin
			
			if (valid_inst_in && stall) begin
				stalled_valid       			<= 1'b1;
				stalled_src_phy_reg1_in			<= src_phy_reg1_in;
				stalled_src_phy_reg2_in			<= src_phy_reg2_in;
				stalled_dst_phy_reg_in 			<= dst_phy_reg_in;
				stalled_control_in				<= control_in;
				stalled_pc_in					<= pc_in;
				stalled_generated_immediate_in	<= generated_immediate_in;
				stalled_inst_tag				<= inst_tag_in ;
			end
			
			else if (stalled_valid && ~stall) begin
				stalled_valid <= 1'b0; // release the stall
			end
		end
	end
	
	
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	chosen_src_phy_reg1_in			;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	chosen_src_phy_reg2_in			;
	logic 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	chosen_dst_phy_reg_in 			;
	control_t						  			chosen_control_in				;
	logic 	[`INST_ADDR_WIDTH-1:0] 				chosen_pc_in					; 
	logic 	[GENERATED_IMMEDIATE_WIDTH-1:0] 	chosen_generated_immediate_in	;
	logic   [`ROB_SIZE_WIDTH-1:0]				chosen_inst_tag_out				;
	
	
	
	//Muxes to select between stalled instruction and new instruction incoming
	assign chosen_src_phy_reg1_in 			= (stalled_valid)? stalled_src_phy_reg1_in : src_phy_reg1_in;
	assign chosen_src_phy_reg2_in			 = (stalled_valid)? stalled_src_phy_reg2_in : src_phy_reg2_in;
	assign chosen_dst_phy_reg_in 			= (stalled_valid)? stalled_dst_phy_reg_in : dst_phy_reg_in;
	assign chosen_control_in 				= (stalled_valid)? stalled_control_in : control_in;
	assign chosen_pc_in 					= (stalled_valid)? stalled_pc_in : pc_in;
	assign chosen_generated_immediate_in 	= (stalled_valid)? stalled_generated_immediate_in : generated_immediate_in;
	assign chosen_inst_tag_out				= (stalled_valid)? stalled_inst_tag : inst_tag_in ;
	
	
	
	//*********************************************** control value -> FF ***********************************************	
	
	control_t						  			control_d	;
	assign control_d = (flush)? `NOP_CONTROL : chosen_control_in	;

//******************************************** PHY REGFILE INSTANTIATION ********************************************

		PHY_REGFILE phy_regfile (
			
			//inputs
			.clk			(clk),
			.reset			(reset),
			.src_phy_reg1	(chosen_src_phy_reg1_in),
			.src_phy_reg2	(chosen_src_phy_reg2_in),
			.dst_wr_en		(CDB_if.valid),
			.dst_phy_reg	(CDB_if.register_addr),
			.dst_val		(CDB_if.register_val),
			
			//output
			.src_val1		(src_val1_d),
			.src_val2		(src_val2_d)
		);


//************************************************* Flip Flop Section ***********************************************
	
	logic 	issue_allowed;
	assign	issue_allowed = (valid_inst_in | stalled_valid ) & ~stall;
	
	DFF #(1) 							new_valid_inst_ff (.clk(clk) , .rst(reset) , .enable(1'b1) , .in(issue_allowed) , .out(valid_inst_out));
	DFF #(`REG_VAL_WIDTH) 				src_val1_ff 	(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(src_val1_d) , .out(src_val1));
	DFF #(`REG_VAL_WIDTH) 				src_val2_ff 	(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(src_val2_d) , .out(src_val2));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		src_phy_reg1_ff (.clk(clk) , .rst(reset) , .enable(1'b1) , .in(chosen_src_phy_reg1_in) , .out(src_phy_reg1_out));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		src_phy_reg2_ff (.clk(clk) , .rst(reset) , .enable(1'b1) , .in(chosen_src_phy_reg2_in) , .out(src_phy_reg2_out));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		dst_phy_reg_ff 	(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(chosen_dst_phy_reg_in) , .out(dst_phy_reg_out));
	DFF #(`INST_ADDR_WIDTH) 			pc_ff 			(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(chosen_pc_in) , .out(pc_out));
	DFF #(`ROB_SIZE_WIDTH)				tag_ff			(.clk(clk) , .rst (reset), .enable(1'b1) , .in(chosen_inst_tag_out) , .out(inst_tag_out) );
	DFF #(GENERATED_IMMEDIATE_WIDTH) 	immediate_ff 	(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(chosen_generated_immediate_in) , .out(generated_immediate_out));
	
	//DFF
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			// Reset all fields
			control_out.alu_src 	  <= src_reg2 ;
			control_out.alu_op 		  <= add_op	;
			control_out.is_branch_op  <= 1'b0;
			control_out.memory_op	  <= no_mem_op;
			control_out.reg_wb 		  <= 1'b0;
		end
		else begin
			control_out <= control_d;
		end
	end

endmodule