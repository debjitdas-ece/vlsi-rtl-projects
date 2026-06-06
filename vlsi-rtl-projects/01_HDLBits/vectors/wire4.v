// HDLBits: wire4
// Connect 4 inputs to 4 outputs
module top_module (
    input  a, b, c, d,
    output w, x, y, z
);
    assign w = a;
    assign x = b;
    assign y = c;
    assign z = d;
endmodule
