// ADC trigger: 1-clk pulse when the up-counting counter hits atrg (sample mid-on-time).
module pwm_adctrig (
  input clk, input rst_n, input en, input tick, input dir,
  input [15:0] cnt, input [15:0] atrg,
  output reg trg
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) trg <= 1'b0;
    else trg <= en & tick & dir & (cnt == atrg);
endmodule
