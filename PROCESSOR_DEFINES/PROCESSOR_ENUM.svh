/*------------------------------------------------------------------------------
 * File          : PROCESSOR_ENUM.svh
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`ifndef   __PROCESSOE_ENUM__
`define   __PROCESSOE_ENUM__ 

	//****************** Instruction Fetch Unit Enum *************************//
	
	typedef enum {sb , uj , jalr , pc_plus_4_t} next_pc_t;
	
	
	//******************** Decode & Register Renaming Defines ******************//
	
	typedef enum bit[`OPCODE_WIDTH-1:0] {
		NOP 		= 7'b0000000,
		R_type 		= 7'b0110011, 
		I_type_load = 7'b0000011,
		I_type_arth = 7'b0010011,
		S_type 		= 7'b0100011,
		SB_type 	= 7'b1100011
	}	opcode_t ;
	
	
	typedef bit[`FUNC3_WIDTH-1 :0] 						func3_t  ;
	typedef bit[`FUNC7_WIDTH-1 :0] 						func7_t  ;
	
	typedef enum     {src_reg2 , immediate }			alu_src_t ;
	
	typedef enum bit [`ALU_OP_WIDTH-1:0]	{add_op ,sub_op ,sll_op,slt_op ,sltu_op, xor_op, srl_op, sra_op, or_op, and_op,
				  							 eq_op , not_eq_op , less_than_op , greater_equal_than_op} alu_op_t ;
	
	typedef enum bit [1:0]{no_mem_op ,mem_read , mem_write}  memory_op_t;
	
	typedef struct packed{
		
		alu_src_t 	alu_src;
		alu_op_t  	alu_op;
		bit 	  	is_branch_op;
		memory_op_t memory_op;
		bit 	  	reg_wb;
	} control_t ;
	
	
	
	
	
	//****************** Reservation Station Unit Entry ************************//
	
	typedef struct packed {

		bit [`REG_VAL_WIDTH-1:0] 			src_reg1_val  ;
		bit [`REG_VAL_WIDTH-1:0] 			src_reg2_val  ;	 
		bit [`PHYSICAL_REG_NUM_WIDTH-1:0]	src_reg1_addr ;
		bit [`PHYSICAL_REG_NUM_WIDTH-1:0]	src_reg2_addr ;
		bit [`PHYSICAL_REG_NUM_WIDTH-1:0]	dest_reg_addr ;
		bit [`REG_VAL_WIDTH-1:0]			immediate	  ;
		bit [`INST_ADDR_WIDTH-1:0]			pc			  ;
		bit [`ROB_SIZE_WIDTH-1:0]			new_inst_tag  ;	
		control_t 							control		  ;
		bit									valid_entry	  ;	
		
	} reservation_station_t;
	
	typedef enum bit{ not_valid = 1'b0 , valid = 1'b1} RS_reg_status;
	
	
	//*********************** Reorder Buffer Entry ***************************//
	
	
	typedef enum bit[2:0] {reg_commit_wb , store_commit , branch_commit_taken , branch_commit_not_taken} commit_type_t;
	
	typedef struct packed {
		
		bit									occupied			;
		bit [`ARCH_REG_NUM_WIDTH-1:0]		dest_arch_register 	;
		bit	[`PHYSICAL_REG_NUM_WIDTH]		dest_phy_register	;
		bit [`REG_VAL_WIDTH-1:0]			dest_val			;
		bit 								can_commit			;
		commit_type_t						commit_type			;							
		
	} ROB_entry_t;
	
	//******************** Load Store Queue Entry **************************** //
	
	typedef enum bit[1:0] { waiting , executing , forwarded , done } mem_op_status_t;		
	
	typedef struct packed {
		bit 								occupied			;
		bit 								dispatched			;
		memory_op_t 						req_mem_op_type		;
		bit [`D_MEMORY_ADDR_WIDTH-1:0]		req_address			;
		bit [`PHYSICAL_REG_NUM_WIDTH-1:0] 	req_reg_dst			;
		bit [`REG_VAL_WIDTH-1:0]			store_req_data		;
		bit [`REG_VAL_WIDTH-1:0]			load_req_data		;
		bit [`REG_VAL_WIDTH-1:0]			fw_load_req_data	;
		bit 								ready_to_execute	;
		bit 								was_forwarded		;
		bit 								completed			;
	} LSQ_entry_t;
	
	//************************** Retire Tags Entry **************************** //
	
	typedef struct packed {
		bit 								commited			;
		bit 								ready_to_retire		;
		memory_op_t							mem_op				;
	} TAG_RETIRE_entry_t;
	
	
`endif