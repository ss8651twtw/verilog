module Lab3_Moore_structural(output y, input x, clock, reset);
	wire A, B;
	assign y = A & B;
	D_ff_AR D1(A, x & (A ^ B), clock, reset), D2(B, ~x | (A & ~B), clock, reset);
endmodule