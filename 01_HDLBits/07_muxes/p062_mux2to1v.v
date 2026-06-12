// HDLBits Problem 62: 2-to-1 bus mux
// Author: Debjit Das | JGEC ECE

module top_module (input [99:0] a, b, input sel, output [99:0] out);
    assign out = sel ? b : a;
endmodule
