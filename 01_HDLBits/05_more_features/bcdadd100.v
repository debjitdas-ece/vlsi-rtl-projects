// HDLBits Problem 43: 100-digit BCD adder
// Author: Debjit Das | JGEC ECE

module top_module (input [399:0] a, b, input cin,
    output cout, output [399:0] sum);
    wire [99:0] c;
    genvar i;
    generate
        for (i=0; i<100; i=i+1) begin : bcd
            bcd_fadd fa (.a(a[4*i+3:4*i]), .b(b[4*i+3:4*i]),
                .cin(i==0 ? cin : c[i-1]), .cout(c[i]), .sum(sum[4*i+3:4*i]));
        end
    endgenerate
    assign cout = c[99];
endmodule
