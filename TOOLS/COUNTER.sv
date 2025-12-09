/*------------------------------------------------------------------------------
 * File          : COUNTER.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Dec 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module COUNTER #(
	parameter WIDTH = 4  
)(
	input  logic         clk,   
	input  logic         reset, 
	input  logic         en,    
	input  logic		 init_cntr,
	output logic [WIDTH-1:0] count  
);

	always_ff @(posedge clk, posedge reset) begin
		if (reset) begin
			count <= {WIDTH{1'b0}}; 
		end
		else if (init_cntr) begin
			count <= {WIDTH{1'b0}};
		end
		else if (en) begin
			count <= count + 1'b1;
		end
		
	end

endmodule