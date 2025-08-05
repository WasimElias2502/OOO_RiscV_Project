/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jul 13, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module PHY_REGFILE_WRAPPER #(
	GENERATED_IMMEDIATE_WIDTH 	= `REG_VAL_WIDTH				// value width for generated immediate
) 
(
	//inputs
	input 										clk						,
	input 										reset					,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1_in			,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2_in			,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	wr_commit_reg			,
	input 										commit_wr_en			,
	input 	[`REG_VAL_WIDTH-1:0]    			commit_wr_val 			,
	input 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg_in 			,
	input 	control_t						  	control_in				,
	input 	[`INST_ADDR_WIDTH-1:0] 				pc_in					, 
	input 	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_in	,
	input										flush					,
	
	//output
	output 	[`REG_VAL_WIDTH-1:0]				src_val1				,
	output 	[`REG_VAL_WIDTH-1:0]				src_val2				,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg1_out		,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	src_phy_reg2_out		,
	output 	[`PHYSICAL_REG_NUM_WIDTH-1:0]    	dst_phy_reg_out 		,
	output 	control_t						  	control_out				,
	output 	[`INST_ADDR_WIDTH-1:0] 				pc_out					,
	output	[GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate_out

);


//******************************************** PHY REGFILE outputs -> FF ********************************************

	logic 	[`REG_VAL_WIDTH-1:0]				src_val1_d	;
	logic 	[`REG_VAL_WIDTH-1:0]				src_val2_d	;
	
//*********************************************** control value -> FF ***********************************************	
	
	control_t						  			control_d	;
	assign control_d = (flush)? `NOP_CONTROL : control_in	;


//******************************************** PHY REGFILE INSTANTIATION ********************************************

		PHY_REGFILE phy_regfile (
			
			//inputs
			.clk			(clk),
			.reset			(reset),
			.src_phy_reg1	(src_phy_reg1_in),
			.src_phy_reg2	(src_phy_reg2_in),
			.dst_wr_en		(commit_wr_en),
			.dst_phy_reg	(wr_commit_reg),
			.dst_val		(commit_wr_val),
			
			//output
			.src_val1		(src_val1_d),
			.src_val2		(src_val2_d)
		);


//************************************************* Flip Flop Section ***********************************************

	
	DFF #(`REG_VAL_WIDTH) 				src_val1_ff 	(.clk(clk) , .rst(reset) , .enable(1) , .in(src_val1_d) , .out(src_val1));
	DFF #(`REG_VAL_WIDTH) 				src_val2_ff 	(.clk(clk) , .rst(reset) , .enable(1) , .in(src_val2_d) , .out(src_val2));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		src_phy_reg1_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(src_phy_reg1_in) , .out(src_phy_reg1_out));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		src_phy_reg2_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(src_phy_reg2_in) , .out(src_phy_reg2_out));
	DFF #(`PHYSICAL_REG_NUM_WIDTH) 		dst_phy_reg_ff 	(.clk(clk) , .rst(reset) , .enable(1) , .in(dst_phy_reg_in) , .out(dst_phy_reg_out));
	DFF #(`INST_ADDR_WIDTH) 			pc_ff 			(.clk(clk) , .rst(reset) , .enable(1) , .in(pc_in) , .out(pc_out));
	DFF #(GENERATED_IMMEDIATE_WIDTH) 	immediate_ff 	(.clk(clk) , .rst(reset) , .enable(1) , .in(generated_immediate_in) , .out(generated_immediate_out));
	
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