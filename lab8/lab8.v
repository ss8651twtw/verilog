`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date:    11:26:45 11/23/2016 
// Design Name: 
// Module Name:    lab8 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lab8(
  input clk,
  input reset,
  input button,
  output [7:0] led,
  output LCD_E,
  output LCD_RS,
  output LCD_RW,
  output [3:0] LCD_D
  );

  // declare system variables
  wire btn_level, btn_pressed;
  reg prev_btn_level;
  reg [127:0] row_A, row_B;
  reg [15:0]  pixel_addr;

  // declare SRAM control signals
  wire [13:0] sram_addr;
  wire [7:0]  data_in;
  wire [7:0]  data_out;
  wire        we, en;
  reg [1:0] Q , Q_NEXT;
  reg [7:0]image_data;
  reg [39:0]convolution_data;
  reg signed[10:0]sum;
  reg [15:0]edge_counter;
  wire [31:0]edge_pixel ;
  parameter Q_IDLE = 0, Q_CAL = 1, Q_OUTPUT = 2;
  parameter start_addr = 160;
  parameter end_addr = 160*89+4;
  // assign led = pixel_data;
  

  LCD_module lcd0( 
    .clk(clk),
    .reset(reset),
    .row_A(row_A),
    .row_B(row_B),
    .LCD_E(LCD_E),
    .LCD_RS(LCD_RS),
    .LCD_RW(LCD_RW),
    .LCD_D(LCD_D)
  );
  
  debounce btn_db0(
    .clk(clk),
    .btn_input(button),
    .btn_output(btn_level)
  );

  // ------------------------------------------------------------------------
  // The following code describes an initialized SRAM memory block that
  // stores an 160x90 8-bit graylevel image.
  sram ram0(.clk(clk), .we(we), .en(en),
            .addr(sram_addr), .data_i(data_in), .data_o(data_out));

  assign we = 0; // Make the SRAM read-only.
  assign en = 1; // Always enable the SRAM block.
  assign sram_addr = pixel_addr[13:0];
  assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
  // End of the SRAM memory block.
  // ------------------------------------------------------------------------

  always @(posedge clk)begin
    if(reset)
	  Q <= Q_IDLE;
	else 
	  Q <= Q_NEXT;
  end
  
  always @(*)begin
    case(Q)
     Q_IDLE: Q_NEXT = Q_CAL;
	  Q_CAL:  Q_NEXT = (pixel_addr == end_addr+3)?Q_OUTPUT:Q_CAL;
	  Q_OUTPUT:Q_NEXT = Q_OUTPUT;
	  default: Q_NEXT = Q;
	endcase
  end

  
  assign edge_pixel[7 :0 ] = ((edge_counter[3 :0 ] > 9)? "7" : "0") + edge_counter[3 :0 ];
  assign edge_pixel[15:8 ] = ((edge_counter[7 :4 ] > 9)? "7" : "0") + edge_counter[7 :4 ];
  assign edge_pixel[23:16] = ((edge_counter[11:8 ] > 9)? "7" : "0") + edge_counter[11:8 ];
  assign edge_pixel[31:24] = ((edge_counter[15:12] > 9)? "7" : "0") + edge_counter[15:12];
  
  // End of the 1602 LCD text-updating code.
  // ------------------------------------------------------------------------

  // ------------------------------------------------------------------------
  // The following code detects the positive edge of the button-press signal.
  always @(posedge clk) begin
    if (reset)
      prev_btn_level <= 1'b1;
    else
      prev_btn_level <= btn_level;
  end

  assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1'b1 : 1'b0;
  // End of button-press signal edge detector.
  // ------------------------------------------------------------------------

  
  // ------------------------------------------------------------------------
  // The main code that processes the user's button event.
  reg data_fetch;

  always @(posedge clk) begin
    if (Q == Q_IDLE) 
      pixel_addr <= start_addr;
    else if (Q == Q_CAL) 
      pixel_addr <= pixel_addr + 1;
  end
  
  always @(posedge clk)begin
    image_data <= data_out;
  end
  
  always @(posedge clk)begin
    if(Q == Q_IDLE)
	  convolution_data <= 0;
	else if(Q == Q_CAL)begin
	  convolution_data <= convolution_data << 8;
	  convolution_data[7:0] <= image_data;
	end
  end
  
  
  always @(posedge clk)begin
    if(Q == Q_IDLE)begin
	  sum <= 0;
	end
	else if(Q == Q_CAL && pixel_addr >= 167)
	  sum <= (convolution_data[39:32]) +  (convolution_data[31:24] * 2) - ((convolution_data[15:8] * 2) + (convolution_data[7:0]));	
  end
  
  always @(posedge clk)begin
    if(Q == Q_IDLE)
	  edge_counter <= 0;
	else if(Q == Q_CAL && pixel_addr >= 168)
	  edge_counter <= edge_counter + ((sum > 200) || (sum < -200));
  end
  
  always @(posedge clk) begin
    if (reset) begin
      row_A <= "Press WEST to   ";
      row_B <= "edge detection..";
    end
    else if (Q == Q_OUTPUT) begin
      row_A <=  "The edge pixel  ";
      row_B <= {"  number is ",edge_pixel};
    end
  end
  // End of the main code.
  // ------------------------------------------------------------------------

endmodule
