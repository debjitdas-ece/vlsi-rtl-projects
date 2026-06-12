// HDLBits Problem 161: Add/subtract
// Author: Debjit Das | JGEC ECE

module top_module (input do_sub, input [7:0] a, b,
    output reg [7:0] out, output reg result_is_zero);
    reg c_add, c_sub;
    always @(*) begin
        case(do_sub)
            1'b0: {c_add, out} = a + b;
            1'b1: {c_sub, out} = a - b;
        endcase
        result_is_zero = (out==8'b0) ? 1'b1 : 1'b0;
    end
endmodule
