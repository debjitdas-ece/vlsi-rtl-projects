// HDLBits Problem 16: Vector concatenation operator
// Author: Debjit Das | JGEC ECE

module top_module (input [4:0] a, b, c, d, e, f, output [7:0] w, x, y, z);
    assign {w, x, y, z} = {a, b, c, d, e, f};
endmodule
