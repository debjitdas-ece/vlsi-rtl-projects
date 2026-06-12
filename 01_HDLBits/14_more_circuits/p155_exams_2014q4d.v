// HDLBits Problem 155: FSM: shift and count
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, data, shift_ena, counting,
    input done_counting, output done, input ack);
    localparam S=0,S1=1,S11=2,S110=3,B0=4,B1=5,B2=6,B3=7,COUNT=8,WAIT=9;
    reg [3:0] s,ns;
    always @(posedge clk) s <= reset ? S : ns;
    always @(*) case(s)
        S:    ns=data?S1:S;  S1: ns=data?S11:S;
        S11:  ns=data?S11:S110; S110: ns=data?B0:S;
        B0:ns=B1; B1:ns=B2; B2:ns=B3; B3:ns=COUNT;
        COUNT:ns=done_counting?WAIT:COUNT;
        WAIT: ns=ack?S:WAIT; default:ns=S;
    endcase
    assign shift_ena=(s==B0)|(s==B1)|(s==B2)|(s==B3);
    assign counting=(s==COUNT); assign done=(s==WAIT);
endmodule
