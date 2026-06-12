// HDLBits Problem 60: Even longer vectors
// Author: Debjit Das | JGEC ECE

module top_module (input [99:0] in,
    output [98:0] out_both, output [99:1] out_any, output [99:0] out_different);
    assign {out_both, out_any, out_different} = {
        in[98:0] & in[99:1],
        in[99:1] | in[98:0],
        in[99:0] ^ {in[0], in[99:1]}
    };
endmodule
