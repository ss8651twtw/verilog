module t_Lab2_half_sub;
    wire D, B;
    reg [1 : 0] I;
    Lab2_half_sub_gatelevel M1(D, B, I[1], I[0]);
    initial begin
        I = 2'b00;
        repeat(3) #100 I = I + 1'b1;
        #100;
    end
    Lab2_half_sub_dataflow M2(D, B, I[1], I[0]);
    initial #400 begin
        I = 2'b00;
        #100 I = I + 1'b1;
        #100 I = I + 1'b1;
        #100 I = I + 1'b1;
        #100;
    end
    Lab2_half_sub_behavior M3(D, B, I[1], I[0]);
    initial #800 begin
        I = 2'b00;
        #100 I = I + 1'b1;
        #100 I = I + 1'b1;
        #100 I = I + 1'b1;
        #100
        $finish;
    end
endmodule