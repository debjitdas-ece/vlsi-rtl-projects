// HDLBits: module_cseladd
module top_module (
    input  [31:0] a, b,
    output [31:0] sum
);
    wire cout;
    wire [15:0] s1, s2a, s2b;
    add16 lo  (.a(a[15:0]),  .b(b[15:0]),  .cin(1'b0), .sum(s1),  .cout(cout));
    add16 hi0 (.a(a[31:16]), .b(b[31:16]), .cin(1'b0), .sum(s2a), .cout());
    add16 hi1 (.a(a[31:16]), .b(b[31:16]), .cin(1'b1), .sum(s2b), .cout());
    assign sum = {cout ? s2b : s2a, s1};
endmodule
