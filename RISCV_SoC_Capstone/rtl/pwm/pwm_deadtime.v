// Complementary outputs with dead-time: on every raw edge both switches are off for dt clocks.
module pwm_deadtime #(parameter N = 3) (
  input clk, input rst_n, input [7:0] dt, input [N-1:0] raw,
  output [N-1:0] h, output [N-1:0] l
);
  genvar i;
  generate for (i = 0; i < N; i = i + 1) begin : g
    reg rq; reg [7:0] dc;
    wire chg = raw[i] ^ rq;
    always @(posedge clk or negedge rst_n)
      if (!rst_n) begin rq <= 1'b0; dc <= 8'd0; end
      else begin
        rq <= raw[i];
        dc <= chg ? dt : (dc != 8'd0) ? dc - 8'd1 : dc;
      end
    assign h[i] =  rq & ~chg & (dc == 8'd0);
    assign l[i] = ~rq & ~chg & (dc == 8'd0);
  end endgenerate
endmodule
