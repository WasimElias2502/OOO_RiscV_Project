/*------------------------------------------------------------------------------
 * File          : Processor_defines.svh
 * Project       : RTL
 * Author        : epwebq
 * Creation date : May 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


//****************** General Defines *************************//


`define INST_ADDR_WIDTH 			6		// Addess width of the instruction memory
`define FETCH_WIDTH 				1		// Number of instruction to fetch`


//****************** Instruction Fetch Unit Defines *************************//
`define INIT_INST_MEM_FILE 			""		// File to initialize the INST_MEM
`define SB 							0		
`define UJ 							1
`define JALR 						2	
`define PC_PLUS_4 					3


//******************** Decode & Register Renaming Defines *******************//
`define ARCH_REG_NUM_WIDTH			5
`define PHYSICAL_REG_NUM_WIDTH		6