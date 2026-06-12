// HDLBits Problem 70: Signed addition overflow
// Author: Debjit Das | JGEC ECE

module top_module (input [7:0] a, b, output [7:0] s, output overflow);
    assign s        = a + b;
    assign overflow = (a[7] == b[7]) && (s[7] != a[7]);
endmodule
