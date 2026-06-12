// HDLBits Problem 106: 12-hour clock
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, ena,
    output reg pm, output [7:0] hh, mm, ss);
    wire e2, e3, half;
    assign e2   = (ss==8'h59) && ena;
    assign e3   = (mm==8'h59 && ss==8'h59) && ena;
    assign half = (hh==8'h11 && mm==8'h59 && ss==8'h59) && ena;
    always @(posedge clk) begin
        if (reset) pm <= 1'b0;
        else if (half) pm <= ~pm;
    end
    sixty sec(.clk(clk),.reset(reset),.ena(ena),.q(ss));
    sixty min(.clk(clk),.reset(reset),.ena(e2), .q(mm));
    twelve hour(.clk(clk),.reset(reset),.ena(e3),.q(hh));
endmodule
module sixty (input clk, reset, ena, output [7:0] q);
    wire ena_high;
    assign ena_high = (q[3:0]==4'd9) && ena;
    onedigit o1(.clk(clk),.reset(reset),.ena(ena),     .q(q[3:0]));
    twodigit t1(.clk(clk),.reset(reset),.ena(ena_high),.q(q[7:4]));
endmodule
module twelve (input clk, reset, ena, output reg [7:0] q);
    always @(posedge clk) begin
        if (reset) q <= 8'h12;
        else if (ena) begin
            if (q==8'h12) q <= 8'h01;
            else if (q[3:0]==4'd9) begin q[3:0]<=4'd0; q[7:4]<=q[7:4]+1'b1; end
            else q[3:0] <= q[3:0]+1'b1;
        end
    end
endmodule
module onedigit (input clk, ena, reset, output reg [3:0] q);
    always @(posedge clk) begin
        if (reset) q<=4'd0; else if (ena) q<=(q==4'd9)?4'd0:q+1'b1;
    end
endmodule
module twodigit (input clk, ena, reset, output reg [3:0] q);
    always @(posedge clk) begin
        if (reset) q<=4'd0; else if (ena) q<=(q==4'd5)?4'd0:q+1'b1;
    end
endmodule
