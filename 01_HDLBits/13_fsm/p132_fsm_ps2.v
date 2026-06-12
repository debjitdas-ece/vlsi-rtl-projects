// HDLBits Problem 132: PS/2 packet parser
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] in, input reset, output done);
    parameter b1=0,b2=1,b3=2,b_done=3; reg [1:0] s,ns;
    always @(*) case(s)
        b1:     ns = in[3] ? b2 : b1;
        b2:     ns = b3;
        b3:     ns = b_done;
        b_done: ns = in[3] ? b2 : b1;
    endcase
    always @(posedge clk) if (reset) s<=b1; else s<=ns;
    assign done = (s==b_done);
endmodule
