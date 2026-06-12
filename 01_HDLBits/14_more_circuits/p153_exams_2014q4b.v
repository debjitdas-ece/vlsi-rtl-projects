// HDLBits Problem 153: FSM detect 1101
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, data, output start_shifting);
    parameter A=0,B=1,C=2,D=3,E=4; reg [2:0] s,ns;
    always @(posedge clk) s <= reset ? A : ns;
    always @(*) case(s)
        A: ns=data?B:A; B: ns=data?C:A;
        C: ns=data?C:D; D: ns=data?E:A;
        E: ns=E; default: ns=A;
    endcase
    assign start_shifting = (s==E);
endmodule
