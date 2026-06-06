// HDLBits: gates4
// AND, OR, XOR, XNOR of 4 inputs
module top_module (
    input  p1a, p1b, p1c, p1d, p1e, p1f,
    output p1y,
    input  p2a, p2b, p2c, p2d,
    output p2y
);
    assign {p1y, p2y}  = { (p1a & p1b & p1c) | (p1d & p1e & p1f) , ((p2a & p2b) | (p2c & p2d)) };
endmodule
