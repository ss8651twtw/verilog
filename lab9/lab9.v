`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer: Chun-Jen Tsai
//
// Create Date:    14:24:54 11/29/2016 
// Design Name: 
// Module Name:    lab9 
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
module lab9(
  input clk,
  input reset,
  input  button,
  output [7:0] led,
  output LCD_E,
  output LCD_RS,
  output LCD_RW,
  output [3:0] LCD_D,
  input ROT_A,
  input ROT_B
  );

  // declare system variables
  wire btn_level, btn_pressed;
  reg prev_btn_level;
  reg [127:0] row_A, row_B;
  reg freq;          // Frequency: 25, 100 Hz
  reg [2:0]  pwm_dc; // duty cycle: 12.5%, 25%, 50%, 75% 100%
  reg [21:0] period [0:1];
  reg [21:0] period_on [0:1][0:4];
  reg [21:0] counter;
  wire switch;
  wire rot_event;
  wire rot_right;

  assign led = (switch) ? 255 : 0;
  assign switch = (counter < period_on[freq][pwm_dc])? 1 : 0;

  debounce btn_db0(
    .clk(clk),
    .btn_input(button),
    .btn_output(btn_level)
  );

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

  Rotation_direction RTD(
    .CLK(clk),
    .ROT_A(ROT_A),
    .ROT_B(ROT_B),
    .rotary_event(rot_event),
    .rotary_right(rot_right)
  );

  // ------------------------------------------------------------------------
  // The following code detects the positive edge of the button-press signal.
  always @(posedge clk) begin
    if (reset) begin
      prev_btn_level <= 1'b1;
    end
    else begin
      prev_btn_level <= btn_level;
    end
  end

  assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1'b1 : 1'b0;
  // End of button-press signal edge detector.
  // ------------------------------------------------------------------------

  // ------------------------------------------------------------------------
  // The following code updates the 1602 LCD text messages.
  always @(posedge clk) begin
    if (reset) begin
      row_A <= "Frequency: 100Hz";
      row_B <= "Duty cycle:xxxx%";
    end
    else begin
      case (freq)
      1'b0 : row_A[39:16] <= " 25";
      1'b1 : row_A[39:16] <= "100";
      endcase

      case (pwm_dc)
      3'b000  : row_B[39:8] <= "   5";
      3'b001  : row_B[39:8] <= "  25";
      3'b010  : row_B[39:8] <= "  50";
      3'b011  : row_B[39:8] <= "  75";
      3'b100  : row_B[39:8] <= " 100";
      default : row_B[39:8] <= "    ";
      endcase
    end
  end
  // End of the 1602 LCD text-updating code.
  // ------------------------------------------------------------------------

  initial begin
    // set base frequency period
    period[0] = 22'd2_000_000;  // 25Hz
    period[1] =   22'd500_000;  // 100Hz

    period_on[0][0] = 22'd100_000;    // 25Hz, 5%
    period_on[0][1] = 22'd500_000;    // 25Hz, 25%
    period_on[0][2] = 22'd1_000_000;  // 25Hz, 50%
    period_on[0][3] = 22'd1_500_000;  // 25Hz, 75%
    period_on[0][4] = 22'd2_000_000;  // 25Hz, 100%

    period_on[1][0] = 22'd25_000;     // 100Hz, 5%
    period_on[1][1] = 22'd125_000;    // 100Hz, 25%
    period_on[1][2] = 22'd250_000;    // 100Hz, 50%
    period_on[1][3] = 22'd375_000;    // 100Hz, 75%
    period_on[1][4] = 22'd500_000;    // 100Hz, 100%
  end

  always@ (posedge clk) begin
    if (reset)
      pwm_dc <= 3'b010;
    else if (rot_event && !rot_right && pwm_dc < 3'b100)
      pwm_dc <= pwm_dc + 1;
    else if (rot_event && rot_right && pwm_dc > 3'b000)
      pwm_dc <= pwm_dc - 1;
  end

  always@ (posedge clk) begin
    if (reset)
      freq <= 1'b0;
    else if (btn_pressed)
      freq <= 1 - freq;
  end

  always@ (posedge clk) begin
    if (reset)
      counter <= 22'd0;
    else
      counter <= (counter < period[freq])? counter + 1 : 0;
  end

endmodule
