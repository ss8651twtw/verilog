module DecodeMorse(
	input clk,
	input enable,
	input [79:0] in_bits,
	output reg [34:0] out_text,
	output valid);
	
	
	reg [79:0] in_data ;
	wire shift_4, finish_n ; 
	reg [2:0] remaining ; 
	reg [4:0] st, nst  ; 
	
	parameter A = 5'd0 ,	B = 5'd1 ,	C = 5'd2 ,	D = 5'd3 ,	E = 5'd4 ,	F = 5'd5 ,	G = 5'd6 ,	H = 5'd7 ,
						I = 5'd8 ,	J = 5'd9 ,	K = 5'd10,	L = 5'd11,	M = 5'd12,	N = 5'd13,	O = 5'd14,	P = 5'd15,
						Q = 5'd16,	R = 5'd17,	S = 5'd18,	T = 5'd19,	U = 5'd20,	V = 5'd21,	W = 5'd22,	X = 5'd23,
						Y = 5'd24,	Z = 5'd25, 
						idle = 5'd26 ; 
	
	
	assign shift_4 = in_data[78] ; 
	assign finish_n = in_data[79] | in_data[78] ; 

	always @ (posedge clk)
	begin 
		if(!enable) in_data <= in_bits ; 
		else begin 
			if(shift_4)  in_data <= in_data << 4 ;
			else  in_data <= in_data << 2 ;
		end 
	end 
	
	always @ (posedge clk)
	begin 
		if(!enable) st <= idle ; 
		else st <= nst ;
	end 
	
	always @ (*)
	begin 
	case(st)
		idle:	nst = (remaining==0)? idle : (shift_4) ? T : E;
			A : nst = (!finish_n) ? idle : (shift_4) ? W : R;
			B : nst = idle ;
			C : nst = idle ;
			D : nst = (!finish_n) ? idle : (shift_4) ? X : B;
			E : nst = (!finish_n) ? idle : (shift_4) ? A : I;
			F : nst = idle ;
			G : nst = (!finish_n) ? idle : (shift_4) ? Q : Z;
			H : nst = idle ;
			I : nst = (!finish_n) ? idle : (shift_4) ? U : S;
			J : nst = idle ;
			K : nst = (!finish_n) ? idle : (shift_4) ? Y : C;
			L : nst = idle ;
			M : nst = (!finish_n) ? idle : (shift_4) ? O : G;
			N : nst = (!finish_n) ? idle : (shift_4) ? K : D;
			O : nst = idle ;
			P : nst = idle ;
			Q : nst = idle;
			R : nst = (!finish_n) ? idle : L ;
			S : nst = (!finish_n) ? idle : (shift_4) ? V : H;
			T : nst = (!finish_n) ? idle : (shift_4) ? M : N;
			U : nst = (!finish_n) ? idle : F ; 
			V : nst = idle ;
			W : nst = (!finish_n) ? idle : (shift_4) ? J : P;
			X : nst = idle ; 
			Y : nst = idle ; 
			Z : nst = idle ; 
			default : nst = idle ; 
		endcase 
	end 
	
	always @ (posedge clk)
	begin 
		if(!finish_n && enable && (remaining !=0)) out_text <= {out_text[27:0], st+7'h41} ;
	end 	
	
	always @ (posedge clk)
	begin 
		if(!enable) remaining <= 3'd5 ; 
		else if(!finish_n) remaining <= (remaining==0) ? 0 : remaining - 1 ;
	end 
	
	assign valid = (remaining == 0) ;
	
endmodule
