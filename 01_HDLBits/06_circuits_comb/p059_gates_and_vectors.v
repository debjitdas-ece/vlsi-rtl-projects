// HDLBits Problem 59: Gates and vectors
// Author: Debjit Das | JGEC ECE

module top_module (input [3:0] in,
    output [2:0] out_both, output [3:1] out_any, output [3:0] out_different);
    assign {out_both, out_any, out_different} = {
        in[2:0] & in[3:1],
        in[3:1] | in[2:0],
        in[3:0] ^ {in[0], in[3:1]}
    };
endmodule
