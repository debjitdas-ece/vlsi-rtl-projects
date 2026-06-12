// HDLBits Problem 67: Full adder
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, cin, output cout, sum);
    assign {cout, sum} = a + b + cin;
endmodule
