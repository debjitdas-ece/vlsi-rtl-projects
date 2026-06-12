// HDLBits Problem 143: FSM: 5 states one-hot next
// Author: Debjit Das | JGEC ECE

module top_module (input [2:0] y, x, output Y0, z);
    assign Y0 = (~y[2]&~y[1]&~y[0]&x)|(~y[2]&~y[1]&y[0]&~x)|
                (~y[2]&y[1]&~y[0]&x)|(~y[2]&y[1]&y[0]&~x)|
                (y[2]&~y[1]&~y[0]&~x);
    assign z = (y==3'b011)||(y==3'b100);
endmodule
