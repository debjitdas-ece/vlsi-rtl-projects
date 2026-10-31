// Fault protection: hardware fault input (latched), software trip, write-1-to-clear.
// Latch only clears when the fault input is no longer asserted.
module pwm_trip (
  input clk, input rst_n,
  input flt, input flt_en, input sw, input clr,
  output trp, output reg lat
);
  wire f = flt & flt_en;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) lat <= 1'b0;
    else lat <= (clr & ~f) ? 1'b0 : (lat | f);
  assign trp = lat | sw | f;
endmodule
