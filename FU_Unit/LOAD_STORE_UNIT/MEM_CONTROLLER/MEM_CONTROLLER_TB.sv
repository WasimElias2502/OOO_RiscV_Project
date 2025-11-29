/*------------------------------------------------------------------------------
 * File          : MEM_CONTROLLER_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 29, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ns

module MEM_CONTROLLER_TB;

	logic clk, reset;

	logic         lsq_req_valid;
	memory_op_t   lsq_req_op;
	logic [31:0]  lsq_req_address;
	logic [31:0]  lsq_req_data;

	logic         mem_ctrl_ready;
	logic         mem_ctrl_done;
	logic [31:0]  mem_ctrl_data;

	logic         memory_ready;
	logic         memory_ack;
	logic [31:0]  memory_data_return;

	logic         memory_req_valid;
	memory_op_t   memory_req_op;
	logic [31:0]  memory_req_address;
	logic [31:0]  memory_req_data;

	MEM_CONTROLLER dut (
		.clk(clk),
		.reset(reset),
		.lsq_req_valid(lsq_req_valid),
		.lsq_req_op(lsq_req_op),
		.lsq_req_address(lsq_req_address),
		.lsq_req_data(lsq_req_data),
		.mem_ctrl_ready(mem_ctrl_ready),
		.mem_ctrl_done(mem_ctrl_done),
		.mem_ctrl_data(mem_ctrl_data),
		.memory_ready(memory_ready),
		.memory_ack(memory_ack),
		.memory_data_return(memory_data_return),
		.memory_req_valid(memory_req_valid),
		.memory_req_op(memory_req_op),
		.memory_req_address(memory_req_address),
		.memory_req_data(memory_req_data)
	);

	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#35 reset = 1'b0;
			#2000 reset = 1'b1;
		end

	initial begin
		clk = 0;
		lsq_req_valid = 0;
		memory_ready = 0;
		memory_ack = 0;
		memory_data_return = 0;
		
		#50
		// request
		@(posedge clk);
		wait(mem_ctrl_ready);
		lsq_req_valid = 1;
		lsq_req_op = mem_read;
		lsq_req_address = 32'hA0;
		lsq_req_data = 32'h0;

		@(posedge clk);

		// memory accepts request
		repeat(3) @(posedge clk);
		memory_ready = 1;
		@(posedge clk);
		memory_ready = 0;

		// memory returns result
		repeat(4) @(posedge clk);
		memory_ack = 1;
		memory_data_return = 32'h12345678;
		@(posedge clk);
		memory_ack = 0;

		repeat(10) @(posedge clk);

	end
	
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("MEM_CONTROLLER_TB_output_wave.vcd");
			$fsdbDumpvars(0,MEM_CONTROLLER_TB);
		end
	
	//end test after 500ns
	initial 
		#1500 $finish;



endmodule
