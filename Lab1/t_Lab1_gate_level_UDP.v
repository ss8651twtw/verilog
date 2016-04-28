module t_Lab1_gate_level_UDP;
	wire F;
	reg A, B, C, D;
	
	Lab1_gate_level_UDP M1(F, A, B, C, D);
	
	initial begin
		A=1'b0;	B=1'b0;	C=1'b0;	D=1'b0;
		#100
		A=1'b0;	B=1'b0;	C=1'b0;	D=1'b1;
		#100
		A=1'b0;	B=1'b0;	C=1'b1;	D=1'b0;
		#100
		A=1'b0;	B=1'b0;	C=1'b1;	D=1'b1;
		#100
		A=1'b0;	B=1'b1;	C=1'b0;	D=1'b0;
		#100
		A=1'b0;	B=1'b1;	C=1'b0;	D=1'b1;
		#100
		A=1'b0;	B=1'b1;	C=1'b1;	D=1'b0;
		#100
		A=1'b0;	B=1'b1;	C=1'b1;	D=1'b1;
		#100
		A=1'b1;	B=1'b0;	C=1'b0;	D=1'b0;
		#100
		A=1'b1;	B=1'b0;	C=1'b0;	D=1'b1;
		#100
		A=1'b1;	B=1'b0;	C=1'b1;	D=1'b0;
		#100
		A=1'b1;	B=1'b0;	C=1'b1;	D=1'b1;
		#100
		A=1'b1;	B=1'b1;	C=1'b0;	D=1'b0;
		#100
		A=1'b1;	B=1'b1;	C=1'b0;	D=1'b1;
		#100
		A=1'b1;	B=1'b1;	C=1'b1;	D=1'b0;
		#100
		A=1'b1;	B=1'b1;	C=1'b1;	D=1'b1;
		#100
		$finish;
	end
endmodule