/*------------------------------------------------------------------------------
 * File          : Processor_defines.svh
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`ifndef  __PROCESSOR_DEFINES__
`define  __PROCESSOR_DEFINES__

	//*************************** General Defines *******************************//
	
	
	`define INST_ADDR_WIDTH 			6						// Addess width of the instruction memory
	`define FETCH_WIDTH 				1						// Number of instruction to fetch
	`define REG_VAL_WIDTH				32
	`define GENERATED_IMMEDIATE_WIDTH  `REG_VAL_WIDTH
	
	
	//****************** Instruction Fetch Unit Defines *************************//
	`define INIT_INST_MEM_FILE 			"INIT_INST_MEM.hex"		// File to initialize the INST_MEM
	
	
	
	
	//******************** Decode & Register Renaming Defines *******************//
	`define ARCH_REG_NUM_WIDTH			5					   
	`define PHYSICAL_REG_NUM_WIDTH		6
	`define PHYSICAL_REG_NUM			(1<<`PHYSICAL_REG_NUM_WIDTH)
	`define NO_OLD_PRF 					(1<<`PHYSICAL_REG_NUM_WIDTH)
	`define IMM_WIDTH					12
	`define OPCODE_WIDTH			    7
	`define FUNC3_WIDTH					3
	`define FUNC7_WIDTH					7
	`define ALU_OP_WIDTH 				4
	`define CTRL_WIDTH					$bits(control_t)
	
	//******************** Reservation Station Defines **************************//
	//`define RS_TAG_WIDTH				`PHYSICAL_REG_NUM_WIDTH
	`define	RS_ALU_ENTRIES_NUM			8
	`define	RS_MEM_ENTRIES_NUM			2
	
	
	//******************** Branch Misprediction Defines *************************//
	`define NOP_CONTROL '{alu_src:src_reg2, alu_op:add_op, is_branch_op:0, memory_op:no_mem_op, reg_wb:0}

	//************************ Functional Unit Defines **************************//
	`define NUM_OF_ALUS					4
	`define NUM_OF_MEM					1
	`define NUM_OF_FU					(`NUM_OF_ALUS+`NUM_OF_MEM)
`endif







