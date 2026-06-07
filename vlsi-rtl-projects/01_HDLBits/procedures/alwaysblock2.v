// HDLBits: alwaysblock2
module top_module (
    input      clk, a, b,
    output reg out_always_comb,
    output reg out_always_ff
);
    always @(*)        out_always_comb = a ^ b;
    always @(posedge clk) out_always_ff   = a ^ b;
endmodule
