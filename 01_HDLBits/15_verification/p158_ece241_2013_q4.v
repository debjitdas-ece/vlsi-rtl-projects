// HDLBits Problem 158: Mux select
// Author: Debjit Das | JGEC ECE

module top_module (input sel, input [7:0] a, b, output [7:0] out);
    assign out = sel ? a : b;
endmodule
