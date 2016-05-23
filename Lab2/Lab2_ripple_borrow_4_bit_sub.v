module Lab2_ripple_borrow_4_bit_sub(output [3 : 0] Diff, output Bout, input [3 : 0] X, Y, input Bin);
    wire w1, w2, w3;
    Lab2_full_sub M1(Diff[0], w1, X[0], Y[0], Bin), M2(Diff[1], w2, X[1], Y[1], w1), M3(Diff[2], w3, X[2], Y[2], w2), M4(Diff[3], Bout, X[3], Y[3], w3);
endmodule