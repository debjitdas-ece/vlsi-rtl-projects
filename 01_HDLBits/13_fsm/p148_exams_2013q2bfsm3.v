// HDLBits Problem 148: FSM: Y1 Y3
// Author: Debjit Das | JGEC ECE

module top_module (input [5:0] y, w, output Y1, Y3);
    assign Y1 = y[0] & w;
    assign Y3 = (y[1]|y[2]|y[4]|y[5]) & ~w;
endmodule
