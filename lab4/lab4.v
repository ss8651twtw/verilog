`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer:
// 
// Create Date:
// Design Name: 
// Module Name:    lab4 
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
module lab4(
    input clk,
    input reset,
    input rx,
    output tx,
    output [7:0] led
    );
 
localparam [1:0] S_INIT = 2'b00, S_PROMPT = 2'b01, S_WAIT_KEY = 2'b10, S_HELLO = 2'b11;
localparam [1:0] S_IDLE = 2'b00, S_WAIT = 2'b01, S_SEND = 2'b10, S_INCR = 2'b11;
localparam MEM_SIZE = 64;
localparam PROMPT_STR = 0; 
localparam HELLO_STR = 25;

// declare system variables
wire enter_pressed;
wire [4:0] string_id;
reg print_enable, print_done;
reg [5:0] send_counter;
reg [1:0] P, P_next;
reg [1:0] Q, Q_next;
reg [7:0] data[0:MEM_SIZE-1];
reg [15:0] init_counter;

reg [15:0]num_reg;
reg [2:0]cnt;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

wire [31:0] HEX;
wire [7:0] temp;

assign enter_pressed  = (rx_temp == 8'h0D);
assign temp =(rx_byte>8'h2F && rx_byte<8'h3A && cnt<5)?rx_byte:0;
assign led = 8'h00;
assign tx_byte = (received)?temp:data[send_counter];

uart uart(
    .clk(clk),
    .rst(reset),
    .rx(rx),
    .tx(tx),
    .transmit(transmit),
    .tx_byte(tx_byte),
    .received(received),
    .rx_byte(rx_byte),
    .is_receiving(is_receiving),
    .is_transmitting(is_transmitting),
    .recv_error(recv_error)
    );

BinToHex H2A1(.A(num_reg), .B(HEX));

// Initializes some strings.
always @(posedge clk) begin
  if (reset) begin
    data[ 0] <= 8'h45; // "Enter "
    data[ 1] <= 8'h6E;
    data[ 2] <= 8'h74;
    data[ 3] <= 8'h65;
    data[ 4] <= 8'h72;	
    data[ 5] <= 8'h20;	
    data[ 6] <= 8'h61; // "a "
    data[ 7] <= 8'h20;	
    data[ 8] <= 8'h64; // "decimal "
    data[ 9] <= 8'h65;
    data[10] <= 8'h63;
    data[11] <= 8'h69;
    data[12] <= 8'h6D;
    data[13] <= 8'h61;
    data[14] <= 8'h6C;	
    data[15] <= 8'h20;	
    data[16] <= 8'h6E; // "number: "
    data[17] <= 8'h75;
    data[18] <= 8'h6D;
    data[19] <= 8'h62;
    data[20] <= 8'h65;
    data[21] <= 8'h72;	
    data[22] <= 8'h3A;
    data[23] <= 8'h20;
    data[24] <= 8'h00;

    data[25] <= 8'h0D; // CR
    data[26] <= 8'h0D; // CR
    data[27] <= 8'h0A; // LF
    data[28] <= 8'h54; // "The hexadecimal number is: "
    data[29] <= 8'h68;
    data[30] <= 8'h65;	
    data[31] <= 8'h20;	
    data[32] <= 8'h68;
    data[33] <= 8'h65;
    data[34] <= 8'h78;
    data[35] <= 8'h61;
    data[36] <= 8'h64;
    data[37] <= 8'h65;
    data[38] <= 8'h63;
    data[39] <= 8'h69;
    data[40] <= 8'h6D;
    data[41] <= 8'h61;
    data[42] <= 8'h6C;
    data[43] <= 8'h20;	
    data[44] <= 8'h6E;
    data[45] <= 8'h75;
    data[46] <= 8'h6D;
    data[47] <= 8'h62;
    data[48] <= 8'h65;
    data[49] <= 8'h72;
    data[50] <= 8'h20;	
    data[51] <= 8'h69;
    data[52] <= 8'h73;
    data[53] <= 8'h3A;
    data[54] <= 8'h20;

    data[55] <= 8'h00; // the 4-digit HEX
    data[56] <= 8'h00;
    data[57] <= 8'h00;
    data[58] <= 8'h00;

    data[59] <= 8'h0D; // CR
    data[60] <= 8'h0A; // LF
    data[61] <= 8'h0D; // CR
    data[62] <= 8'h0A; // LF
    data[63] <= 8'h00;
  end
  else begin
    data[55] <= HEX[31:24];
    data[56] <= HEX[23:16];
    data[57] <= HEX[15:8];
    data[58] <= HEX[7:0];
  end
end

// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
//
always @(posedge clk) begin
  if (reset) P <= S_INIT; 
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_INIT: // wait 1 ms for the UART controller to initialize.
	   if (init_counter < 50000) P_next = S_INIT;
		else P_next = S_PROMPT;
    S_PROMPT: // Print the prompt message.
      if (print_done) P_next = S_WAIT_KEY;
      else P_next = S_PROMPT;
    S_WAIT_KEY: // wait for <Enter> key.
      if (enter_pressed) P_next = S_HELLO;
      else P_next = S_WAIT_KEY;
    S_HELLO: // Print the hello message.
      if (print_done) P_next = S_PROMPT;
      else P_next = S_HELLO;
  endcase
end

// FSM output logics
assign string_id = (P_next == S_PROMPT)? PROMPT_STR : HELLO_STR;

always @(posedge clk) begin
  if (reset) print_enable <= 0;
  else print_enable <= (P_next == S_PROMPT) | (P_next == S_HELLO);
end

// Initialization counter.
always @(posedge clk) begin
  if (reset) init_counter <= 0;
  else init_counter <= init_counter + 1;
end

//
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller to send a string to the UART.
//
always @(posedge clk) begin
  if (reset) Q <= S_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_IDLE: // wait for print_string flag
      if (print_enable) Q_next = S_WAIT;
      else Q_next = S_IDLE;
    S_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_SEND;
      else Q_next = S_WAIT;
    S_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_INCR; // transmit next character
      else Q_next = S_SEND;
    S_INCR:
      if (tx_byte == 8'h0) Q_next = S_IDLE; // string transmission ends
      else Q_next = S_WAIT;
  endcase
end

// FSM output logics
assign transmit = (Q == S_WAIT || received)? 1 : 0;

// FSM-controlled send_counter incrementing data path
always @(posedge clk) begin
  if (reset)
    send_counter <= 0;
  else if (Q == S_INCR) begin
    // If (tx_byte == 8'h0), it means we hit the end of a string.
    send_counter <= (tx_byte == 8'h0)? string_id : send_counter + 1;
    print_done <= (tx_byte == 8'h0);
  end
  else // 'print_done' and 'print_enable' are mutually exclusive!
    print_done <= ~print_enable;
end
//
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
//
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end

always @(posedge clk)begin
  if(reset) cnt <= 0;
  else if(enter_pressed) cnt <= 0;
  else if(received && rx_byte>8'h2F && rx_byte<8'h3A)cnt <=(cnt == 5)?5: cnt +1 ;
  else cnt <= cnt;
end

always @(posedge clk)begin
  if(reset) num_reg <= 0;
  else if(send_counter == 59) num_reg <= 0;
  else if(received && rx_byte>8'h2F && rx_byte<8'h3A && cnt<5)begin
	num_reg<= (num_reg * 10) + (rx_byte - 48 );
  end
end

endmodule
