`timescale 1ns/1ps
// Self-checking testbench for both SoCs.  Base: -DBASE (default)   Plus: -DPLUS
module tb_top;
  localparam BAUD_CYC = 434;               // 50 MHz / 115200
  reg clk = 0, reset = 1;
  reg uart_rx_pin = 1;
  wire uart_tx_pin;
  always #10 clk = ~clk;                   // 50 MHz

`ifdef PLUS
  reg fault_in = 0; reg [7:0] gpio_in = 8'hA5;
  wire [7:0] gpio_out; wire [2:0] pwm_h, pwm_l; wire adc_trig;
  top_plus u_dut (.clk(clk), .reset(reset), .uart_tx(uart_tx_pin), .uart_rx(uart_rx_pin),
                  .fault_in(fault_in), .gpio_in(gpio_in), .gpio_out(gpio_out),
                  .pwm_h(pwm_h), .pwm_l(pwm_l), .adc_trig(adc_trig));
`else
  top u_dut (.clk(clk), .reset(reset), .uart_tx(uart_tx_pin), .uart_rx(uart_rx_pin));
`endif

  // ---------------- UART monitor: falling edge -> sample mid-bit -> rx_buf ----------------
  reg [7:0] rx_buf [0:8191];
  integer rx_wr = 0, scan_from = 0, log_ptr = 0, logf;
  reg [7:0] b; integer k;
  initial begin
    logf = $fopen("build/uart_log.txt", "w");
    forever begin
      @(negedge uart_tx_pin);
      repeat (BAUD_CYC + BAUD_CYC/2) @(posedge clk);
      for (k = 0; k < 8; k = k + 1) begin b[k] = uart_tx_pin; repeat (BAUD_CYC) @(posedge clk); end
      rx_buf[rx_wr & 8191] = b; rx_wr = rx_wr + 1;
    end
  end
  // separate logger process (avoids the delta-cycle race noted in Module 6)
  initial forever begin
    while (log_ptr == rx_wr) #10;
    $fwrite(logf, "%c", rx_buf[log_ptr & 8191]); $write("%c", rx_buf[log_ptr & 8191]);
    log_ptr = log_ptr + 1;
  end

  // ---------------- helpers ----------------
  task uart_send(input [7:0] c); integer j; begin
    uart_rx_pin = 0; repeat (BAUD_CYC) @(posedge clk);
    for (j = 0; j < 8; j = j + 1) begin uart_rx_pin = c[j]; repeat (BAUD_CYC) @(posedge clk); end
    uart_rx_pin = 1; repeat (BAUD_CYC) @(posedge clk);
  end endtask
  task uart_str(input [8*8-1:0] s, input integer n); integer j; begin
    for (j = n-1; j >= 0; j = j - 1) uart_send(s[8*j +: 8]);
  end endtask
  function tail_match(input [8*16-1:0] pat, input integer n); integer j; begin
    tail_match = 1;
    for (j = 0; j < n; j = j + 1)
      if (rx_buf[(rx_wr - 1 - j) & 8191] !== pat[8*j +: 8]) tail_match = 0;
  end endfunction
  reg ok; integer last_wr;
  task wait_for(input [8*16-1:0] pat, input integer n, input integer timeout); integer t; begin
    ok = 0; t = 0; last_wr = rx_wr;
    while (!ok && t < timeout) begin
      @(posedge clk); t = t + 1;
      if (rx_wr != last_wr) begin
        last_wr = rx_wr;
        if (rx_wr - scan_from >= n && tail_match(pat, n)) ok = 1;
      end
    end
    scan_from = rx_wr;
    if (!ok) begin $display("\n[TB] TIMEOUT waiting for pattern"); $display("TEST FAILED"); $fatal(1); end
  end endtask
  task wait_newlines(input integer cnt, input integer timeout); integer t, seen, p; begin
    t = 0; seen = 0; p = scan_from;
    while (seen < cnt && t < timeout) begin
      @(posedge clk); t = t + 1;
      while (p < rx_wr) begin if (rx_buf[p & 8191] == 8'h0A) seen = seen + 1; p = p + 1; end
    end
    scan_from = rx_wr;
    if (seen < cnt) begin $display("\n[TB] TIMEOUT waiting for %0d lines", cnt); $display("TEST FAILED"); $fatal(1); end
  end endtask


  // ---------------- AXI4-Lite protocol checkers (CPU bus, ROM port, SRAM port) ----------------
  wire rstn_i = u_dut.rst_n;
  axil_checker #(.NAME("cpu")) c_cpu (.clk(clk), .rst_n(rstn_i),
    .awvalid(u_dut.m_awvalid), .awready(u_dut.m_awready), .awaddr(u_dut.m_awaddr),
    .wvalid(u_dut.m_wvalid), .wready(u_dut.m_wready), .wdata(u_dut.m_wdata), .wstrb(u_dut.m_wstrb),
    .bvalid(u_dut.m_bvalid), .bready(u_dut.m_bready), .bresp(u_dut.m_bresp),
    .arvalid(u_dut.m_arvalid), .arready(u_dut.m_arready), .araddr(u_dut.m_araddr),
    .rvalid(u_dut.m_rvalid), .rready(u_dut.m_rready), .rdata(u_dut.m_rdata), .rresp(u_dut.m_rresp));
  axil_checker #(.NAME("rom")) c_rom (.clk(clk), .rst_n(rstn_i),
    .awvalid(u_dut.s_awvalid[0]), .awready(u_dut.s_awready[0]), .awaddr(u_dut.s_awaddr),
    .wvalid(u_dut.s_wvalid[0]), .wready(u_dut.s_wready[0]), .wdata(u_dut.s_wdata), .wstrb(u_dut.s_wstrb),
    .bvalid(u_dut.s_bvalid[0]), .bready(u_dut.s_bready[0]), .bresp(u_dut.s_bresp[1:0]),
    .arvalid(u_dut.s_arvalid[0]), .arready(u_dut.s_arready[0]), .araddr(u_dut.s_araddr),
    .rvalid(u_dut.s_rvalid[0]), .rready(u_dut.s_rready[0]), .rdata(u_dut.s_rdata[31:0]), .rresp(u_dut.s_rresp[1:0]));
  axil_checker #(.NAME("sram")) c_sram (.clk(clk), .rst_n(rstn_i),
    .awvalid(u_dut.s_awvalid[1]), .awready(u_dut.s_awready[1]), .awaddr(u_dut.s_awaddr),
    .wvalid(u_dut.s_wvalid[1]), .wready(u_dut.s_wready[1]), .wdata(u_dut.s_wdata), .wstrb(u_dut.s_wstrb),
    .bvalid(u_dut.s_bvalid[1]), .bready(u_dut.s_bready[1]), .bresp(u_dut.s_bresp[3:2]),
    .arvalid(u_dut.s_arvalid[1]), .arready(u_dut.s_arready[1]), .araddr(u_dut.s_araddr),
    .rvalid(u_dut.s_rvalid[1]), .rready(u_dut.s_rready[1]), .rdata(u_dut.s_rdata[63:32]), .rresp(u_dut.s_rresp[3:2]));
  task final_verdict; integer v; begin
    v = c_cpu.viol + c_rom.viol + c_sram.viol;
    $display("[TB] AXI4-Lite protocol violations: %0d", v);
    if (v != 0) begin $display("TEST FAILED"); $fatal(1); end
    $display("TEST PASSED");
  end endtask

  // ---------------- optional waveform ----------------
  initial if ($test$plusargs("wave")) begin $dumpfile("build/tb_top.fst"); $dumpvars(0, tb_top); end
  // CPU trap = firmware crash
  always @(posedge clk) if (!reset && u_dut.trap_w) begin $display("\n[TB] CPU TRAP"); $display("TEST FAILED"); $fatal(1); end

