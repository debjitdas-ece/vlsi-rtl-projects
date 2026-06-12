// HDLBits Problem 152: Shift+count FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, shift_ena, count_ena, data, output [3:0] q);
    reg [3:0] r;
    always @(posedge clk)
        r <= shift_ena ? {r[2:0],data} : count_ena ? r-1'b1 : r;
    assign q = r;
endmodule
