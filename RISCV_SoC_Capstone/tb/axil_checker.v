`timescale 1ns/1ps
// Passive AXI4-Lite protocol checker (simulation only). Samples on posedge clk.
// Rules checked (after reset release):
//   R1 no X/Z on any VALID; no X/Z on a READY while its VALID is high (an idle READY may be X in 4-state
//      simulators because PicoRV32 does not reset mem_addr)
//   R2 once VALID is high it stays high, with a stable payload, until READY (AW, W, AR, B, R)
//   R3 no B response before BOTH the AW and W handshakes; no R response before the AR handshake
//   R4 RESP is never EXOKAY (2'b01) in AXI4-Lite
// Violations are counted in `viol` and printed with the instance NAME.
module axil_checker #(parameter NAME = "chk") (
  input clk, input rst_n,
  input awvalid, input awready, input [31:0] awaddr,
  input wvalid,  input wready,  input [31:0] wdata, input [3:0] wstrb,
  input bvalid,  input bready,  input [1:0] bresp,
  input arvalid, input arready, input [31:0] araddr,
  input rvalid,  input rready,  input [31:0] rdata, input [1:0] rresp
);
  integer viol = 0, aw_n = 0, w_n = 0, b_n = 0, ar_n = 0, r_n = 0;
  reg p_awv=0, p_awr=0, p_wv=0, p_wr=0, p_bv=0, p_br=0, p_arv=0, p_arr=0, p_rv=0, p_rr=0;
  reg [31:0] p_awa, p_wd, p_ara, p_rd; reg [3:0] p_ws; reg [1:0] p_bresp, p_rresp;
  reg seen_rst = 0;

  task fail(input [8*40-1:0] msg); begin
    viol = viol + 1;
    if (viol <= 10) $display("[AXIL-CHK %0s] t=%0t VIOLATION: %0s", NAME, $time, msg);
  end endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      p_awv<=0; p_wv<=0; p_bv<=0; p_arv<=0; p_rv<=0; p_awr<=0; p_wr<=0; p_br<=0; p_arr<=0; p_rr<=0;
      aw_n = 0; w_n = 0; b_n = 0; ar_n = 0; r_n = 0; seen_rst = 1;
    end else if (seen_rst) begin
      // R1
      if ((^{awvalid,wvalid,bvalid,arvalid,rvalid}) === 1'bx) fail("X on VALID");
      if ((awvalid && ((^awready) === 1'bx)) || (wvalid && ((^wready) === 1'bx)) || (bvalid && ((^bready) === 1'bx)) ||
          (arvalid && ((^arready) === 1'bx)) || (rvalid && ((^rready) === 1'bx))) fail("X on READY while VALID");
      // R2 : previous cycle VALID && !READY  =>  still VALID, payload unchanged
      if (p_awv && !p_awr && !(awvalid && awaddr === p_awa)) fail("AW dropped/changed before ready");
      if (p_wv  && !p_wr  && !(wvalid  && wdata === p_wd && wstrb === p_ws)) fail("W dropped/changed before ready");
      if (p_arv && !p_arr && !(arvalid && araddr === p_ara)) fail("AR dropped/changed before ready");
      if (p_bv  && !p_br  && !(bvalid  && bresp === p_bresp)) fail("B dropped/changed before ready");
      if (p_rv  && !p_rr  && !(rvalid  && rdata === p_rd && rresp === p_rresp)) fail("R dropped/changed before ready");
      // R3 : responses only after the request handshake(s) of an EARLIER cycle
      if (bvalid && !(aw_n > b_n && w_n > b_n)) fail("B before AW and W handshakes");
      if (rvalid && !(ar_n > r_n))              fail("R before AR handshake");
      // R4
      if (bvalid && bresp === 2'b01) fail("B EXOKAY in AXI4-Lite");
      if (rvalid && rresp === 2'b01) fail("R EXOKAY in AXI4-Lite");
      // handshake counters (updated after the checks above, so they reflect earlier cycles)
      if (awvalid && awready) aw_n = aw_n + 1;
      if (wvalid  && wready)  w_n  = w_n  + 1;
      if (bvalid  && bready)  b_n  = b_n  + 1;
      if (arvalid && arready) ar_n = ar_n + 1;
      if (rvalid  && rready)  r_n  = r_n  + 1;
      p_awv<=awvalid; p_awr<=awready; p_awa<=awaddr;
      p_wv<=wvalid; p_wr<=wready; p_wd<=wdata; p_ws<=wstrb;
      p_bv<=bvalid; p_br<=bready; p_bresp<=bresp;
      p_arv<=arvalid; p_arr<=arready; p_ara<=araddr;
      p_rv<=rvalid; p_rr<=rready; p_rd<=rdata; p_rresp<=rresp;
    end
  end
endmodule
