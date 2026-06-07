// HDLBits: module_addsub
module top_module (
    input  [31:0] a, b,
    input         sub,
    output [31:0] sum
);
    wire cout;
    wire [31:0] b_xor;
    assign b_xor = b ^ {32{sub}};
    add16 lo (.a(a[15:0]),  .b(b_xor[15:0]),  .cin(sub),  .sum(sum[15:0]),  .cout(cout));
    add16 hi (.a(a[31:16]), .b(b_xor[31:16]), .cin(cout), .sum(sum[31:16]), .cout());
endmodule
