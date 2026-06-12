// HDLBits Problem 50: 7420 chip
// Author: Debjit Das | JGEC ECE

module top_module (
    input p1a, p1b, p1c, p1d, output p1y,
    input p2a, p2b, p2c, p2d, output p2y);
    assign {p1y, p2y} = {~(p1a&p1b&p1c&p1d), ~(p2a&p2b&p2c&p2d)};
endmodule
