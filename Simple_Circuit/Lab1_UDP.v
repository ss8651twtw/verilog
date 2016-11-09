primitive Lab1_UDP(F, A, B, C);
	output F;
	input A, B, C;
	
	table
		0 0 0 : 0;
		0 0 1 : 1;
		0 1 0 : 0;
		0 1 1 : 1;
		1 0 0 : 1;
		1 0 1 : 1;
		1 1 0 : 0;
		1 1 1 : 0;
	endtable
endprimitive
		