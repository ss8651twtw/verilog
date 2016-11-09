module Lab1_gate_level_UDP(F, A, B, C, D);
	output F;
	input A, B, C, D;
	wire w1, w2;
	
	Lab1_UDP M0(w1, A, B, C);
	or G1(w2, B, !D);
	and G2(F, w1, w2);
endmodule