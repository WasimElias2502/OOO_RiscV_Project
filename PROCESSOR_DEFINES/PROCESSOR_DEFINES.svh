/*------------------------------------------------------------------------------
 * File          : Processor_defines.svh
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


//****************** General Defines *************************//


`define INST_ADDR_WIDTH 			6						// Addess width of the instruction memory
`define FETCH_WIDTH 				1						// Number of instruction to fetch`


//****************** Instruction Fetch Unit Defines *************************//
`define INIT_INST_MEM_FILE 			"INIT_INST_MEM.hex"		// File to initialize the INST_MEM

//******************** Decode & Register Renaming Defines *******************//
`define ARCH_REG_NUM_WIDTH			5					   
`define PHYSICAL_REG_NUM_WIDTH		6
`define NO_OLD_PRF 					1<<`PHYSICAL_REG_NUM_WIDTH
`define IMM_WIDTH					12