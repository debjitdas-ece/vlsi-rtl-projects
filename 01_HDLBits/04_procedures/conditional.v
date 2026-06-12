// HDLBits Problem 37: Conditional ternary operator
// Author: Debjit Das | JGEC ECE

module top_module (input [7:0] a, b, c, d, output [7:0] min);
    wire [7:0] m1, m2;
    assign m1  = (a < b) ? a : b;
    assign m2  = (c < d) ? c : d;
    assign min = (m1 < m2) ? m1 : m2;
endmodule
