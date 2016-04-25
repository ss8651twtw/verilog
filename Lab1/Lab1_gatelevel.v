module Lab1_gatelevel(F, A, B, C, D);
	output F;
	input A, B, C, D;
	wire w1, w2, w3, w4;
	
	and G1(w1, A, !B);
	and G2(w2, !A, C);
	or G3(w3, w1, w2);
	or G4(w4, B, !D);
	and G5(F, w3, w4);
endmodule