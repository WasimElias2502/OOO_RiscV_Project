/*------------------------------------------------------------------------------
 * File          : Processor_defines.svh
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


//****************** General Defines ****************************************//


`define INST_ADDR_WIDTH 			6						// Addess width of the instruction memory
`define FETCH_WIDTH 				1						// Number of instruction to fetch
`define REG_VAL_WIDTH				32


//****************** Instruction Fetch Unit Defines *************************//
`define INIT_INST_MEM_FILE 			"INIT_INST_MEM.hex"		// File to initialize the INST_MEM




//******************** Decode & Register Renaming Defines *******************//
`define ARCH_REG_NUM_WIDTH			5					   
`define PHYSICAL_REG_NUM_WIDTH		6
`define NO_OLD_PRF 					1<<`PHYSICAL_REG_NUM_WIDTH
`define IMM_WIDTH					12
`define OPCODE_WIDTH			    7
`define FUNC3_WIDTH					3
`define FUNC7_WIDTH					7

//******************** Reservation Station Defines **************************//
`define RS_TAG_WIDTH				`PHYSICAL_REG_NUM_WIDTH
`define ADD_RS_NUM					3