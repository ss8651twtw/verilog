`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:33:02 11/18/2016
// Design Name:   lab7
// Module Name:   C:/Users/hung/Desktop/lab7/lab7/tb.v
// Project Name:  lab7
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lab7
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb;

	// Inputs
	reg clk;
	reg reset;
	reg button;

	// Outputs
	wire LCD_E;
	wire LCD_RS;
	wire LCD_RW;
	wire [3:0] LCD_D;
	integer idx ;
	// Instantiate the Unit Under Test (UUT)
	lab7 uut (
		.clk(clk), 
		.reset(reset), 
		.button(button), 
		.LCD_E(LCD_E), 
		.LCD_RS(LCD_RS), 
		.LCD_RW(LCD_RW), 
		.LCD_D(LCD_D)
	);


	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		button = 0;
		
		#5 reset = 1;
		#10 reset = 0;

		// Wait 100 ns for global reset to finish
		#1000 ;
		
		#8000 button = 1;
		for (idx = 0; idx < 14; idx = idx + 1)
		  #20 button = $random % 2;
		#100 button = 1;
		#1000 button = 0;
		// Add stimulus here

	end
	
  // System clock generator.
  parameter SYSTEM_CLOCK_FREQUENCY = 50; /* MHz */
  parameter CLOCK_PERIOD = 1000/SYSTEM_CLOCK_FREQUENCY; /* nsec */
	
	always #(CLOCK_PERIOD/2) clk = ! clk;
	
      
endmodule

