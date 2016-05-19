module Lab2_half_sub_gatelevel(output D, B, input x, y);
    xor G1(D, x, y);
    and G2(B, ~x, y);
endmodule