// HDLBits Problem 138: FSM with async reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, aresetn, x, output z);
    parameter a=0,b=1,c=2; reg [1:0] s,ns;
    always @(*) case(s)
        a: ns = x ? b : a;
        b: ns = x ? b : c;
        c: ns = x ? b : a;
        default: ns = a;
    endcase
    always @(posedge clk or negedge aresetn)
        if (!aresetn) s<=a; else s<=ns;
    assign z = (s==c) && (x==1'b1);
endmodule
