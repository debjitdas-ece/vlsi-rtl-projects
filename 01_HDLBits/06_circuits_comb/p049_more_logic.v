// HDLBits Problem 49: More logic gates
// Author: Debjit Das | JGEC ECE

module top_module (input a, b,
    output out_and, out_or, out_xor,
    out_nand, out_nor, out_xnor, out_anotb);
    assign {out_and, out_or, out_xor}    = {a&b, a|b, a^b};
    assign {out_nand, out_nor, out_xnor} = {~(a&b), ~(a|b), ~(a^b)};
    assign out_anotb = a & (~b);
endmodule
