// HDLBits Problem 66: Half adder
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, output cout, sum);
    assign {cout, sum} = a + b;
endmodule
