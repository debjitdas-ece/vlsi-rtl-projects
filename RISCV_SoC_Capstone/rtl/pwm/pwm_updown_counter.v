// Triangular counter 0..per..0 (center-aligned). zero/top are 1-clk event pulses on tick.
module pwm_updown_counter (
  input clk, input rst_n, input en, input tick, input [15:0] per,
  output [15:0] cnt, output dir, output zero, output top
);
  reg [15:0] c; reg d;   // d=1: counting up
  wire at_top = d & (c >= per);
  wire at_bot = ~d & (c == 16'd0);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin c <= 16'd0; d <= 1'b1; end
    else begin
      c <= !en ? 16'd0 : !tick ? c : at_top ? ((per == 16'd0) ? 16'd0 : c - 16'd1) : at_bot ? 16'd1 : d ? c + 16'd1 : c - 16'd1;
      d <= !en ? 1'b1  : !tick ? d : at_top ? 1'b0 : at_bot ? 1'b1 : d;
    end
  assign cnt = c; assign dir = d;
  assign zero = tick & (c == 16'd0);
  assign top  = tick & d & (c >= per);
endmodule
