// N-phase center-aligned PWM core with dead-time, trip protection and ADC trigger.
module pwm_top #(parameter N = 3) (
  input clk, input rst_n, input en,
  input [15:0] psc, input [15:0] per, input [7:0] dt, input [15:0] atrg,
  input [16*N-1:0] duty,
  input flt, input flt_en, input sw_trp, input trp_clr,
  output reg [N-1:0] h, output reg [N-1:0] l,
  output trg, output trp, output trp_lat
);
  wire tick, dir, zero, top; wire [15:0] cnt;
  wire [16*N-1:0] dq; wire [N-1:0] raw, hd, ld_;
  pwm_prescaler       u_psc (.clk(clk), .rst_n(rst_n), .en(en), .psc(psc), .tick(tick));
  pwm_updown_counter  u_cnt (.clk(clk), .rst_n(rst_n), .en(en), .tick(tick), .per(per), .cnt(cnt), .dir(dir), .zero(zero), .top(top));
  pwm_dbuf  #(.N(N))  u_dbf (.clk(clk), .rst_n(rst_n), .ld(zero | ~en), .d(duty), .q(dq));
  pwm_compare #(.N(N)) u_cmp (.cnt(cnt), .duty(dq), .raw(raw));
  pwm_deadtime #(.N(N)) u_dt (.clk(clk), .rst_n(rst_n), .dt(dt), .raw(raw), .h(hd), .l(ld_));
  pwm_trip            u_trp (.clk(clk), .rst_n(rst_n), .flt(flt), .flt_en(flt_en), .sw(sw_trp), .clr(trp_clr), .trp(trp), .lat(trp_lat));
  pwm_adctrig         u_adc (.clk(clk), .rst_n(rst_n), .en(en), .tick(tick), .dir(dir), .cnt(cnt), .atrg(atrg), .trg(trg));
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin h <= {N{1'b0}}; l <= {N{1'b0}}; end
    else begin
      h <= (en & ~trp) ? hd  : {N{1'b0}};
      l <= (en & ~trp) ? ld_ : {N{1'b0}};
    end
endmodule
