`ifndef _IDU2PHY_REGFILE_SV__
`define _IDU2PHY_REGFILE_SV__

interface IDU2PHY_REGFILE_IF;

	control_t						  		control;
	logic [`INST_ADDR_WIDTH-1:0] 			pc;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_read_reg_num1; 			
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_read_reg_num2;			
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] 	phy_write_reg_num;			
	logic [`GENERATED_IMMEDIATE_WIDTH-1:0] 	generated_immediate ;
	logic 									valid_inst;
	logic [`ROB_SIZE_WIDTH-1:0]				inst_tag;

endinterface

`endif