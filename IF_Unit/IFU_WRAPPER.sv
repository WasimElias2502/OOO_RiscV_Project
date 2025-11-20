/*------------------------------------------------------------------------------
 * File          : IFU_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 21, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module IFU_WRAPPER #(
	FETCH_WIDTH 	= `FETCH_WIDTH, 			// Number of instruction to fetch
	INST_ADDR_WIDTH = `INST_ADDR_WIDTH			// Addess width of the instruction memory
) (
	input 						clk,
	input 						reset,
	//inputs for branch instructions
	input next_pc_t 			next_pc_sel,
	input [INST_ADDR_WIDTH-1:0] SB_Type_addr,
	input [INST_ADDR_WIDTH-1:0] UJ_Type_addr,
	input [INST_ADDR_WIDTH-1:0] JALR_Type_addr,
	input 						stall,				
	//outputs
	output						 seen_last_inst,
	output [31:0] 				 Instruction_Code [FETCH_WIDTH-1:0],
	output [INST_ADDR_WIDTH-1:0] pc_out,
	output [INST_ADDR_WIDTH-1:0] pc_plus_4_out,
	output						 new_valid_inst
);


//************************ Internal Signals **************************//

	logic [31:0] 				Instruction_Code_d[FETCH_WIDTH-1:0];
	logic [INST_ADDR_WIDTH-1:0] pc_out_d;
	logic [INST_ADDR_WIDTH-1:0] pc_plus_4_out_d;
	logic 						new_valid_inst_d;


//************************ IFU Instantiation **************************//
	IFU if_unit (
		//inputs
		.clk					(clk),
		.reset					(reset),
		.next_pc_sel			(next_pc_sel),
		.SB_Type_addr			(SB_Type_addr),
		.UJ_Type_addr			(UJ_Type_addr),
		.JALR_Type_addr			(JALR_Type_addr),
		.stall					(stall),
		
		//outputs
		.Instruction_Code		(Instruction_Code_d),
		.pc_out					(pc_out_d),
		.pc_plus_4_out			(pc_plus_4_out_d),
		.new_valid_inst			(new_valid_inst_d),
		.seen_last_inst			(seen_last_inst)
	);
	
//************************ Flip Flop Output **************************//
	genvar i;
	generate
	  for (i = 0; i < FETCH_WIDTH; i = i + 1) begin : gen_dff_array
		DFF #(32) dff_inst (
		  .clk		(clk),
		  .rst		(reset),
		  .enable	(~stall),
		  .in		(Instruction_Code_d[i]),
		  .out		(Instruction_Code[i])
		);
	  end
	endgenerate
	
	DFF #(INST_ADDR_WIDTH) 	pc_ff 			(.clk(clk) , .rst(reset) , .enable(~stall) , .in(pc_out_d) , .out(pc_out));
	DFF #(INST_ADDR_WIDTH) 	pc_plus4_ff 	(.clk(clk) , .rst(reset) , .enable(~stall) , .in(pc_plus_4_out_d) , .out(pc_plus_4_out));
	DFF #(1)			 	valid_inst_ff 	(.clk(clk) , .rst(reset) , .enable(1'b1) , .in(new_valid_inst_d) , .out(new_valid_inst));
	



endmodule