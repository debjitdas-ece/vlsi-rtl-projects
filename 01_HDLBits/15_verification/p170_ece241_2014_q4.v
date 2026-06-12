// HDLBits Problem 170: Latch + DFF
// Author: Debjit Das | JGEC ECE

module top_module (input clock, a, output p, q);
    always @(*) if (clock) p = a;
    always @(negedge clock) q <= p;
endmodule
