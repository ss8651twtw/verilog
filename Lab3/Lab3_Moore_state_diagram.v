module Lab3_Moore_state_diagram(output y, input x, clock, reset);
	reg [1 : 0] state;
	parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
	always @(posedge clock, negedge reset)
		if(~reset)state <= S0;
		else case(state)
			S0: if(x)state <= S0; else state <= S1;
			S1: if(x)state <= S2; else state <= S1;
			S2: if(x)state <= S3; else state <= S1;
			S3: if(x)state <= S0; else state <= S1;
		endcase
		assign y = (state == S3);
endmodule