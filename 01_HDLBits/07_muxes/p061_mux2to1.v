// HDLBits Problem 61: 2-to-1 mux
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, sel, output out);
    assign out = sel ? b : a;
endmodule
