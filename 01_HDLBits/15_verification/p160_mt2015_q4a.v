// HDLBits Problem 160: 2-to-1 mux using 3 instances
// Author: Debjit Das | JGEC ECE

module top_module (input [1:0] sel, input [7:0] a,b,c,d, output [7:0] out);
    wire [7:0] mx, my;
    mux2 m0(.sel(sel[0]),.a(a),.b(b),.out(mx));
    mux2 m1(.sel(sel[0]),.a(c),.b(d),.out(my));
    mux2 mf(.sel(sel[1]),.a(mx),.b(my),.out(out));
endmodule
