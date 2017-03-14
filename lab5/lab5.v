`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date:    15:45:54 10/04/2016 
// Design Name: 
// Module Name:    lab5 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This is a sample top module of lab 5: sd card reader.
//              The behavior of this module is as follows:
//              1. The moudle will read one block (512 bytes) of the SD card
//                 into an on-chip SRAM every time the user hit the WEST button.
//              2. The starting address of the disk block is #8192 (i.e., 0x2000).
//              3. A message will be printed on the UART about the block id and the
//                 first byte of the block.
//              4. After printing the message, the block address will be incremented
//                 by one, waiting for the next user button press.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lab5(
    // General system I/O ports
    input  clk,
    input  reset,
    input  button,
    input  rx,
    output tx,
    output [7:0] led,

    // SD card specific I/O ports
    output cs,
    output sclk,
    output mosi,
    input  miso
    );

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_IDLE = 1,
                 S_MAIN_READ = 3, S_MAIN_LOOP = 4, S_TAG_FAIL = 5,
                 S_TAG_SUCCESS = 6, S_MAIN_DONE = 7, S_UART_ENABLE = 2;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam MEM_SIZE = 128;
localparam MESSAGE_STR = 0;
localparam NUMBER_STR = 0;

// declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  print_enable, print_done;
reg  [8:0] send_counter;
reg  [2:0] P, P_next;
reg  [1:0] Q, Q_next;
reg  [9:0] sd_counter;
reg  [0:(MEM_SIZE-1)*8+7] data;
reg  [31:0] blk_addr;
reg  [7:0]ans_matrix[15:0];
reg  [5:0]row_cnt,col_cnt,ans_cnt;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

// declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finish;
wire [7:0] sd_dout;
wire sd_valid;

// declare a SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire       we, en;
wire [8:0] sram_addr;

wire [7:0]tag_word[0:7];
reg compare_flag;
reg [7:0]matrix[31:0];
wire [7:0]matrix_data;
reg [5:0]matrix_cnt;
reg [15:0]result[3:0];
reg [17:0]matrix_ans[15:0];
wire [5:0]result_cnt;
wire [17:0]result_reg;
wire [31:0]ans;

integer i;

assign tag_word[0] = "M";
assign tag_word[1] = "A";
assign tag_word[2] = "T";
assign tag_word[3] = "X";
assign tag_word[4] = "_";
assign tag_word[5] = "T";
assign tag_word[6] = "A";
assign tag_word[7] = "G";

assign clk_sel = (init_finish)? clk : clk_500k; // clocks for the SD controller
assign led = {P,blk_addr[15:11]};

debounce btn_db0(
  .clk(clk),
  .btn_input(button),
  .btn_output(btn_level));

uart uart0(
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
  .recv_error(recv_error));

sd_card sd_card0(
  .cs(cs),
  .sclk(sclk),
  .mosi(mosi),
  .miso(miso),

  .clk(clk_sel),
  .rst(reset),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finish(init_finish),
  .dout(sd_dout),
  .sd_valid(sd_valid));

clk_divider#(100) clk_divider0(
  .clk(clk),
  .rst(reset),
  .clk_out(clk_500k));

// Text messages configuration circuit.
always @(posedge clk) begin
  if (reset) begin
    data[0   :13*8+7] <= "The result is:";
    data[14*8:15*8+7] <= { 8'h0D, 8'h0A };
    data[16*8:40*8+7] <= "[ 0000, 0000, 0000, 0000]";
    data[41*8:42*8+7] <= { 8'h0D, 8'h0A };
    data[43*8:67*8+7] <= "[ 0000, 0000, 0000, 0000]";
    data[68*8:69*8+7] <= { 8'h0D, 8'h0A };
    data[70*8:94*8+7] <= "[ 0000, 0000, 0000, 0000]";
	data[95*8:96*8+7] <= { 8'h0D, 8'h0A };
    data[97*8:121*8+7] <= "[ 0000, 0000, 0000, 0000]";
    data[122*8:126*8+7] <= { 8'h0D, 8'h0A, 8'h0D, 8'h0A, 8'h00 };
    data[127*8:127*8+7] <= 0;
  end
  else begin
    // print matrix
    data[18*8:21*8+7]   <= (result_cnt == 0)? ans : data[18*8:21*8+7]   ;
    data[24*8:27*8+7]   <= (result_cnt == 1)? ans : data[24*8:27*8+7]   ;
    data[30*8:33*8+7]   <= (result_cnt == 2)? ans : data[30*8:33*8+7]   ;
    data[36*8:39*8+7]   <= (result_cnt == 3)? ans : data[36*8:39*8+7]   ;
	                                                                    
    data[45*8:48*8+7]   <= (result_cnt == 4)? ans : data[45*8:48*8+7]   ;
    data[51*8:54*8+7]   <= (result_cnt == 5)? ans : data[51*8:54*8+7]   ;
    data[57*8:60*8+7]   <= (result_cnt == 6)? ans : data[57*8:60*8+7]   ;
    data[63*8:66*8+7]   <= (result_cnt == 7)? ans : data[63*8:66*8+7]   ;
	                                                                    
    data[72*8:75*8+7]   <= (result_cnt == 8 )? ans :data[72*8:75*8+7]   ;
	data[78*8:81*8+7]   <= (result_cnt == 9 )? ans :data[78*8:81*8+7]   ;
    data[84*8:87*8+7]   <= (result_cnt == 10)? ans :data[84*8:87*8+7]   ;
    data[90*8:93*8+7]   <= (result_cnt == 11)? ans :data[90*8:93*8+7]   ;
	                                                                    
    data[99 *8:102*8+7] <= (result_cnt == 12)? ans :data[99 *8:102*8+7] ;
    data[105*8:108*8+7] <= (result_cnt == 13)? ans :data[105*8:108*8+7] ;
    data[111*8:114*8+7] <= (result_cnt == 14)? ans :data[111*8:114*8+7] ;
    data[117*8:120*8+7] <= (result_cnt == 15)? ans :data[117*8:120*8+7] ;
  end
end
// Enable one cycle of btn_pressed per each button hit.
assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
always @(posedge clk) begin
  if (reset)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end
// ------------------------------------------------------------------------
// The following code describes an SRAM memory block that is connected
// to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
sram ram0(.clk(clk), .we(we), .en(en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
assign we = sd_valid;     // Write data into SRAM when sd_valid is high.
assign en = 1;             // Always enable the SRAM block.
assign data_in = sd_dout;  // Input data always comes from the SD controller.
assign matrix_data = (data_out>="0"&&data_out<="9")?data_out-48:(data_out>="A"&&data_out<="F")?data_out-55:0;
// Set the driver of the SRAM address signal.
assign sram_addr = sd_counter[8:0];

always @(posedge clk) begin // Controller of the 'sd_counter' signal.
  if (reset || P == S_MAIN_READ)
    sd_counter <= 0;
  else if (P == S_MAIN_LOOP && sd_valid)
    sd_counter <= sd_counter + 1;
end
//
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main circuit that reads a SD card sector (512 bytes)
// and then print its byte.
//
always @(posedge clk) begin
  if (reset) P <= S_MAIN_INIT;
  else P <= P_next;
end
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finish) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_READ;
      else P_next = S_MAIN_IDLE;
    S_MAIN_READ: // issue a read request to the SD controller
      P_next = S_MAIN_LOOP;
    S_MAIN_LOOP: // wait for the input data to enter the SRAM buffer
	  if (sd_counter == 512 && !compare_flag) P_next = S_TAG_FAIL;
      else if (sd_counter == 512) P_next = S_TAG_SUCCESS;
      else P_next = S_MAIN_LOOP;
    S_TAG_FAIL:
      P_next = S_MAIN_READ;
    S_TAG_SUCCESS: 
	  if(ans_cnt == 16) P_next = S_UART_ENABLE;
	  else P_next = S_TAG_SUCCESS;
	S_UART_ENABLE:
	  P_next = S_MAIN_DONE;
    S_MAIN_DONE:
      if (print_done) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_DONE;
  endcase
end

always @(posedge clk)begin
  if(reset || P == S_MAIN_READ)begin
    for(i=0; i<31; i=i+1)
	  matrix[i] <= 0;
  end
  else if(P == S_MAIN_LOOP && sd_counter > 9 && sd_counter <136 && data_out != 8'h0D && data_out != 8'h0A && sd_valid)
    matrix[matrix_cnt] <= (matrix[matrix_cnt] << 4) + matrix_data;
end

always @(posedge clk)begin
  if(reset)
    matrix_cnt <= 0;
  else if(P == S_MAIN_READ)
    matrix_cnt <= 0;
  else if(P == S_MAIN_LOOP && sd_counter > 9 && sd_counter <136 && sd_valid)
    matrix_cnt <= (sd_counter[1:0] == 2'b00)? matrix_cnt + 1 : matrix_cnt;    
end

always @(posedge clk)begin
  if(reset)begin
    for(i=0; i<4; i=i+1)
	  result[i] <= 0;
  end
  else if(P == S_TAG_SUCCESS) begin
    result[0] <= matrix[row_cnt + 0 ] * matrix[col_cnt + 0] ;
	result[1] <= matrix[row_cnt + 4 ] * matrix[col_cnt + 1] ;
	result[2] <= matrix[row_cnt + 8 ] * matrix[col_cnt + 2] ;
	result[3] <= matrix[row_cnt + 12] * matrix[col_cnt + 3] ;
  end    
end

assign result_cnt = (ans_cnt == 0) ? 0 : ans_cnt - 1;
assign result_reg = result[0] + result[1] + result[2] + result[3];
DecToHex D1(.A(result_reg[15:0]), .B(ans));

always @(posedge clk)begin
  if(reset)begin
    row_cnt <= 0; 
	col_cnt <= 16;
  end
  else if(P == S_TAG_SUCCESS && ans_cnt[1:0] == 2'b11)begin
    row_cnt <= row_cnt + 1;
	col_cnt <= 16;
  end
  else if(P == S_TAG_SUCCESS )    
	col_cnt <= col_cnt + 4;
  else if(P == S_MAIN_IDLE)begin
    row_cnt <= 0;
	col_cnt <= 16;
  end    
end

always @(posedge clk)begin
  if(reset)
    ans_cnt <= 0;
  else if(P == S_TAG_SUCCESS)
    ans_cnt <= ans_cnt + 1 ;
  else if(P == S_MAIN_IDLE)
    ans_cnt <= 0;
end

always @(posedge clk)begin
  if(reset) 
    compare_flag <= 1;
  else if (P == S_TAG_FAIL) 
    compare_flag <= 1;
  else if(P == S_MAIN_LOOP && sd_counter < 8 && sd_valid)
    compare_flag <= (data_out == tag_word[sd_counter]) ? compare_flag : 0;
end
// FSM output logics: print string control signals.
always @(*) begin
  if (P == S_UART_ENABLE)
    print_enable = 1;
  else
    print_enable = 0;
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_READ);
  rd_addr = blk_addr;
end

// SD card read address incrementer
always @(posedge clk) begin
  if (reset) blk_addr <= 32'h2000;
  else blk_addr <= (blk_addr == 7736319)? 32'h2000:blk_addr + (P == S_TAG_FAIL || P == S_TAG_SUCCESS);
end
//
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller to send a string to the UART.
//
always @(posedge clk) begin
  if (reset) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics
assign transmit = (Q == S_UART_WAIT)? 1 : 0;
assign tx_byte = data[{ send_counter, 3'b000 } +: 8];

// Send_counter incrementing circuit.
always @(posedge clk) begin
  if (reset) begin
    send_counter <= MESSAGE_STR;
    print_done <= 0;
  end
  else begin
    if (P == S_MAIN_IDLE)
      send_counter <= MESSAGE_STR;
    else if (P == S_UART_ENABLE)
      send_counter <= MESSAGE_STR;
    else
      send_counter <= send_counter + (Q == S_UART_SEND && Q_next == S_UART_INCR);
      print_done <= (print_enable)? 0 : (tx_byte == 8'h0);
  end
end
//
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

endmodule

module DecToHex (A ,B);
input [15:0] A;
output [31:0]B;

Dec1ToHex1 D1 (.A(A[15:12]), .B(B[31:24]))  ;
Dec1ToHex1 D2 (.A(A[11:8]),  .B(B[23:16]))  ;
Dec1ToHex1 D3 (.A(A[7:4] ),  .B(B[15:8] ))  ;
Dec1ToHex1 D4 (.A(A[4:0]  ), .B(B[7:0]  ))  ;

endmodule

module Dec1ToHex1 (A,B);
  input [3:0]A;
  output [7:0]B;
  
  assign B = (A>=0 && A<10)?A+48:A+55;
  
endmodule