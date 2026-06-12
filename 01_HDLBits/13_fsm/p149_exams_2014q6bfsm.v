// HDLBits Problem 149: FSM: arbitration
// Author: Debjit Das | JGEC ECE

module top_module (input clk, resetn, input [3:1] r, output [3:1] g);
    parameter A=0,B=1,C=2,D=3; reg [1:0] s,ns;
    always @(posedge clk) s <= !resetn ? 2'd0 : ns;
    always @(*) case(s)
        A: ns = r[1]?B:r[2]?C:r[3]?D:A;
        B: ns = r[1]?B:A;
        C: ns = r[2]?C:A;
        D: ns = r[3]?D:A;
        default: ns = A;
    endcase
    assign g = {(s==D),(s==C),(s==B)};
endmodule
