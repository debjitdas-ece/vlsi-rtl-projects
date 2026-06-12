// HDLBits Problem 173: Testbench: clock
// Author: Debjit Das | JGEC ECE

module top_module;
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;
    dut my_instance(.clk(clk));
endmodule
