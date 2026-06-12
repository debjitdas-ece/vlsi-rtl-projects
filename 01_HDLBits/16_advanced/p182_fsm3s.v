// HDLBits Problem 182: FSM3 synchronous reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, in, output out);
    parameter A=0,B=1,C=2,D=3; reg [1:0] state,next;
    always @(*) case(state)
        A: next = in ? B : A; B: next = in ? B : C;
        C: next = in ? D : A; D: next = in ? B : C;
        default: next = A;
    endcase
    always @(posedge clk) if (reset) state<=A; else state<=next;
    assign out = (state==D);
endmodule
