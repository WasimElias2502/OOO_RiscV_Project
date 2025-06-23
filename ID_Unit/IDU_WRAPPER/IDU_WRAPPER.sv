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
	
	input 						clk,
	input 						reset,

	input [31:0] 				 				Instruction_Code [FETCH_WIDTH-1:0],
	input [INST_ADDR_WIDTH-1:0] 				pc_in,
	input [INST_ADDR_WIDTH-1:0] 				pc_plus_4_out,
	//inputs to free physical registers
	input 										commit_valid,
	input 										commit_with_write,
	input [PHYSICAL_REG_NUM_WIDTH-1:0] 			commited_wr_register,
	
	//control unit output
	output control_t						  	control,
	
	//pc output
	input [INST_ADDR_WIDTH-1:0] 				pc_out,
	
	
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
	logic 							      		can_rename_d;
	
	//imm output
	logic [GENERATED_IMMEDIATE_WIDTH-1:0] 		generated_immediate_d;
	
//****************************** Internal Control Signals  *********************************//

	logic 										dst_reg_active;
	opcode_t 									opcode;
	logic [INST_ADDR_WIDTH-1:0] 				pc_out_d;




//****************************** Control Unit Instantiation ********************************//

	assign opcode  = Instruction_Code[`OPCODE_WIDTH-1:0];

	CONTROL_UNIT control_unit (
		
		//inputs
		.opcode(opcode),
		.func3 (Instruction_Code[14:12]),
		.func7 (Instruction_Code[31:25]),
		
		//outputs
		.control(control_d)
	);
	
	DFF #(`CTRL_WIDTH) 	ctrl_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(control_d) , .out(control));
	
	
//********************************** Program Counter ****************************************//

	assign pc_out_d = pc_in ;
	
	DFF #(INST_ADDR_WIDTH) 	pc_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(pc_out_d) , .out(pc_out));


//**************************** Arch Reg File Instantiation **********************************//

	assign dst_reg_active = ~(opcode == S_type || opcode == SB_type );

	ARCH_REG_FILE arch_reg_file (
		
		//inputs
		.clk(clk),
		.reset(reset),
		.arch_read_reg_num1(Instruction_Code[19:15]),
		.arch_read_reg_num2(Instruction_Code[24:20]),
		.arch_write_reg_num(Instruction_Code[11:7]),
		.regwrite(dst_reg_active),
		.commit_valid(commit_valid),
		.commit_with_write(commit_with_write),
		.commited_wr_register(commited_wr_register),
		
		//outputs
		.phy_read_reg_num1(phy_read_reg_num1_d),
		.phy_read_reg_num2(phy_read_reg_num2_d),
		.phy_write_reg_num(phy_write_reg_num_d),
		.valid(can_rename_d)
	);
	
	
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_read_reg1_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(phy_read_reg_num1_d) , .out(phy_read_reg_num1));
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_read_reg2_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(phy_read_reg_num2_d) , .out(phy_read_reg_num2));
	DFF #(PHYSICAL_REG_NUM_WIDTH) 	phy_wr_reg_ff 	 (.clk(clk) , .rst(reset) , .enable(1) , .in(phy_write_reg_num_d) , .out(phy_write_reg_num));
	
	
//**************************** Immediate Generator Instantiation ******************************//

	IMM_GENERATOR imm_generator (
		
		//inputs
		.Instruction_code(Instruction_Code),
		
		//outputs
		.generated_immediate (generated_immediate_d)
	);
	
	DFF #(GENERATED_IMMEDIATE_WIDTH) immediate_ff (.clk(clk) , .rst(reset) , .enable(1) , .in(generated_immediate_d) , .out(generated_immediate));


endmodule