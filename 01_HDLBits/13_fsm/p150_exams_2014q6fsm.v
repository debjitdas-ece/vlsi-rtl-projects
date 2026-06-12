// HDLBits Problem 150: 9-state one-hot FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, resetn, x, y, output f, g);
    parameter A=9'b1,B=9'b10,C=9'b100,D=9'b1000,E=9'b10000,
              F=9'b100000,G=9'b1000000,H=9'b10000000,I=9'b100000000;
    reg [8:0] s,ns;
    always @(*) case(s)
        A: ns=B; B: ns=C;
        C: ns=x?D:C; D: ns=x?D:E; E: ns=x?F:C;
        F: ns=y?H:G; G: ns=y?H:I; H: ns=H; I: ns=I;
        default: ns=A;
    endcase
    always @(posedge clk) if (!resetn) s<=A; else s<=ns;
    assign f = s[1];
    assign g = s[5]|s[6]|s[7];
endmodule
