// HDLBits: module_fadd
module top_module (
    input  [31:0] a, b,
    output [31:0] sum
);
    wire cout;
    wire [15:0] s1, s2;
    add16 a1 (.a(a[15:0]),  .b(b[15:0]),  .cin(1'b0), .sum(s1), .cout(cout));
    add16 a2 (.a(a[31:16]), .b(b[31:16]), .cin(cout), .sum(s2), .cout());
    assign sum = {s2, s1};
endmodule
