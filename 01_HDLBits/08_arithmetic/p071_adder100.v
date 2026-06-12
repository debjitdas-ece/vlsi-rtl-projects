// HDLBits Problem 71: 100-bit binary adder
// Author: Debjit Das | JGEC ECE

module top_module (input [99:0] a, b, input cin,
    output cout, output [99:0] sum);
    assign {cout, sum} = a + b + cin;
endmodule
