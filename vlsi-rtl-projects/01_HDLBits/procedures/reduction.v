// HDLBits: reduction
// Parity check using XOR reduction
module top_module (
    input  [7:0] in,
    output       parity
);
    assign parity = ^in;
endmodule
