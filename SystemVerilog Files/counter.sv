/*------------------------------------------------------------------------------
 * File          : counter.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : Nov 14, 2023
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module counter (
	input  clk,       		// Clock input
	input  RESETn,     		// Reset input
	input  init,			//initialize the counter to zero
	input  trigger,      		// Input to trigger counting
	input  classification,
	output [10:0] count  // Counter output
  );

	// Internal counter variable
	reg [10:0] internal_count;

	// Always block to update the counter
	always @(posedge clk or negedge RESETn) begin
	  // Reset the counter if reset is 1
	  if (!RESETn) internal_count <= #1 11'b0;
	 
	  // Reset the counter if reset is 1
	  else if (init) internal_count <= #1 11'b0;
	
	  // Increment the counter if done is 1
	  else if (trigger) internal_count <= #1 internal_count + classification;
	 
	  // No action if done is 0
	end

	// Assign the counter value to the output
	assign count = internal_count;

  endmodule