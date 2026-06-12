// HDLBits Problem 123: FSM3 combinational
// Author: Debjit Das | JGEC ECE

module top_module (input in, input [1:0] state,
    output [1:0] next_state, output out);
    parameter A=0,B=1,C=2,D=3;
    assign out = (state==D);
    always @(*) case(state)
        A: next_state = in ? B : A;
        B: next_state = in ? B : C;
        C: next_state = in ? D : A;
        D: next_state = in ? B : C;
    endcase
endmodule
