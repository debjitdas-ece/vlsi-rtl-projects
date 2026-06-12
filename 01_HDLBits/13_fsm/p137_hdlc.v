// HDLBits Problem 137: Sequence 1101011 detector (HDLC)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, in,
    output disc, flag, err);
    reg [9:0] state, ns;
    assign ns[0] = ~in & (|{state[4:0],state[9:7]});
    assign ns[1] = in  & (state[0]|state[8]|state[9]);
    assign ns[2] = in  & state[1]; assign ns[3]=in&state[2];
    assign ns[4] = in  & state[3]; assign ns[5]=in&state[4];
    assign ns[6] = in  & state[5]; assign ns[7]=in&(state[6]|state[7]);
    assign ns[8] = ~in & state[5]; assign ns[9]=~in&state[6];
    assign disc=(state[8]); assign flag=(state[9]); assign err=(state[7]);
    always @(posedge clk)
        if (reset) state=10'b1; else state<=ns;
endmodule
