module t_Lab3_Moore;
	wire y1, y2;
	reg x, clock, reset;
	Lab3_Moore_state_diagram M1(y1, x, clock, reset);
	Lab3_Moore_structural M2(y2, x, clock, reset);
	initial begin
		reset = 0;
		clock = 0;
		#5 reset = 1;
		forever #5 clock = ~clock;
	end
	initial begin
		#5 x = 1;
		#10 x = 0;
		#10 x = 0;
		#10 x = 1;
		#10 x = 0;
		#10 x = 1;
		#10 x = 1;
		#10 x = 0;
		#10 x = 1;
		#10 x = 1;
		#10 x = 1;
		#10 $finish;
	end
endmodule