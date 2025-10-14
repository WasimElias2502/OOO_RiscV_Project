/*------------------------------------------------------------------------------
 * File          : PHY_REGFILE2RS_IF.sv.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Oct 12, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

interface PHY_REGFILE2RS_IF;
	
	control_t							control		  					;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg1_val					;
	logic [`REG_VAL_WIDTH-1:0] 			src_reg2_val					;
	logic [`REG_VAL_WIDTH-1:0] 			dst_reg_val						;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0]	dst_reg_addr					;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg1_addr					;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] src_reg2_addr					;
	logic [`REG_VAL_WIDTH-1:0]			immediate						;
	logic								new_valid_inst					;
	
	
	modport PHY_REGFILE(
		output 		control,
		output 		src_reg1_val,
		output		src_reg2_val,
		output 		dst_reg_val,
		output		dst_reg_addr,
		output		src_reg1_addr,
		output		src_reg2_addr,
		output		immediate,
		output		new_valid_inst
	);
	
	
	modport RS(
		input 		control,
		input 		src_reg1_val,
		input		src_reg2_val,
		input 		dst_reg_val,
		input		dst_reg_addr,
		input		src_reg1_addr,
		input		src_reg2_addr,
		input		immediate,
		input		new_valid_inst
	);
	


endinterface