// HDLBits Problem 103: Counter 1-12
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, enable,
    output [3:0] Q, output c_enable, c_load, output [3:0] c_d);
    assign {c_enable, c_load, c_d} = {enable, (reset || (enable && Q==4'd12)), 4'd1};
    count4 the_counter (clk, c_enable, c_load, c_d, Q);
endmodule
