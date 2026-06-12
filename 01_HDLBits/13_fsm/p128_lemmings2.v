// HDLBits Problem 128: Lemmings 2
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, bump_left, bump_right, ground,
    output walk_left, walk_right, aaah);
    parameter L=0,R=1,LF=2,RF=3; reg [1:0] state;
    always @(posedge clk or posedge areset) begin
        if (areset) state <= L;
        else case(state)
            L:  state <= !ground ? LF : (bump_left  ? R : L);
            R:  state <= !ground ? RF : (bump_right ? L : R);
            LF: state <= ground  ? L  : LF;
            RF: state <= ground  ? R  : RF;
        endcase
    end
    assign walk_left  = (state==L);
    assign walk_right = (state==R);
    assign aaah       = (state==LF || state==RF);
endmodule
