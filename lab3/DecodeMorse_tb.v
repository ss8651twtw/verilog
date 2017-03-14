`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:50:55 09/29/2016
// Design Name:   morse_decode
// Module Name:   C:/Users/hung/Desktop/test/test/morse_tb.v
// Project Name:  test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: morse_decode
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module DecodeMorse_tb;

	// Inputs
	reg clk;
	reg enable_0,enable_1,enable_2,enable_3,enable_4,enable_5,enable_6;
	reg [79:0] in_bits_0,in_bits_1,in_bits_2,in_bits_3,in_bits_4,in_bits_5,in_bits_6;

	// Outputs
	wire [34:0] out_text_0,out_text_1,out_text_2,out_text_3,out_text_4,out_text_5,out_text_6;
	wire valid_0,valid_1,valid_2,valid_3,valid_4,valid_5,valid_6;
	
	reg [79:0] data [6:0] ;
	
	
	integer i,correct_cnt ; 
	// Instantiate the Unit Under Test (UUT)
	DecodeMorse uut0 (.clk(clk), .enable(enable_0), .in_bits(in_bits_0), .out_text(out_text_0), .valid(valid_0));
	DecodeMorse uut1 (.clk(clk), .enable(enable_1), .in_bits(in_bits_1), .out_text(out_text_1), .valid(valid_1));
	DecodeMorse uut2 (.clk(clk), .enable(enable_2), .in_bits(in_bits_2), .out_text(out_text_2), .valid(valid_2));
	DecodeMorse uut3 (.clk(clk), .enable(enable_3), .in_bits(in_bits_3), .out_text(out_text_3), .valid(valid_3));
	DecodeMorse uut4 (.clk(clk), .enable(enable_4), .in_bits(in_bits_4), .out_text(out_text_4), .valid(valid_4));
	DecodeMorse uut5 (.clk(clk), .enable(enable_5), .in_bits(in_bits_5), .out_text(out_text_5), .valid(valid_5));
	DecodeMorse uut6 (.clk(clk), .enable(enable_6), .in_bits(in_bits_6), .out_text(out_text_6), .valid(valid_6));

	initial begin
		// Initialize Inputs
		clk = 0;
		correct_cnt = 0 ; 
		enable_0 = 1'b0 ;
		enable_1 = 1'b0 ;
		enable_2 = 1'b0 ;
		enable_3 = 1'b0 ;
		enable_4 = 1'b0 ;
		enable_5 = 1'b0 ;
		enable_6 = 1'b0 ;

		in_bits_0 = 80'b0 ; 
		in_bits_1 = 80'b0 ; 
		in_bits_2 = 80'b0 ; 
		in_bits_3 = 80'b0 ; 
		in_bits_4 = 80'b0 ; 
		in_bits_5 = 80'b0 ; 
		in_bits_6 = 80'b0 ; 

		
		// test case 0 
		in_bits_0 ={48'b101110001110101010001110101110100011101010001000,32'b0} ;  //ABCDE
		repeat(3)@(negedge clk);
		enable_0 	= 1'b1 ;
		check_ans(0) ;
		
		// test case 1
		in_bits_1 ={56'b10101110100011101110100010101010001010001011101110111000,24'b0}; // FGHIJ
		repeat(3)@(negedge clk);
		enable_1 	= 1'b1 ;
		check_ans(1) ;		
		
		in_bits_2 ={56'b11101011100010111010100011101110001110100011101110111000,24'b0}; // KLMNO
		repeat(3)@(negedge clk);
		enable_2 	= 1'b1 ;
		check_ans(2) ;		
		
		in_bits_3 ={54'b101110111010001110111010111000101110100010101000111000,26'b0}; // PQRST
		repeat(3)@(negedge clk);
		enable_3 	= 1'b1 ;
		check_ans(3) ;		
		
		in_bits_4 ={64'b1010111000101010111000101110111000111010101110001110101110111000,16'b0};  // UVWXY
		repeat(3)@(negedge clk);
		enable_4 	= 1'b1 ;
		check_ans(4) ;		
		
		in_bits_5 ={70'b1110111010100011101110101000111011101010001110111010100011101110101000,10'b0}; // ZZZZZ
		repeat(3)@(negedge clk);
		enable_5 	= 1'b1 ;
		check_ans(5) ;		
		
		in_bits_6 ={46'b1110111000111011101110001011101000101010001000, 34'b0} ; //  MORSE
		repeat(3)@(negedge clk);
		enable_6 	= 1'b1 ;
		check_ans(6) ;	

		repeat(3)@(negedge clk);
	 
		result ; 
		$finish ;

	end
      
	always  #10 clk = ~clk ; 
	
task check_ans; 
	input integer case_number ;
begin 
	if(case_number==0)		wait(valid_0) ;
	else if(case_number==1)	wait(valid_1) ;
	else if(case_number==2)	wait(valid_2) ;
	else if(case_number==3)	wait(valid_3) ;
	else if(case_number==4)	wait(valid_4) ;
	else if(case_number==5)	wait(valid_5) ;
	else if(case_number==6)	wait(valid_6) ;
	else $display(" valid error ");
	@(negedge clk);
	$display("=========================================");
	$write("test case %1d :   ",case_number);
	
	if(case_number==0)	$display("your answer is %C%C%C%C%C",out_text_0[34:28],out_text_0[27:21], out_text_0[20:14],out_text_0[13:7],out_text_0[6:0]);
	else if(case_number==1)	$display("your answer is %C%C%C%C%C",out_text_1[34:28],out_text_1[27:21], out_text_1[20:14],out_text_1[13:7],out_text_1[6:0]);
	else if(case_number==2)	$display("your answer is %C%C%C%C%C",out_text_2[34:28],out_text_2[27:21], out_text_2[20:14],out_text_2[13:7],out_text_2[6:0]);
	else if(case_number==3)	$display("your answer is %C%C%C%C%C",out_text_3[34:28],out_text_3[27:21], out_text_3[20:14],out_text_3[13:7],out_text_3[6:0]);
	else if(case_number==4)	$display("your answer is %C%C%C%C%C",out_text_4[34:28],out_text_4[27:21], out_text_4[20:14],out_text_4[13:7],out_text_4[6:0]);
	else if(case_number==5)	$display("your answer is %C%C%C%C%C",out_text_5[34:28],out_text_5[27:21], out_text_5[20:14],out_text_5[13:7],out_text_5[6:0]);
	else if(case_number==6)	$display("your answer is %C%C%C%C%C",out_text_6[34:28],out_text_6[27:21], out_text_6[20:14],out_text_6[13:7],out_text_6[6:0]);
	else $display("testbench error ");
	$display("=========================================");
	
	
	if(case_number==0)			begin if(out_text_0 === {7'd65,7'd66,7'd67,7'd68,7'd69}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==1)	begin if(out_text_1 === {7'd70,7'd71,7'd72,7'd73,7'd74}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==2)	begin if(out_text_2 === {7'd75,7'd76,7'd77,7'd78,7'd79}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==3)	begin if(out_text_3 === {7'd80,7'd81,7'd82,7'd83,7'd84}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==4)	begin if(out_text_4 === {7'd85,7'd86,7'd87,7'd88,7'd89}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==5)	begin if(out_text_5 === {7'd90,7'd90,7'd90,7'd90,7'd90}) correct_cnt = correct_cnt + 1 ;  end
	else if(case_number==6)	begin if(out_text_6 === {7'd77,7'd79,7'd82,7'd83,7'd69}) correct_cnt = correct_cnt + 1 ;  end
	
	
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
end endtask

task result; 
begin 
	$display("");
	if(correct_cnt === 7) begin 
		$display("*****************************************");
		$display("                               PASS");
		$display("*****************************************");
	end 
	else begin 
		$display("*****************************************");
		$display("                               FAIL");
		$display("*****************************************");
	end 
	@(negedge clk);
end endtask


  
endmodule

