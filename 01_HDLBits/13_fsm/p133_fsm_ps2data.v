// HDLBits Problem 133: PS/2 packet parser with datapath
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] in, input reset,
    output [23:0] out_bytes, output done);
    parameter b1=0,b2=1,b3=2,b_done=3; reg [1:0] s,ns;
    reg [23:0] rb;
    always @(*) case(s)
        b1:     ns = in[3] ? b2 : b1;
        b2:     ns = b3;
        b3:     ns = b_done;
        b_done: ns = in[3] ? b2 : b1;
    endcase
    always @(posedge clk) begin
        if (reset) begin s<=b1; rb<=24'b0; end
        else begin s<=ns; rb<={rb[15:0],in}; end
    end
    assign done     = (s==b_done);
    assign out_bytes = rb;
endmodule
