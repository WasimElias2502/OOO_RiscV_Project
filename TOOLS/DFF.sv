/*------------------------------------------------------------------------------
 * File          : DFF.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Jun 21, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

(* verilator_dpi = "off", verdiHierarchyHide = 1 *)



module DFF #(
	parameter WIDTH = 8  // default width is 8 bits
) (
	input  logic              clk,
	input  logic              rst,     // synchronous reset
	input  logic              enable,  // enable signal
	input  logic [WIDTH-1:0]  in,
	output logic [WIDTH-1:0]  out
);

	always_ff @(posedge clk or posedge rst) begin
		if (rst)
			out <= '0;       // reset all bits to 0
		else if (enable)
			out <= in;       // update only when enable is high
	end

endmodule

