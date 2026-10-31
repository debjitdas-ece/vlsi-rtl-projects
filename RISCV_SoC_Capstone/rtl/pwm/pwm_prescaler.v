module pwm_prescaler (
  input clk, input rst_n, input en, input [15:0] psc,
  output tick
);
  reg [15:0] c;
  wire last = (c >= psc);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) c <= 16'd0;
    else c <= !en ? 16'd0 : last ? 16'd0 : c + 16'd1;
  assign tick = en & last;
endmodule
