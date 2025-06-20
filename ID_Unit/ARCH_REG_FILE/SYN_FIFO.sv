/*------------------------------------------------------------------------------
 * File          : SYN_FIFO.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 2, 2025
 * Description   :
 *------------------------------------------------------------------------------*/


`timescale 1ns/1ns


// Synchronous_FIFO.sv (Keep this in a separate file or above your rename unit)
module SYN_FIFO #(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 4, // log2(FIFO_DEPTH)
	parameter RESET_INITIAL_PUSH_EN = 1, // Enable initial push on reset
	parameter RESET_INITIAL_PUSH_START = 0, // Value to start pushing
	parameter RESET_INITIAL_PUSH_COUNT = 0  // Number of values to push
) (
	input  logic                   clk,
	input  logic                   reset,      // Asynchronous reset (active high)

	// Write Interface
	input  logic                   wr_en,      // Write enable
	input  logic [DATA_WIDTH-1:0]  wr_data,    // Data to write
	output logic                   full,       // FIFO is full (won't be connected in rename unit unless needed)

	// Read Interface
	input  logic                   rd_en,      // Read enable
	output logic [DATA_WIDTH-1:0]  rd_data,    // Data read
	output logic                   empty       // FIFO is empty
);

	localparam FIFO_DEPTH = 1 << ADDR_WIDTH; // Calculate FIFO depth

	// Internal Memory
	logic [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];

	// Pointers
	logic [ADDR_WIDTH-1:0] wr_ptr_reg, rd_ptr_reg; // Registers for pointers
	logic [ADDR_WIDTH-1:0] wr_ptr_next, rd_ptr_next; // Next values for pointers

	// Full/Empty logic - uses fill_count for simplicity
	logic [ADDR_WIDTH:0]   fill_count_reg;   // Stores number of elements in FIFO
	logic [ADDR_WIDTH:0]   fill_count_next;

	// --- Combinational Logic for Next State ---

	// Calculate next write pointer
	always_comb begin
		wr_ptr_next = wr_ptr_reg;
		if (wr_en && (fill_count_reg < FIFO_DEPTH)) begin // Only increment if writing and not full
			wr_ptr_next = wr_ptr_reg + 1;
		end
	end

	// Calculate next read pointer
	always_comb begin
		rd_ptr_next = rd_ptr_reg;
		if (rd_en && (fill_count_reg > 0)) begin // Only increment if reading and not empty
			rd_ptr_next = rd_ptr_reg + 1;
		end
	end

	// Calculate next fill count
	always_comb begin
		fill_count_next = fill_count_reg;
		if (wr_en && (fill_count_reg < FIFO_DEPTH) && (!rd_en || (fill_count_reg == 0))) begin
			// Only writing OR writing to an empty FIFO while also reading
			fill_count_next = fill_count_reg + 1;
		end else if (rd_en && (fill_count_reg > 0) && (!wr_en || (fill_count_reg == FIFO_DEPTH))) begin
			// Only reading OR reading from a full FIFO while also writing
			fill_count_next = fill_count_reg - 1;
		end
		// If both read and write happen simultaneously and FIFO is not full/empty, count remains same
		// (fill_count_next = fill_count_reg + 1 - 1 = fill_count_reg)
	end

	// Output Data: Read from the current read pointer
	assign rd_data = fifo_mem[rd_ptr_reg];

	// Full and Empty flags
	assign full  = (fill_count_reg == FIFO_DEPTH);
	assign empty = (fill_count_reg == 0);


	// --- Sequential Logic (Registers and Memory Updates) ---

	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			wr_ptr_reg   <= '0;
			rd_ptr_reg   <= '0;
			fill_count_reg <= '0;
			
			// ** INITIALIZE MEMORY FOR FREE LIST SCENARIO **
			if (RESET_INITIAL_PUSH_EN) begin
				for (int i = 0; i < RESET_INITIAL_PUSH_COUNT; i++) begin
					fifo_mem[i] <= RESET_INITIAL_PUSH_START + i;
				end
				wr_ptr_reg   <= RESET_INITIAL_PUSH_COUNT;
				fill_count_reg <= RESET_INITIAL_PUSH_COUNT;
			end
		end else begin
			// Update write pointer
			wr_ptr_reg <= wr_ptr_next;

			// Update read pointer
			rd_ptr_reg <= rd_ptr_next;

			// Update fill count
			fill_count_reg <= fill_count_next;

			// Write to memory if write enable is active and FIFO is not full
			if (wr_en && (fill_count_reg < FIFO_DEPTH)) begin // Use current fill_count_reg for 'full' check
				fifo_mem[wr_ptr_reg] <= wr_data; // Write data to memory at current write pointer
			end
		end
	end

endmodule