// HDLBits: module_add
module top_module (
    input  [31:0] a, b,
    output [31:0] sum
);
    wire cout;
    add16 a1 (.a(a[15:0]),  .b(b[15:0]),  .cin(1'b0), .sum(sum[15:0]),  .cout(cout));
    add16 a2 (.a(a[31:16]), .b(b[31:16]), .cin(cout), .sum(sum[31:16]), .cout());
endmodule
