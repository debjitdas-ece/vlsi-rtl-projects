// HDLBits Problem 157: One-hot FSM next state
// Author: Debjit Das | JGEC ECE

module top_module (input d, done_counting, ack, input [9:0] state,
    output B3_next, S_next, S1_next, Count_next, Wait_next,
    output done, counting, shift_ena);
    assign S_next    =(state[0]&~d)|(state[1]&~d)|(state[3]&~d)|(state[9]&ack);
    assign S1_next   = state[0]&d;
    assign B3_next   = state[6];
    assign Count_next= state[7]|(state[8]&~done_counting);
    assign Wait_next =(state[8]&done_counting)|(state[9]&~ack);
    assign shift_ena = state[4]|state[5]|state[6]|state[7];
    assign counting  = state[8];
    assign done      = state[9];
endmodule
