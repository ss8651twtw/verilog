module t_Lab2_BCD_adder_behavior;
    wire [3 : 0] Sum;
    wire Cout;
    reg [3 : 0] A, B;
    reg Cin;
    Lab2_BCD_adder_behavior M1(Sum, Cout, A, B, Cin);
    initial begin
        A = 4'b0100;
        B = 4'b0010;
        Cin = 1'b0;
        #100
        Cin = 1'b1;
        #100
        A = 4'b0101;
        B = 4'b0110;
        Cin = 1'b0;
        #100
        Cin = 1'b1;
        #100
        A = 4'b1001;
        B = 4'b0111;
        Cin = 1'b0;
        #100
        Cin = 1'b1;
        #100
        $finish;
    end
endmodule