// HDLBits Problem 38: Reduction operators
// Author: Debjit Das | JGEC ECE

module top_module (input [7:0] in, output parity);
    assign parity = ^in;
endmodule
