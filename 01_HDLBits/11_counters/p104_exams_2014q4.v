// HDLBits Problem 104: Counter 1000
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output OneHertz, output [2:0] c_enable);
    wire [3:0] q0, q1, q2;
    assign c_enable = {q1==4'd9 && q0==4'd9, q0==4'd9, 1'b1};
    bcdcount counter0 (clk, reset, c_enable[0], q0);
    bcdcount counter1 (clk, reset, c_enable[1], q1);
    bcdcount counter2 (clk, reset, c_enable[2], q2);
    assign OneHertz = c_enable[2] && q2==4'd9;
endmodule
