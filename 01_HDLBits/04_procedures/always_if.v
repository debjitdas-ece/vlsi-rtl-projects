// HDLBits Problem 31: If statement
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, sel_b1, sel_b2,
    output reg out_assign, output reg out_always);
    assign out_assign = (sel_b1 & sel_b2) ? b : a;
    always @(*) begin
        if (sel_b1 & sel_b2) out_always = b;
        else                 out_always = a;
    end
endmodule
