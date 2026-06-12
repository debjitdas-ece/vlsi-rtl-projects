// HDLBits Problem 92: Mux and DFF 2
// Author: Debjit Das | JGEC ECE

module top_module (input clk, w, R, E, L, output reg Q);
    always @(posedge clk) Q <= L ? R : (E ? w : Q);
endmodule
