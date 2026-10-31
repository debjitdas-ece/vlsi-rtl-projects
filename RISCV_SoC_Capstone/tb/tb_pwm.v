`timescale 1ns/1ps
// Unit test for the PWM IP core: duty accuracy, dead-time, trip response, ADC trigger.
module tb_pwm;
  reg clk = 0, rst_n = 0; always #10 clk = ~clk;
  reg en = 0; reg [15:0] psc = 0, per = 500, atrg = 250; reg [7:0] dt = 25;
  reg [47:0] duty = {16'd100, 16'd250, 16'd400};     // ch0=400 ch1=250 ch2=100
  reg flt = 0, flt_en = 1, sw = 0, clr = 0;
  wire [2:0] h, l; wire trg, trp, lat;
  pwm_top #(.N(3)) dut (.clk(clk), .rst_n(rst_n), .en(en), .psc(psc), .per(per), .dt(dt), .atrg(atrg), .duty(duty),
    .flt(flt), .flt_en(flt_en), .sw_trp(sw), .trp_clr(clr), .h(h), .l(l), .trg(trg), .trp(trp), .trp_lat(lat));
  integer hi [0:2]; integer lo [0:2]; integer c, i, shoot, gap_min, gap, trgs; reg prev_any;
  initial begin
    repeat (4) @(posedge clk); rst_n = 1; @(posedge clk); en = 1;
    repeat (1000) @(posedge clk);                    // settle (duty loads at counter zero)
    for (i = 0; i < 3; i = i + 1) begin hi[i] = 0; lo[i] = 0; end
    shoot = 0; trgs = 0; gap = 0; gap_min = 9999; prev_any = 1;
    for (c = 0; c < 1000; c = c + 1) begin           // exactly one PWM period (2*per clocks)
      @(posedge clk);
      for (i = 0; i < 3; i = i + 1) begin hi[i] = hi[i] + h[i]; lo[i] = lo[i] + l[i]; end
      if (|(h & l)) shoot = shoot + 1;
      if (trg) trgs = trgs + 1;
      if (!h[1] && !l[1]) gap = gap + 1; else begin if (gap != 0 && gap < gap_min) gap_min = gap; gap = 0; end
    end
    $display("ch0 h=%0d l=%0d | ch1 h=%0d l=%0d | ch2 h=%0d l=%0d | shoot=%0d dead-gap(ch1)=%0d trg=%0d",
             hi[0], lo[0], hi[1], lo[1], hi[2], lo[2], shoot, gap_min, trgs);
    // expected high ~ 2*duty - dt (dead-time eats dt clocks on the rising edge side)
    if (hi[0] < 770 || hi[0] > 780 || hi[1] < 470 || hi[1] > 480 || hi[2] < 170 || hi[2] > 180 || shoot != 0 || trgs != 1 || gap_min < 24 || gap_min > 27) begin
      $display("TEST FAILED"); $fatal(1); end
    // trip response
    flt = 1; repeat (3) @(posedge clk);
    if (h !== 3'b0 || l !== 3'b0 || !lat) begin $display("trip failed"); $display("TEST FAILED"); $fatal(1); end
    flt = 0; repeat (3) @(posedge clk);
    if (h !== 3'b0 || !lat) begin $display("latch should hold after fault removal"); $display("TEST FAILED"); $fatal(1); end
    clr = 1; @(posedge clk); clr = 0; repeat (400) @(posedge clk);
    if (lat || (h === 3'b0 && l === 3'b0)) begin $display("clear failed"); $display("TEST FAILED"); $fatal(1); end
    $display("TEST PASSED"); $finish;
  end
endmodule