`ifdef PLUS
  // ---------------- safety assertions (EV motor drive) ----------------
  integer shoot = 0, adc_cnt = 0, tripped_cycles = 0;
  always @(posedge clk) begin
    if (|(pwm_h & pwm_l)) shoot = shoot + 1;           // shoot-through must never happen
    if (adc_trig) adc_cnt = adc_cnt + 1;
  end
`endif

  // ---------------- main sequence ----------------
  initial begin
    repeat (10) @(posedge clk); reset = 0;
`ifndef PLUS
    wait_newlines(10, 3000000);
    $display("[TB] 10 greetings received, sending PING");
    uart_str("PING", 4);
    wait_for("PING", 4, 200000);
    $display("\n[TB] echo OK");
    final_verdict;
    $finish;
`else
    wait_for("READY", 5, 3000000);
    wait_for("TEL,3,", 6, 3000000);
    $display("\n[TB] injecting fault_in");
    fault_in = 1;
    repeat (20) @(posedge clk);
    if (pwm_h !== 3'b000 || pwm_l !== 3'b000) begin $display("[TB] outputs not forced off by trip"); $display("TEST FAILED"); $fatal(1); end
    wait_for("TEL,6,", 6, 3000000);
    $display("\n[TB] releasing fault_in");
    fault_in = 0;
    wait_for("CLR", 3, 3000000);
    wait_for("TEL,11,", 7, 3000000);
    wait_for("> ", 2, 3000000);
    uart_str("st\015", 3);   wait_for("en=1", 4, 400000);
    wait_for("> ", 2, 400000);
    uart_str("d 1 75\015", 7); wait_for("OK", 2, 400000);
    wait_for("> ", 2, 400000);
    uart_str("g a\015", 4);  wait_for("OK", 2, 400000);
    if (gpio_out !== 8'h0a) begin $display("[TB] gpio_out wrong: %h", gpio_out); $display("TEST FAILED"); $fatal(1); end
    wait_for("> ", 2, 400000);
    uart_str("x\015", 2);   wait_for("ERR", 3, 400000);
    $display("\n[TB] shoot-through events: %0d, ADC triggers: %0d", shoot, adc_cnt);
    if (shoot != 0 || adc_cnt == 0) begin $display("TEST FAILED"); $fatal(1); end
    final_verdict;
    $finish;
`endif
  end
  initial begin #300_000_000; $display("\n[TB] GLOBAL TIMEOUT"); $display("TEST FAILED"); $fatal(1); end
endmodule
