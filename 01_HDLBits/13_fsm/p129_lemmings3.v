// HDLBits Problem 129: Lemmings 3
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, bump_left, bump_right, ground, dig,
    output walk_left, walk_right, aaah, digging);
    parameter L=0,R=1,LF=2,RF=3,LD=4,RD=5; reg [2:0] state;
    always @(posedge clk or posedge areset) begin
        if (areset) state <= L;
        else case(state)
            L:  state <= !ground?LF : dig?LD : (bump_left?R:L);
            R:  state <= !ground?RF : dig?RD : (bump_right?L:R);
            LF: state <= !ground?LF:L;
            RF: state <= !ground?RF:R;
            LD: state <= ground?LD:LF;
            RD: state <= ground?RD:RF;
        endcase
    end
    assign walk_left  = (state==L);
    assign walk_right = (state==R);
    assign aaah       = (state==LF||state==RF);
    assign digging    = (state==LD||state==RD);
endmodule
