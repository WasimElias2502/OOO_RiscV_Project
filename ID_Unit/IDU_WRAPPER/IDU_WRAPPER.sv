/*------------------------------------------------------------------------------
 * File          : IDU_WRAPPER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 21, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module IDU_WRAPPER #(

	FETCH_WIDTH 				= `FETCH_WIDTH, 				// Number of instruction to fetch
	INST_ADDR_WIDTH 			= `INST_ADDR_WIDTH,				// Addess width of the instruction memory
	ARCH_REG_NUM_WIDTH 	    	= `ARCH_REG_NUM_WIDTH, 			// Number of architecture registers
	PHYSICAL_REG_NUM_WIDTH 		= `PHYSICAL_REG_NUM_WIDTH,		// width (number of bits) of the number of physical registers
	GENERATED_IMMEDIATE_WIDTH 	= `REG_VAL_WIDTH				// value width for generated immediate

) (
	
	input 										clk,
	input 										reset,

	input [31:0] 				 				Instruction_Code [FETCH_WIDTH-1:0],
	input [INST_ADDR_WIDTH-1:0] 				pc_in,
	input [INST_ADDR_WIDTH-1:0] 				pc_plus_4_in,
	//inputs to free physical registers
	input 										commit_valid,
	input 										commit_with_write,
	input [PHYSICAL_REG_NUM_WIDTH-1:0] 			commited_wr_register,
	
	//control unit output
	output control_t						  	control,
	
	//pc output
	output [INST_ADDR_WIDTH-1:0] 				pc_out,
	
	
	//arch ref file output
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_read_reg_num1, 			// ***************** physical ***************//
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_read_reg_num2,			// ******************** W/R *****************//
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_write_reg_num,			// **************** registers****************//
	output logic 						      	can_rename,
	
	//imm output
	output [GENERATED_IMMEDIATE_WIDTH-1:0] 		generated_immediate
	

);

//*************************** Internal Signals -> Inputs for FF ****************************//

	control_t						  			control_d;
	
	//arch ref file output
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			phy_read_reg_num1_d; 			
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			phy_read_reg_num2_d;			
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			phy_write_reg_num_d;			
	
	//imm output
	logic [GENERATED_IMMEDIATE_WIDTH-1:0] 		generated_immediate_d;
	
	//cannot rename (arch regfile -> control unit)
	logic 										can_rename_to_ctrl_unit;
	
//****************************** Internal Control Signals  *********************************//

	logic 										dst_reg_active;
	opcode_t 									opcode;
	logic [INST_ADDR_WIDTH-1:0] 				pc_out_d;
	func3_t										func3;
	func7_t										func7;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			arch_read_reg_num1;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			arch_read_reg_num2;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] 			arch_write_reg_num;




//****************************** Control Unit Instantiation ********************************//

	assign opcode 	= (can_rename_to_ctrl_unit) ? opcode_t'(Instruction_Code[0][`OPCODE_WIDTH-1:0]) : NOP;
	assign func3   	= Instruction_Code[0][14:12];
	assign func7	= Instruction_Code[0][31:25];

	CONTROL_UNIT control_unit (
		
		//inputs
		.opcode(opcode),
		.func3 (func3),
		.func7 (func7),
		
		//outputs
		.control(control_d)
	);
	
	
	//DFF
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			// Reset all fields
			control.alu_src 	  <= src_reg2 ;
			control.alu_op 		  <= add_op	;
			control.is_branch_op  <= 1'b0;
			control.memory_op	  <= no_mem_op;
			control.reg_wb 		  <= 1'b0;
		end
		else begin
			control <= control_d;
		end
	end

	
	
//********************************** Program Counter ****************************************//

	assign pc_out_d = pc_in ;
	
	DFF #(INST_ADDR_WIDTH) 	pc_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(pc_out_d) , .out(pc_out));


//**************************** Arch Reg File Instantiation **********************************//

	assign dst_reg_active = ~(opcode == S_type || opcode == SB_type || opcode == NOP);
	assign arch_read_reg_num1 = Instruction_Code[0][19:15];
	assign arch_read_reg_num2 = Instruction_Code[0][24:20];
	assign arch_write_reg_num = Instruction_Code[0][11:7];

	ARCH_REG_FILE arch_reg_file (
		
		//inputs
		.clk(clk),
		.reset(reset),
		.arch_read_reg_num1(arch_read_reg_num1),
		.arch_read_reg_num2(arch_read_reg_num2),
		.arch_write_reg_num(arch_write_reg_num),
		.regwrite(dst_reg_active),
		.commit_valid(commit_valid),
		.commit_with_write(commit_with_write),
		.commited_wr_register(commited_wr_register),
		
		//outputs
		.phy_read_reg_num1(phy_read_reg_num1_d),
		.phy_read_reg_num2(phy_read_reg_num2_d),
		.phy_write_reg_num(phy_write_reg_num_d),
		.valid(can_rename)
	);
	
	
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_read_reg1_ff 			(.clk(clk) , .rst(reset) , .enable(1) , .in(phy_read_reg_num1_d) , .out(phy_read_reg_num1));
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_read_reg2_ff 			(.clk(clk) , .rst(reset) , .enable(1) , .in(phy_read_reg_num2_d) , .out(phy_read_reg_num2));
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_wr_reg_ff 	 			(.clk(clk) , .rst(reset) , .enable(1) , .in(phy_write_reg_num_d) , .out(phy_write_reg_num));
	DFF #(1) 						can_rename_to_ctrl_unit_ff 	(.clk(clk) , .rst(reset) , .enable(1) , .in(can_rename) 		 , .out(can_rename_to_ctrl_unit));
	
	
	
//**************************** Immediate Generator Instantiation ******************************//

	IMM_GENERATOR imm_generator (
		
		//inputs
		.Instruction_code(Instruction_Code[0]),
		
		//outputs
		.generated_immediate (generated_immediate_d)
	);
	
	DFF #(GENERATED_IMMEDIATE_WIDTH) immediate_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(generated_immediate_d) , .out(generated_immediate));


endmodule