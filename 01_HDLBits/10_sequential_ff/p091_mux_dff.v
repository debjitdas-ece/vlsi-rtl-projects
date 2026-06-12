// HDLBits Problem 91: Mux and DFF
// Author: Debjit Das | JGEC ECE

module top_module (input clk, L, r_in, q_in, output reg Q);
    always @(posedge clk) Q <= L ? r_in : q_in;
endmodule
