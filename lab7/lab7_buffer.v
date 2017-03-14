`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:30:47 11/22/2015 
// Design Name: 
// Module Name:    lcd 
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
module lab7(
    input clk,
    input reset,
    input  button,
    output LCD_E,
    output LCD_RS,
    output LCD_RW,
    output [3:0]LCD_D
    );

    wire btn_level, btn_pressed;
    reg prev_btn_level;
    reg [127:0] row_A, row_B;
    
	// main state machine 
	localparam [1:0] S_INIT = 2'd0, S_IDLE = 2'd1, S_SET_LCD = 2'd2, S_UPDATE_BUFFER = 2'd3;  
	reg 	[1:0] st, nst ; 
	
	// declare scroll direction 
	localparam scroll_up = 1'b0, scroll_down = 1'b1 ;
	localparam point_seven = 10 ;
	// localparam point_seven = 3500_0000 ;
	reg scroll_dir ; 
	reg [35:0] cnt ; 
	wire time_out ;
	reg  pre_scroll_dir ; 
	wire dir_change ;
	
	// declare FIB  
	localparam MAX_FIB_IN = 25;
	reg [15:0] Fib_1,Fib_2 ;
	
	// declare buffer 
	reg [15:0] buffer[0:3] ;
	reg [15:0] backup_top, backup_button  ;
	reg [4:0]	 LCD_cnt ;
	wire [4:0]	next_LCD_cnt ;
	
	// declare a SRAM memory block
	wire [15:0] data_in;
	wire [15:0] data_out;
	wire        we, en;
	wire [4:0]  sram_addr;
	reg  [4:0]  sd_counter;
	
	reg wait_data ; 
		
		
	sram #(.DATA_WIDTH(16), .ADDR_WIDTH(5), .RAM_SIZE(26))
				ram0(.clk(clk), .we(we), .en(en), .addr(sram_addr), .data_i(data_in), .data_o(data_out));
	
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
	
	assign sram_addr = sd_counter;
	assign we = (st == S_INIT);     
	assign en = 1;             
	assign data_in = Fib_2;  

	always @(posedge clk) begin 
		if (reset)begin 
			backup_top <= 46368; 
			buffer[0] <= 46368;
			buffer[1] <= 0;
			buffer[2] <= 1;
			buffer[3] <= 1;
			backup_button <= 1; 
		end 
		else if(st == S_UPDATE_BUFFER && wait_data)begin 
			if(scroll_dir == scroll_up) begin 
				backup_top <= buffer[0] ;
				buffer[0] <= buffer[1] ;
				buffer[1] <= buffer[2] ;
				buffer[2] <= buffer[3] ;
				buffer[3] <= data_out  ; 
			end 
			else begin // scroll_down
				buffer[0] <= data_out ;
				buffer[1] <= buffer[0] ;
				buffer[2] <= buffer[1] ;
				buffer[3] <= buffer[2] ; 
				backup_button <= buffer[3] ;
			end 
		end 
		else if(dir_change)begin 
			if(scroll_dir == scroll_up) begin 
				backup_top <= buffer[0] ;
				buffer[0] <= buffer[1] ;
				buffer[1] <= buffer[2] ;
				buffer[2] <= buffer[3] ;
				buffer[3] <= backup_button  ; 
			end 
			else begin // scroll_down
				buffer[0] <= backup_top ;
				buffer[1] <= buffer[0] ;
				buffer[2] <= buffer[1] ;
				buffer[3] <= buffer[2] ; 
				backup_button <= buffer[3] ;
			end 
		end 
	end

	always @(posedge clk) begin 
		if (reset)	wait_data <= 0 ; 
		else if(st == S_IDLE) wait_data <= 0 ;
		else if(st == S_UPDATE_BUFFER) wait_data <= ~wait_data ;
	end		
	
	always @(posedge clk) begin 
		if (reset)	LCD_cnt <= 1;
		else if(dir_change)begin 
			if(scroll_dir == scroll_down) LCD_cnt <= (LCD_cnt <= 2 ) ? 25 - 2 + LCD_cnt : LCD_cnt - 2  ; 
			else 	LCD_cnt <= (LCD_cnt >= 24 ) ? LCD_cnt - 23  : LCD_cnt + 1  ; 
		end 
		else if(st == S_SET_LCD)begin 
			if(scroll_dir == scroll_down) LCD_cnt <= (LCD_cnt == 1 ) ? 25 : LCD_cnt - 1  ; 
			else 	LCD_cnt <= (LCD_cnt == 25 ) ? 1 : LCD_cnt + 1  ; 
		end 
	end	
	
	always @(posedge clk) begin 
		if (reset)								sd_counter <= 1;
		else if(st == S_INIT)			sd_counter <= (sd_counter == MAX_FIB_IN) ? 0 : sd_counter + 1;
		else if(st == S_SET_LCD)	begin 
			if(LCD_cnt == 2)				sd_counter <= (scroll_dir == scroll_down) ? 25 : 5 ; 
			else if(LCD_cnt == 1)		sd_counter <= (scroll_dir == scroll_down) ? 24 : 4 ; 
			else if(LCD_cnt == 25)	sd_counter <= (scroll_dir == scroll_down) ? 23 : 3 ; 
			else if(LCD_cnt == 24)	sd_counter <= (scroll_dir == scroll_down) ? 22 : 2 ;			
			else if(LCD_cnt == 23)	sd_counter <= (scroll_dir == scroll_down) ? 22 : 1 ;			
			else 										sd_counter <= (scroll_dir == scroll_down) ? LCD_cnt - 2 : LCD_cnt + 3 ;			
		end  
	end
	
	always @(posedge clk) begin // Controller of the 'sd_counter' signal.
		if (reset)begin 
			Fib_1 <= 0 ;  
			Fib_2 <= 0 ;
		end
		else if (st == S_INIT)begin 
			if(sd_counter == 1) begin 
				Fib_1 <= 0 ; 
				Fib_2 <= 1 ;		
			end 
			else begin 
				Fib_1 <= Fib_2 ; 
				Fib_2 <= Fib_1 + Fib_2 ;
			end 
		end 
	end
	
	always @(posedge clk) begin
		if (reset)
			st <= S_INIT;
		else
			st <= nst ;
	end
	
	always @ (*)begin 
		case(st)
			S_INIT : nst = (sd_counter == MAX_FIB_IN) ? S_IDLE : S_INIT ; 
			S_IDLE : nst = (time_out) ? S_SET_LCD : S_IDLE ; 
			S_SET_LCD : nst = S_UPDATE_BUFFER ; 
			S_UPDATE_BUFFER : nst = (wait_data) ? S_IDLE : S_UPDATE_BUFFER; 
			default : nst = S_IDLE ; 
		endcase
	end 
	
	assign time_out = (cnt == 0) ; 
	
	always @(posedge clk) begin
		if (reset)
			cnt <= point_seven;
		else
			cnt <= (cnt == 0) ? point_seven : cnt-1;
	end    
		
	always @(posedge clk) begin
		if (reset)
			prev_btn_level <= 1;
		else
			prev_btn_level <= btn_level;
	end

	assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
	
	assign dir_change = scroll_dir ^ pre_scroll_dir ; 
	
	always @(posedge clk) begin
		if (reset)
			scroll_dir <= scroll_up;
		else if(btn_pressed) 
			scroll_dir <= ~scroll_dir;
	end	
	
	always @(posedge clk) begin
		if (reset)
			pre_scroll_dir <= scroll_up;
		else 
			pre_scroll_dir <= scroll_dir ;
	end


	assign next_LCD_cnt = (LCD_cnt == MAX_FIB_IN) ? 1 : LCD_cnt + 1 ;
	
	always @(posedge clk) begin
		if (reset) begin
			row_A <= "Fibo #01 is 0000"; 
			row_B <= "Fibo #02 is 0001";
		end
		else if (st == S_SET_LCD) begin
			if(scroll_dir == scroll_down)begin 
			
				row_A[127:120] <= "F";
				row_A[119:112] <= "i";
				row_A[111:104] <= "b";
				row_A[103:96 ] <= "o";
				row_A[95 :88 ] <= " ";
				row_A[87 :80 ] <= "#";
				row_A[79 :72 ] <= {3'd0,LCD_cnt[4]} + "0";
				row_A[71 :64 ] <= (LCD_cnt[3:0] >=10) ? {4'd0,LCD_cnt[3:0]}-10 + "A" : {4'd0,LCD_cnt[3:0]} + "0" ;
				row_A[63 :56 ] <= " ";
				row_A[55 :48 ] <= "i";
				row_A[47 :40 ] <= "s";
				row_A[39 :32 ] <= " ";
				row_A[31 :24 ] <= (buffer[1][15:12] >=10) ? {4'd0,buffer[1][15:12]}-10 + "A" : {4'd0,buffer[1][15:12]} + "0" ;
				row_A[23 :16 ] <= (buffer[1][11:8 ] >=10) ? {4'd0,buffer[1][11:8 ]}-10 + "A" : {4'd0,buffer[1][11:8 ]} + "0" ;
				row_A[15 :8  ] <= (buffer[1][7 :4 ] >=10) ? {4'd0,buffer[1][7 :4 ]}-10 + "A" : {4'd0,buffer[1][7 :4 ]} + "0" ;
				row_A[7  :0  ] <= (buffer[1][3 :0 ] >=10) ? {4'd0,buffer[1][3 :0 ]}-10 + "A" : {4'd0,buffer[1][3 :0 ]} + "0" ;
			
				row_B <= row_A;
			end 
			else begin 
				row_A <= row_B;
				
				row_B[127:120] <= "F";
				row_B[119:112] <= "i";
				row_B[111:104] <= "b";
				row_B[103:96 ] <= "o";
				row_B[95 :88 ] <= " ";
				row_B[87 :80 ] <= "#";
				row_B[79 :72 ] <= {3'd0,next_LCD_cnt[4]} + "0";
				row_B[71 :64 ] <= (next_LCD_cnt[3:0] >=10) ? {4'd0,next_LCD_cnt[3:0]}-10 + "A" : {4'd0,next_LCD_cnt[3:0]} + "0" ;
				row_B[63 :56 ] <= " ";
				row_B[55 :48 ] <= "i";
				row_B[47 :40 ] <= "s";
				row_B[39 :32 ] <= " ";
				row_B[31 :24 ] <= (buffer[2][15:12] >=10) ? {4'd0,buffer[2][15:12]}-10 + "A" : {4'd0,buffer[2][15:12]} + "0" ;
				row_B[23 :16 ] <= (buffer[2][11:8 ] >=10) ? {4'd0,buffer[2][11:8 ]}-10 + "A" : {4'd0,buffer[2][11:8 ]} + "0" ;
				row_B[15 :8  ] <= (buffer[2][7 :4 ] >=10) ? {4'd0,buffer[2][7 :4 ]}-10 + "A" : {4'd0,buffer[2][7 :4 ]} + "0" ;
				row_B[7  :0  ] <= (buffer[2][3 :0 ] >=10) ? {4'd0,buffer[2][3 :0 ]}-10 + "A" : {4'd0,buffer[2][3 :0 ]} + "0" ;
			end 
		end
	end
	






endmodule
