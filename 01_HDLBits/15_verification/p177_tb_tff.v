// HDLBits Problem 177: Testbench: TFF
// Author: Debjit Das | JGEC ECE

module top_module;
    reg clk, reset, t; wire q;
    tff dut(.clk(clk),.reset(reset),.t(t),.q(q));
    initial clk=0; always #5 clk=~clk;
    initial begin
        reset=1; t=0; #10; reset=0; t=1;
    end
endmodule
