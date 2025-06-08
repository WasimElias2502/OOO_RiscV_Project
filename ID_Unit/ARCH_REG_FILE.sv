/*------------------------------------------------------------------------------
 * File          : ARCH_REG_FILE.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 2, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module ARCH_REG_FILE #(
	ARCH_REG_NUM_WIDTH 	   = `ARCH_REG_NUM_WIDTH, 						// Number of architecture registers
	PHYSICAL_REG_NUM_WIDTH = `PHYSICAL_REG_NUM_WIDTH					// width (number of bits) of the number of physical registers
) (
	input clk,
	input reset,
	input [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num1, 					// **************** architecture ************//
	input [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num2,					// ******************** W/R *****************//
	input [ARCH_REG_NUM_WIDTH-1:0] arch_write_reg_num,					// **************** registers****************//
	input regwrite,
	//inputs to free physical registers
	input commit_valid,
	input commit_with_write,
	input [PHYSICAL_REG_NUM_WIDTH-1:0] commited_wr_register,
	
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num1, 		// ***************** physical ***************//
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num2,		// ******************** W/R *****************//
	output logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_write_reg_num			// **************** registers****************//
);

	//local params in use
	localparam IN_USE 	  = 1<<ARCH_REG_NUM_WIDTH ;
	localparam NOT_IN_USE = (1<<PHYSICAL_REG_NUM_WIDTH)-(1<<ARCH_REG_NUM_WIDTH);
	
	
	//internal signals for the FIFO 
	logic 								free_phy_registers_is_empty;
	logic 								pop_free_phy_register ;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0]  pop_free_phy_register_id ;
	logic push_free_phy_register ;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] push_free_phy_register_id ;
	

	//mapping of the arch-phy registers
	reg [PHYSICAL_REG_NUM_WIDTH-1:0] arch_phy_mapping 		[(1<<ARCH_REG_NUM_WIDTH)-1:0];
	reg [PHYSICAL_REG_NUM_WIDTH-1:0] arch_phy_mapping_next 	[(1<<ARCH_REG_NUM_WIDTH)-1:0];
	
	//array to tell if physical register in use or not
	reg [(1<<ARCH_REG_NUM_WIDTH)-1:0] phy_register_in_use ;
	reg [(1<<ARCH_REG_NUM_WIDTH)-1:0] phy_register_in_use_next ;
	
	
	//instantiation of the free physical register 
	SYN_FIFO #(
		.DATA_WIDTH(PHYSICAL_REG_NUM_WIDTH),
		.ADDR_WIDTH (PHYSICAL_REG_NUM_WIDTH),
		.RESET_INITIAL_PUSH_EN(1),
		.RESET_INITIAL_PUSH_START(IN_USE),
		.RESET_INITIAL_PUSH_COUNT(NOT_IN_USE)
		) free_phy_registers(
			.clk(clk),
			.reset(reset),
			.wr_en (push_free_phy_register),
			.wr_data (push_free_phy_register_id),
			.full (),
			.rd_en (pop_free_phy_register),
			.rd_data (pop_free_phy_register_id),
			.empty (free_phy_registers_is_empty)
		);

	
	// ************************************ Always Comb Logic **************************************************//
	
	always_comb begin
		
		//Default values
		pop_free_phy_register = 1'b0;
		push_free_phy_register_id = 0 ;
		push_free_phy_register = 1'b0 ;
		arch_phy_mapping_next = arch_phy_mapping ;
		phy_register_in_use_next = phy_register_in_use ;
	
		//allocate new register for WR
		if(regwrite && !free_phy_registers_is_empty) begin
			pop_free_phy_register = 1'b1; 
			phy_register_in_use_next[arch_phy_mapping[arch_write_reg_num]] = 1'b0;
			arch_phy_mapping_next[arch_write_reg_num] = pop_free_phy_register_id;
			phy_register_in_use_next[pop_free_phy_register_id] = 1'b1;
		end
		
		//got commited WR instruction
		if(commit_valid && commit_with_write && !phy_register_in_use[arch_phy_mapping[arch_write_reg_num]] ) begin
			push_free_phy_register = 1'b1;
			push_free_phy_register_id = commited_wr_register;
			phy_register_in_use_next[commited_wr_register] = 1'b0;
		end
		
		//read register instruction
		phy_read_reg_num1 = arch_phy_mapping[arch_read_reg_num1];
		phy_read_reg_num2 = arch_phy_mapping[arch_read_reg_num2];
		
		//for write register
		phy_write_reg_num = arch_phy_mapping_next[arch_write_reg_num];
	
	end
	
	
	// ************************************ Always FF Logic ****************************************************//
	
	always_ff@(posedge clk or posedge reset) begin
		
		if(reset) begin
			//initialize arch in use for the first 1<<ARCH_REG_NUM_WIDTH registers
			phy_register_in_use <= {{NOT_IN_USE{1'b0}} , {IN_USE{1'b1}}};
			
			for (int i=0 ; i < 1<<ARCH_REG_NUM_WIDTH ; i++) begin
				arch_phy_mapping[i]  <= i;
			end
			
		end
		
		else begin
			phy_register_in_use <= phy_register_in_use_next;
			arch_phy_mapping <= arch_phy_mapping_next ;
		end
		
	end	
		
endmodule