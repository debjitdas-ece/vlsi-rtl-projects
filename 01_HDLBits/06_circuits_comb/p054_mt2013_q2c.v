// HDLBits Problem 54: Simple circuit B
// Author: Debjit Das | JGEC ECE

module top_module (input x, input y, output z);
    assign z = ~(x^y);
endmodule
