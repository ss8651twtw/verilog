module t_Lab2_full_sub;
    wire D, B;
    reg [2 : 0] I;
    Lab2_full_sub M1(D, B, I[2], I[1], I[0]);
    initial begin
        I = 3'b000;
        repeat(7) #100 I = I + 1'b1;
        #100
        $finish;
    end
endmodule