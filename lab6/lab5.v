`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer: Ya-Chiu Wu
// 
// Create Date:    16:12:38 11/02/2016 
// Module Name:    lab5
// 
// Description:    Lab5 top module
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

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_IDLE = 1, S_MAIN_INCR = 2,
                 S_MAIN_READ = 3, S_MAIN_LOOP = 4, S_MAIN_FIND_MATRIX = 5,
                 S_MAIN_MSG2 = 6, S_MAIN_DONE = 7;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam MEM_SIZE = 128;
localparam MESSAGE_STR = 0;

// declare system variables
wire btn_level, btn_pressed;
wire tag_notfound;
reg  prev_btn_level;
reg  print_enable, print_done;
reg  [6:0] send_counter;
reg  [2:0] P, P_next;
reg  [1:0] Q, Q_next;
reg  [9:0] sd_counter;
reg  [31:0] byte4;
reg  [0:(MEM_SIZE-1)*8+7] data;
reg  [0:7*8+7] tag;
reg  [31:0] blk_addr;

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

assign clk_sel = (init_finish)? clk : clk_500k; // clocks for the SD controller
assign led = 8'h00;

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
    data[0   :13*8+7] <= "The matrix is:";
    data[14*8:15*8+7] <= { 8'h0D, 8'h0A };
    data[16*8:35*8+7] <= "[ 0000, 0000, 0000 ]";
    data[36*8:37*8+7] <= { 8'h0D, 8'h0A };
    data[38*8:57*8+7] <= "[ 0000, 0000, 0000 ]";
    data[58*8:59*8+7] <= { 8'h0D, 8'h0A };
    data[60*8:79*8+7] <= "[ 0000, 0000, 0000 ]";
    data[80*8:84*8+7] <= { 8'h0D, 8'h0A, 8'h0D, 8'h0A, 8'h00 };
    data[85*8:127*8+7] <= 0;
  end
  else begin
    // print matrix
    data[18*8:21*8+7] <= (sd_counter == 512 + 15)? byte4 : data[18*8:21*8+7];
    data[24*8:27*8+7] <= (sd_counter == 512 + 33)? byte4 : data[24*8:27*8+7];
    data[30*8:33*8+7] <= (sd_counter == 512 + 51)? byte4 : data[30*8:33*8+7];
    data[40*8:43*8+7] <= (sd_counter == 512 + 21)? byte4 : data[40*8:43*8+7];
    data[46*8:49*8+7] <= (sd_counter == 512 + 39)? byte4 : data[46*8:49*8+7];
    data[52*8:55*8+7] <= (sd_counter == 512 + 57)? byte4 : data[52*8:55*8+7];
    data[62*8:65*8+7] <= (sd_counter == 512 + 27)? byte4 : data[62*8:65*8+7];
    data[68*8:71*8+7] <= (sd_counter == 512 + 45)? byte4 : data[68*8:71*8+7];
    data[74*8:77*8+7] <= (sd_counter == 512 + 63)? byte4 : data[74*8:77*8+7];
  end
end

always @(posedge clk) begin
  if (reset)
    tag <= 0;
  else begin
    tag[0  :3*8+7] <= (sd_counter == 512 + 5)? byte4 : tag[0  :3*8+7];
    tag[4*8:7*8+7] <= (sd_counter == 512 + 9)? byte4 : tag[4*8:7*8+7];
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

// Set the driver of the SRAM address signal.
assign sram_addr = sd_counter[8:0];

always @(posedge clk) begin // Controller of the 'sd_counter' signal.
  if (reset || P == S_MAIN_READ)
    sd_counter <= 0;
  else if ((P == S_MAIN_LOOP && sd_valid) || (P == S_MAIN_FIND_MATRIX))
    sd_counter <= sd_counter + 1;
end

always @(posedge clk) begin // Shift sram[sram_addr] to the register 'byte4'.
  if (reset) byte4 <= 32'b0;
  else if (en && P == S_MAIN_FIND_MATRIX) byte4 <= { byte4[23:0], data_out };
end
//
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main circuit that reads a SD card sector (512 bytes)
// and then search the tag.
//
always @(posedge clk) begin
  if (reset) P <= S_MAIN_INIT;
  else P <= P_next;
end

assign tag_notfound = ((tag != "DLAB_TAG") && (sd_counter == 512 + 10));

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
      if (sd_counter == 512) P_next = S_MAIN_FIND_MATRIX;
      else P_next = S_MAIN_LOOP;
    S_MAIN_FIND_MATRIX:
      if (sd_counter == 512 + 63) P_next = S_MAIN_MSG2;
      else if (tag_notfound) P_next = S_MAIN_INCR;
      else P_next = S_MAIN_FIND_MATRIX;
    S_MAIN_INCR:
      P_next = S_MAIN_READ;
    S_MAIN_MSG2:
      P_next = S_MAIN_DONE;
    S_MAIN_DONE:
      if (print_done) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_DONE;
  endcase
end

// FSM output logics: print string control signals.
always @(*) begin
  if (P == S_MAIN_MSG2)
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
  if (reset || P == S_MAIN_IDLE) blk_addr <= 32'h2000;
  else blk_addr <= blk_addr + (P == S_MAIN_INCR);
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
    else
      send_counter <= send_counter + (Q == S_UART_SEND && Q_next == S_UART_INCR);
    print_done <= (print_enable)? 0 : (tx_byte == 8'h0);
  end
end
//
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

endmodule
