// HDLBits Problem 167: Mux from truth table
// Author: Debjit Das | JGEC ECE

module top_module (input [3:0] a, b, c, d, e, output reg [3:0] q);
    always @(*) case(c)
        4'd0:q=b; 4'd1:q=e; 4'd2:q=a; 4'd3:q=d;
        default:q=4'hf;
    endcase
endmodule
