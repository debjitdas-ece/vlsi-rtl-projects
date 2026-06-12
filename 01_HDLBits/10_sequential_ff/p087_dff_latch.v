// HDLBits Problem 87: D latch
// Author: Debjit Das | JGEC ECE

module top_module (input d, ena, output reg q);
    always @(*) if (ena) q = d;
endmodule
