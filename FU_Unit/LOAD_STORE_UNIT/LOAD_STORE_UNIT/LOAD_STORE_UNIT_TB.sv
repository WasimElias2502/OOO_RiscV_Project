/*------------------------------------------------------------------------------
 * File          : LOAD_STORE_UNIT_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 29, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module LOAD_STORE_UNIT_TB #() ();

	logic clk, reset;

	logic [`ROB_SIZE_WIDTH-1:0] issued_tag;
	logic issue_valid;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] issue_reg_dst;
	memory_op_t issue_mem_op;

	logic [`D_MEMORY_ADDR_WIDTH-1:0] req_memory_addr;
	logic req_valid;
	logic [`ROB_SIZE_WIDTH-1:0] req_tag;
	logic [`REG_VAL_WIDTH-1:0] req_data;

	logic [`ROB_SIZE_WIDTH-1:0]						commited_tag [`MAX_NUM_OF_COMMITS-1:0];
	logic [`MAX_NUM_OF_COMMITS-1:0]					commit_valid;

	logic ld_st_ready;

	logic cdb_valid;
	logic [`PHYSICAL_REG_NUM_WIDTH-1:0] cdb_register_addr;
	logic [`REG_VAL_WIDTH-1:0] cdb_register_val;
	logic [`ROB_SIZE_WIDTH-1:0] cdb_inst_tag;

	logic memory_ready;
	logic memory_ack;
	logic [`REG_VAL_WIDTH-1:0] memory_data_return;

	logic memory_req_valid;
	memory_op_t memory_req_op;
	logic [`D_MEMORY_ADDR_WIDTH-1:0] memory_req_address;
	logic [`REG_VAL_WIDTH-1:0] memory_req_data;

	LOAD_STORE_UNIT dut (
		.clk(clk),
		.reset(reset),
		.issued_tag(issued_tag),
		.issue_valid(issue_valid),
		.issue_reg_dst(issue_reg_dst),
		.issue_mem_op(issue_mem_op),
		.req_memory_addr(req_memory_addr),
		.req_valid(req_valid),
		.req_tag(req_tag),
		.req_data(req_data),
		.commited_tag(commited_tag),
		.commit_valid (commit_valid),
		.ld_st_ready(ld_st_ready),
		.cdb_valid(cdb_valid),
		.cdb_register_addr(cdb_register_addr),
		.cdb_register_val(cdb_register_val),
		.cdb_inst_tag(cdb_inst_tag),
		.memory_ready(memory_ready),
		.memory_ack(memory_ack),
		.memory_data_return(memory_data_return),
		.memory_req_valid(memory_req_valid),
		.memory_req_op(memory_req_op),
		.memory_req_address(memory_req_address),
		.memory_req_data(memory_req_data)
	);

	always #5 clk = ~clk;

	task issue_inst(input int tag, input memory_op_t op, input int dst_reg);
		@(posedge clk);
		issued_tag <= tag;
		issue_valid <= 1;
		issue_mem_op <= op;
		issue_reg_dst <= dst_reg;
		@(posedge clk);
		issue_valid <= 0;
	endtask

	task request(input int tag, input longint addr, input longint data);
		@(posedge clk);
		req_tag <= tag;
		req_memory_addr <= addr;
		req_data <= data;
		req_valid <= 1;
		@(posedge clk);
		req_valid <= 0;
	endtask

	task commit_inst(input int tag);
		
		repeat(20) @(posedge clk);
		
		@(posedge clk);
		commited_tag[0] <= tag;
		commit_valid <= 1'b1;
		@(posedge clk);
		commited_tag[0] <= '0;
		commit_valid <= 1'b0;
	endtask

	task memory_respond(input bit is_load, input longint ret_data);
			@(posedge clk);
			memory_ready <= 1;
			
			wait(memory_req_valid);
			
			@(posedge clk);
			memory_ready <= 0;
			repeat(7) @(posedge clk);
			memory_ack <= 1;
			memory_data_return <= is_load ? ret_data : '0;
			@(posedge clk);
			memory_ack <= 0;
	endtask

	initial begin
		clk = 0;
		reset = 1;
		issue_valid = 0;
		req_valid = 0;
		memory_ready = 0;
		memory_ack = 0;
		for(int i=0 ; i<`MAX_NUM_OF_COMMITS ; i++) begin
			commited_tag[i] = 0;
		end
		#(20);
		reset = 0;
		
		fork 
			begin
				memory_respond(1, 32'hAABBCCDD);
				memory_respond(0, 0);
				memory_respond(1, 32'hBAD);
			end
		join_none


		// ===== TEST SEQUENCE =====
		//Isuue 3->4->5
		issue_inst(3, mem_read, 5);
		issue_inst(4, mem_write,'0);
		issue_inst(5, mem_read, 7);

		#50
		
		//Request 4->3->5
		request(4, 32'h2000, 32'h11112222);		
		request(3, 32'h1000, '0);
		request(5, 32'h2000, '0);			//4 should forward to 5

		
		commit_inst(3);
		commit_inst(4);
		
		
		

		#(1000);
		$finish;
	end

endmodule