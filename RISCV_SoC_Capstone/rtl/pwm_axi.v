// AXI4-Lite PWM peripheral @0x2000_0000
//  0x00 CTRL  b0 en  b1 sw_trip  b2 flt_en  b3 trip_clr (write 1, self-clearing)
//  0x04 PSC   0x08 PER   0x0C DT (clocks)   0x10 ATRG   0x14 STATUS (b0 trp b1 lat b2 flt_in b3 en)
//  0x20+4*i DUTY[i]  (shadowed; applied at counter zero)
module pwm_axi #(parameter N = 3) (
  input clk, input rst_n,
  input  [31:0] s_awaddr, input s_awvalid, output s_awready,
  input  [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output s_bvalid, input s_bready,
  input  [31:0] s_araddr, input s_arvalid, output s_arready,
  output [31:0] s_rdata, output [1:0] s_rresp, output s_rvalid, input s_rready,
  input flt_in, output [N-1:0] pwm_h, output [N-1:0] pwm_l, output adc_trig
);
  wire we; wire [31:0] wa, wd, ra; wire [3:0] ws; reg [31:0] rd;
  axil_reg_if u_if (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .reg_we(we), .reg_wa(wa), .reg_wd(wd), .reg_ws(ws), .reg_re(), .reg_ra(ra), .reg_rd(rd));

  reg en, swt, fen, clr; reg [15:0] psc, per, atrg; reg [7:0] dt; reg [16*N-1:0] duty;
  wire trp, lat; integer wi, ri;   // separate loop variables: one per always block (a shared one has two drivers)
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin en <= 1'b0; swt <= 1'b0; fen <= 1'b0; clr <= 1'b0;
                      psc <= 16'd0; per <= 16'd500; dt <= 8'd25; atrg <= 16'd0; duty <= {16*N{1'b0}}; end
    else begin
      clr <= 1'b0;
      if (we) case (wa[7:2])
        6'd0: begin en <= wd[0]; swt <= wd[1]; fen <= wd[2]; clr <= wd[3]; end
        6'd1: psc <= wd[15:0];
        6'd2: per <= wd[15:0];
        6'd3: dt  <= wd[7:0];
        6'd4: atrg <= wd[15:0];
        default: for (wi = 0; wi < N; wi = wi + 1) if ({26'd0, wa[7:2]} == 32'd8 + wi) duty[16*wi +: 16] <= wd[15:0];
      endcase
    end
  always @* begin
    rd = 32'd0;
    case (ra[7:2])
      6'd0: rd = {28'd0, 1'b0, fen, swt, en};
      6'd1: rd = {16'd0, psc};
      6'd2: rd = {16'd0, per};
      6'd3: rd = {24'd0, dt};
      6'd4: rd = {16'd0, atrg};
      6'd5: rd = {28'd0, en, flt_in, lat, trp};
      default: for (ri = 0; ri < N; ri = ri + 1) if ({26'd0, ra[7:2]} == 32'd8 + ri) rd = {16'd0, duty[16*ri +: 16]};
    endcase
  end
  pwm_top #(.N(N)) u_pwm (.clk(clk), .rst_n(rst_n), .en(en), .psc(psc), .per(per), .dt(dt), .atrg(atrg),
    .duty(duty), .flt(flt_in), .flt_en(fen), .sw_trp(swt), .trp_clr(clr),
    .h(pwm_h), .l(pwm_l), .trg(adc_trig), .trp(trp), .trp_lat(lat));
endmodule
