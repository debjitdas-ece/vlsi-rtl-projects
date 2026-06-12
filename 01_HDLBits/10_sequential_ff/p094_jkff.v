// HDLBits Problem 94: JK flip-flop
// Author: Debjit Das | JGEC ECE

module top_module (input clk, j, k, output reg Q);
    always @(posedge clk) Q <= (j & ~Q) | (~k & Q);
endmodule
