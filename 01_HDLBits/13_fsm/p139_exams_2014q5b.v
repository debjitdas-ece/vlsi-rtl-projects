// HDLBits Problem 139: Mealy FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, x, output z);
    parameter a=0,b=1,c=2; reg [1:0] s,ns;
    always @(*) case(s)
        a: ns = x ? b : a;
        b: ns = x ? c : b;
        c: ns = x ? c : b;
        default: ns = a;
    endcase
    always @(posedge clk or posedge areset)
        if (areset) s<=a; else s<=ns;
    assign z = (s==b);
endmodule
