// HDLBits Problem 114: Shift register with mux
// Author: Debjit Das | JGEC ECE

module top_module (input [3:0] SW, input [3:0] KEY, output [3:0] LEDR);
    MUXDFF inst3(.clk(KEY[0]),.E(KEY[1]),.L(KEY[2]),.R(SW[3]),.w(KEY[3]),   .Q(LEDR[3]));
    MUXDFF inst2(.clk(KEY[0]),.E(KEY[1]),.L(KEY[2]),.R(SW[2]),.w(LEDR[3]),  .Q(LEDR[2]));
    MUXDFF inst1(.clk(KEY[0]),.E(KEY[1]),.L(KEY[2]),.R(SW[1]),.w(LEDR[2]),  .Q(LEDR[1]));
    MUXDFF inst0(.clk(KEY[0]),.E(KEY[1]),.L(KEY[2]),.R(SW[0]),.w(LEDR[1]),  .Q(LEDR[0]));
endmodule
module MUXDFF (input clk, w, E, R, L, output reg Q);
    always @(posedge clk) Q <= L ? R : (E ? w : Q);
endmodule
