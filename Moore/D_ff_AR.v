module D_ff_AR(output reg Q, input D, clock, reset);
	always @(posedge clock, negedge reset)
		if(~reset)Q <= 1'b0;
		else Q <= D;
endmodule