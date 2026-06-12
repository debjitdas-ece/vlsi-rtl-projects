// HDLBits Problem 13: Vector part select
// Author: Debjit Das | JGEC ECE

module top_module (input [31:0] vec, output [7:0] out3, out2, out1, out0);
    assign {out3, out2, out1, out0} = vec;
endmodule
