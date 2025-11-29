/*------------------------------------------------------------------------------
 * File          : LSQ_2_MEM_CTRL_IF.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 29, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

interface LSQ_2_MEM_CTRL_IF;
	
	logic 										lsq_req_valid;
	memory_op_t									lsq_req_op;
	logic [`D_MEMORY_ADDR_WIDTH-1:0]			lsq_req_address;
	logic [`REG_VAL_WIDTH-1:0]					lsq_req_data;
	
	
	logic										mem_ctrl_ready;
	logic										mem_ctrl_done;
	logic [`REG_VAL_WIDTH-1:0]					mem_ctrl_data;

endinterface

