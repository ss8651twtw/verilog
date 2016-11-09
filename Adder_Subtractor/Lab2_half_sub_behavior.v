module Lab2_half_sub_behavior(output reg D, B, input x, y);
    always @(*)begin
        D = x ^ y;
        B = ~x & y;
    end
endmodule