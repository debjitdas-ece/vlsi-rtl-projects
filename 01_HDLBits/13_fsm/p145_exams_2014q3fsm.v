// HDLBits Problem 145: FSM: Y2 Y4
// Author: Debjit Das | JGEC ECE

module top_module (input [6:1] y, w, output Y2, Y4);
    assign Y2 = y[1] & ~w;
    assign Y4 = (y[2]|y[3]|y[5]|y[6]) & w;
endmodule
