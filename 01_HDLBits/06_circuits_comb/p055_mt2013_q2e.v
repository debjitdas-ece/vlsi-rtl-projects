// HDLBits Problem 55: Combine circuits A and B
// Author: Debjit Das | JGEC ECE

module top_module (input x, input y, output z);
    wire zA, zB;
    assign zA = (x^y) & x;
    assign zB = ~(x^y);
    assign z  = zA | zB;
endmodule
