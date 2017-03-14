`timescale 1ns / 1ps

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
	localparam [1:0] S_INIT = 2'd0, S_IDLE = 2'd1, S_BUFFER = 2'd2, S_UPDATE = 2'd3;  
	reg 	[1:0] st, nst ; 
	
	// declare scroll direction 
	localparam scroll_up = 1'b0, scroll_down = 1'b1 ;
	localparam point_seven = 3500_0000 ;
	reg scroll_dir ; 
	reg [35:0] cnt ; 
	wire time_out ;
	reg  pre_scroll_dir ; 
	wire dir_change ;
	
	// declare FIB  
	localparam MAX_FIB_IN = 25;
	reg [15:0] Fib_1,Fib_2 ;
	
	// declare buffer 
	reg [15:0] buffer;
	wire [4:0]	next_sd_counter ;
	
	// declare a SRAM memory block
	wire [15:0] data_in;
	wire [15:0] data_out;
	wire        we, en;
	wire [4:0]  sram_addr;
	reg  [4:0]  sd_counter;
		
		
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
	
	assign next_sd_counter = (sd_counter == MAX_FIB_IN) ? 1 : sd_counter + 1 ;
	
	assign sram_addr = (st == S_IDLE && time_out) ? next_sd_counter : sd_counter;
	assign we = (st == S_INIT);     
	assign en = 1;             
	assign data_in = Fib_2;  

	
	always @(posedge clk) begin 
		if (reset)								sd_counter <= 1;
		else if(st == S_INIT)			sd_counter <= (sd_counter == MAX_FIB_IN) ? 1 : sd_counter + 1;
		else if(st == S_IDLE && cnt == 1)	begin 
			if(sd_counter == 1)				sd_counter <= (scroll_dir == scroll_down) ? 25 : 2 ; 
			else if(sd_counter == 25)	sd_counter <= (scroll_dir == scroll_down) ? 24 : 1 ; 			
			else 											sd_counter <= (scroll_dir == scroll_down) ? sd_counter - 1 : sd_counter + 1 ;			
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
			S_IDLE : nst = (time_out) ? S_BUFFER : S_IDLE ; 
			S_BUFFER : nst = S_UPDATE ; 
			S_UPDATE : nst =S_IDLE ; 
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

	always @(posedge clk) begin
		if (reset)	buffer <= 0 ;
		else if(st == S_BUFFER) buffer <= data_out ;
			
	end   

	
	always @(posedge clk) begin
		if (reset) begin
			row_A <= "Fibo #01 is 0000"; 
			row_B <= "Fibo #02 is 0001";
		end
		else if (st == S_UPDATE) begin
			
				row_A[127:120] <= "F";
				row_A[119:112] <= "i";
				row_A[111:104] <= "b";
				row_A[103:96 ] <= "o";
				row_A[95 :88 ] <= " ";
				row_A[87 :80 ] <= "#";
				row_A[79 :72 ] <= {3'd0,sd_counter[4]} + "0";
				row_A[71 :64 ] <= (sd_counter[3:0] >=10) ? {4'd0,sd_counter[3:0]}-10 + "A" : {4'd0,sd_counter[3:0]} + "0" ;
				row_A[63 :56 ] <= " ";
				row_A[55 :48 ] <= "i";
				row_A[47 :40 ] <= "s";
				row_A[39 :32 ] <= " ";

				row_A[31 :24 ] <= (data_out[15:12] >=10) ? {4'd0,data_out[15:12]}-10 + "A" : {4'd0,data_out[15:12]} + "0" ;
				row_A[23 :16 ] <= (data_out[11:8 ] >=10) ? {4'd0,data_out[11:8 ]}-10 + "A" : {4'd0,data_out[11:8 ]} + "0" ;
				row_A[15 :8  ] <= (data_out[7 :4 ] >=10) ? {4'd0,data_out[7 :4 ]}-10 + "A" : {4'd0,data_out[7 :4 ]} + "0" ;
				row_A[7  :0  ] <= (data_out[3 :0 ] >=10) ? {4'd0,data_out[3 :0 ]}-10 + "A" : {4'd0,data_out[3 :0 ]} + "0" ;


				row_B[127:120] <= "F";
				row_B[119:112] <= "i";
				row_B[111:104] <= "b";
				row_B[103:96 ] <= "o";
				row_B[95 :88 ] <= " ";
				row_B[87 :80 ] <= "#";
				row_B[79 :72 ] <= {3'd0,next_sd_counter[4]} + "0";
				row_B[71 :64 ] <= (next_sd_counter[3:0] >=10) ? {4'd0,next_sd_counter[3:0]}-10 + "A" : {4'd0,next_sd_counter[3:0]} + "0" ;
				row_B[63 :56 ] <= " ";
				row_B[55 :48 ] <= "i";
				row_B[47 :40 ] <= "s";
				row_B[39 :32 ] <= " ";
				row_B[31 :24 ] <= (buffer[15:12] >=10) ? {4'd0,buffer[15:12]}-10 + "A" : {4'd0,buffer[15:12]} + "0" ;
				row_B[23 :16 ] <= (buffer[11:8 ] >=10) ? {4'd0,buffer[11:8 ]}-10 + "A" : {4'd0,buffer[11:8 ]} + "0" ;
				row_B[15 :8  ] <= (buffer[7 :4 ] >=10) ? {4'd0,buffer[7 :4 ]}-10 + "A" : {4'd0,buffer[7 :4 ]} + "0" ;
				row_B[7  :0  ] <= (buffer[3 :0 ] >=10) ? {4'd0,buffer[3 :0 ]}-10 + "A" : {4'd0,buffer[3 :0 ]} + "0" ;
		end
	end
	






endmodule
