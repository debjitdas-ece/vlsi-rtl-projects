// HDLBits Problem 140: FSM: 2 states
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, x, output reg z);
    parameter A=0,B=1; reg s,ns;
    always @(*) case(s)
        A: {ns,z} = x ? {B,1'b1} : {A,1'b0};
        B: {ns,z} = x ? {B,1'b0} : {B,1'b1};
        default: {ns,z} = {A,1'b0};
    endcase
    always @(posedge clk or posedge areset)
        if (areset) s<=A; else s<=ns;
endmodule
