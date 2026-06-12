// HDLBits Problem 130: Lemmings 4
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, bump_left, bump_right, ground, dig,
    output walk_left, walk_right, aaah, digging);
    parameter L=0,R=1,LF=2,RF=3,LD=4,RD=5,S=6; reg [2:0] state,nxt;
    reg [4:0] fc;
    always @(*) begin
        case(state)
            L:  nxt = !ground?LF:dig?LD:(bump_left?R:L);
            R:  nxt = !ground?RF:dig?RD:(bump_right?L:R);
            LF: nxt = !ground?LF:fc>=20?S:L;
            RF: nxt = !ground?RF:fc>=20?S:R;
            LD: nxt = ground?LD:LF;
            RD: nxt = ground?RD:RF;
            S:  nxt = S;
            default: nxt = L;
        endcase
    end
    always @(posedge clk or posedge areset) begin
        if (areset) begin state<=L; fc<=0; end
        else begin
            state <= nxt;
            if (state==LF||state==RF) fc <= (fc==20)?20:fc+1'b1;
            else fc <= 5'd0;
        end
    end
    assign walk_left=(state==L); assign walk_right=(state==R);
    assign aaah=(state==LF||state==RF); assign digging=(state==LD||state==RD);
endmodule
