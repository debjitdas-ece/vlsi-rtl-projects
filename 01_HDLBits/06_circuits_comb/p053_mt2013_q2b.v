// HDLBits Problem 53: Simple circuit A
// Author: Debjit Das | JGEC ECE

module top_module (input x, input y, output z);
    assign z = (x^y) & x;
endmodule
