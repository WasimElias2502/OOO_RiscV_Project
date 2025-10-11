`ifndef __IF2IDU_IF_SV_ 
`define __IF2IDU_IF_SV_

`timescale 1ns/1ns

interface IF2IDU_IF ;

	logic [31:0] 				 				Instruction_Code [`FETCH_WIDTH-1:0];
	logic [`INST_ADDR_WIDTH-1:0] 				pc;
	logic [`INST_ADDR_WIDTH-1:0] 				pc_plus_4;
	logic 										can_rename;

endinterface

`endif