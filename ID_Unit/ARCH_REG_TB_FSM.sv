/*------------------------------------------------------------------------------
 * File          : ARCH_REG_TB_FSM.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 17, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module ARCH_REG_TB_FSM #(
	ARCH_REG_NUM_WIDTH    = `ARCH_REG_NUM_WIDTH,
	PHYSICAL_REG_NUM_WIDTH= `PHYSICAL_REG_NUM_WIDTH
) ();
	
	// DUT inputs
	logic clk;
	logic reset;
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num1;
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_read_reg_num2;
	logic [ARCH_REG_NUM_WIDTH-1:0] arch_write_reg_num;
	logic regwrite;
	logic commit_valid;
	logic commit_with_write;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] commited_wr_register;
	
	// DUT outputs
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num1;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_read_reg_num2;
	logic [PHYSICAL_REG_NUM_WIDTH-1:0] phy_write_reg_num;
	logic 							   valid;
	
	// Instantiate DUT
	ARCH_REG_FILE #(
		.ARCH_REG_NUM_WIDTH(ARCH_REG_NUM_WIDTH),
		.PHYSICAL_REG_NUM_WIDTH(PHYSICAL_REG_NUM_WIDTH)
	) dut (
		.clk(clk),
		.reset(reset),
		.arch_read_reg_num1(arch_read_reg_num1),
		.arch_read_reg_num2(arch_read_reg_num2),
		.arch_write_reg_num(arch_write_reg_num),
		.regwrite(regwrite),
		.commit_valid(commit_valid),
		.commit_with_write(commit_with_write),
		.commited_wr_register(commited_wr_register),
		.phy_read_reg_num1(phy_read_reg_num1),
		.phy_read_reg_num2(phy_read_reg_num2),
		.phy_write_reg_num(phy_write_reg_num),
		.valid(valid)
	);
	
	// Clock generation: 40ns period (25 MHz)
	initial clk = 0;
	always #20 clk = ~clk;
	
	// Reset generation: Assert reset for first 40ns
	initial begin
		reset = 1'b1;
		#40;
		reset = 1'b0;
	end
	
	// Test sequence controller
	typedef enum logic [3:0] {
		IDLE,
		STEP1,
		STEP2,
		STEP3,
		STEP4,
		STEP5,
		STEP6,
		STEP7,
		DONE
	} test_state_t;
	
	test_state_t state, next_state;
	
	// Drive inputs using synchronous FSM
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= IDLE;
	
			// Reset inputs
			arch_read_reg_num1   <= '0;
			arch_read_reg_num2   <= '0;
			arch_write_reg_num   <= '0;
			regwrite             <= 1'b0;
			commit_valid         <= 1'b0;
			commit_with_write    <= 1'b0;
			commited_wr_register <= '0;
		end else begin
			state <= next_state;
			case (state)
				IDLE: begin
					// Idle state: do nothing
					arch_read_reg_num1   <= 0;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 0;
					regwrite             <= 0;
					commit_valid         <= 0;
					commit_with_write    <= 0;
					commited_wr_register <= 0;
				end
	
				STEP1: begin
					arch_read_reg_num1   <= 1;
					arch_read_reg_num2   <= 2;
					arch_write_reg_num   <= 3;
					regwrite             <= 1;
				end
	
				STEP2: begin
					arch_read_reg_num1   <= 1;
					arch_read_reg_num2   <= 3;
					arch_write_reg_num   <= 1;
					regwrite             <= 1;
				end
	
				STEP3: begin
					arch_read_reg_num1   <= 2;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 2;
					regwrite             <= 1;
				end
	
				STEP4: begin
					arch_read_reg_num1   <= 2;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 2;
					regwrite             <= 1;
				end
				
				STEP5: begin
					arch_read_reg_num1   <= 1;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 1;
					regwrite             <= 1;
				end
				
				STEP6: begin
					arch_read_reg_num1   <= 1;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 1;
					regwrite             <= 1;
					//commit command 3
					commit_valid         <= 1'b1;
					commit_with_write    <= 1'b1;
					commited_wr_register <= 6;
				end
				
				STEP7: begin
					arch_read_reg_num1   <= 1;
					arch_read_reg_num2   <= 0;
					arch_write_reg_num   <= 1;
					regwrite             <= 1;
					commit_valid         <= 1'b0;
					commit_with_write    <= 1'b0;
					commited_wr_register <= 0;
				end
				

	
				DONE: begin
					// Finish writing, stop register writes
					regwrite <= 0;
				end
			endcase
		end
	end
	
	// Next state logic (advance every clock)
	always_comb begin
		next_state = state;
		case(state)
			IDLE:   next_state = STEP1;
			STEP1:  next_state = STEP2;
			STEP2:  next_state = STEP3;
			STEP3:  next_state = STEP4;
			STEP4:  next_state = STEP5;
			STEP5:  next_state = STEP6;
			STEP6:  next_state = STEP7;
			STEP7:  next_state = DONE;
			DONE:   next_state = DONE;
			default: next_state = IDLE;
		endcase
	end
	
	// Stop simulation after some time
	initial begin
		#500 $finish;
	end
	
	// Dump waveform
	initial begin
		$dumpfile("ARCH_REG_TB_FSM.vcd");
		$dumpvars(0, ARCH_REG_TB_FSM);
	end


endmodule