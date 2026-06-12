// HDLBits Problem 146: FSM: 3-bit one-hot (Q1)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, w, output z);
    reg [2:0] s;
    function [2:0] lut; input [17:0] t; input [2:0] idx; lut=t[idx*3+:3]; endfunction
    always @(posedge clk)
        s <= reset ? 3'd0 : (w ? lut(18'b011_011_000_011_011_000,s)
                               : lut(18'b010_100_101_100_010_001,s));
    assign z = s[2] & ~s[1];
endmodule
