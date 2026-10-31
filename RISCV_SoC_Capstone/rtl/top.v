`ifndef SRAM_WORDS_DEF
`define SRAM_WORDS_DEF 256   // 1 KB flop SRAM for simulation; use 64 (256 B) for the ASIC run
`endif
// BASE capstone SoC: PicoRV32 + AXI-Lite bridge/interconnect + ROM + SRAM + UART.
// Ports match the Module 6 SDC/pin-order: clk, reset, uart_tx, uart_rx.
module top #(parameter ROM_WORDS = 1024, parameter SRAM_WORDS = `SRAM_WORDS_DEF) (
  input  clk,
  input  reset,        // active-high, asynchronous
  output uart_tx,
  input  uart_rx
);
  wire rst_n; rst_sync u_rs (.clk(clk), .arst(reset), .rst_n(rst_n));
  wire rx_s;  sync2 #(.W(1), .RV(1'b1)) u_srx (.clk(clk), .rst_n(rst_n), .d(uart_rx), .q(rx_s));

  wire        mem_valid, mem_instr, mem_ready, trap, trap_w;
  assign trap_w = trap;
  wire [31:0] mem_addr, mem_wdata, mem_rdata; wire [3:0] mem_wstrb;
  picorv32 #(.ENABLE_COUNTERS(1), .ENABLE_REGS_16_31(1), .PROGADDR_RESET(32'h0000_0000),
             .STACKADDR(32'h0001_0000 + SRAM_WORDS*4), .BARREL_SHIFTER(0), .COMPRESSED_ISA(0),
             .ENABLE_MUL(0), .ENABLE_DIV(0), .ENABLE_IRQ(0)) u_cpu (
    .clk(clk), .resetn(rst_n), .trap(trap),
    .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata),
    .irq(32'b0), .pcpi_wr(1'b0), .pcpi_rd(32'b0), .pcpi_wait(1'b0), .pcpi_ready(1'b0));

  wire [31:0] m_awaddr, m_wdata, m_araddr, m_rdata; wire [3:0] m_wstrb; wire [1:0] m_bresp, m_rresp;
  wire m_awvalid, m_awready, m_wvalid, m_wready, m_bvalid, m_bready, m_arvalid, m_arready, m_rvalid, m_rready, err_p;
  axi_bridge u_br (.clk(clk), .rst_n(rst_n),
    .mem_valid(mem_valid), .mem_ready(mem_ready), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata),
    .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_araddr(m_araddr), .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rvalid(m_rvalid), .m_rready(m_rready), .err_p(err_p));

  wire [31:0] s_awaddr, s_wdata, s_araddr; wire [3:0] s_wstrb;
  wire [4:0] s_awvalid, s_awready, s_wvalid, s_wready, s_bvalid, s_bready, s_arvalid, s_arready, s_rvalid, s_rready;
  wire [9:0] s_bresp, s_rresp; wire [159:0] s_rdata;
  axi_lite_interconnect #(.PLUS(0), .ROM_BYTES(ROM_WORDS*4), .SRAM_BYTES(SRAM_WORDS*4)) u_ic (.clk(clk), .rst_n(rst_n),
    .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_araddr(m_araddr), .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rvalid(m_rvalid), .m_rready(m_rready),
    .s_awaddr(s_awaddr), .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_araddr(s_araddr),
    .s_awvalid(s_awvalid), .s_awready(s_awready), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready));

  // S3/S4 unused in the base SoC (decoder never selects them)
  assign s_awready[4:3] = 2'b0; assign s_wready[4:3] = 2'b0; assign s_bvalid[4:3] = 2'b0;
  assign s_arready[4:3] = 2'b0; assign s_rvalid[4:3] = 2'b0; assign s_bresp[9:6] = 4'b0;
  assign s_rresp[9:6] = 4'b0;   assign s_rdata[159:96] = 64'b0;

  rom  #(.WORDS(ROM_WORDS))  u_rom (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[0]), .s_awready(s_awready[0]),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[0]), .s_wready(s_wready[0]),
    .s_bresp(s_bresp[1:0]), .s_bvalid(s_bvalid[0]), .s_bready(s_bready[0]),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid[0]), .s_arready(s_arready[0]),
    .s_rdata(s_rdata[31:0]), .s_rresp(s_rresp[1:0]), .s_rvalid(s_rvalid[0]), .s_rready(s_rready[0]));
  sram #(.WORDS(SRAM_WORDS)) u_sram (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[1]), .s_awready(s_awready[1]),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[1]), .s_wready(s_wready[1]),
    .s_bresp(s_bresp[3:2]), .s_bvalid(s_bvalid[1]), .s_bready(s_bready[1]),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid[1]), .s_arready(s_arready[1]),
    .s_rdata(s_rdata[63:32]), .s_rresp(s_rresp[3:2]), .s_rvalid(s_rvalid[1]), .s_rready(s_rready[1]));
  uart_axi u_uart (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[2]), .s_awready(s_awready[2]),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[2]), .s_wready(s_wready[2]),
    .s_bresp(s_bresp[5:4]), .s_bvalid(s_bvalid[2]), .s_bready(s_bready[2]),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid[2]), .s_arready(s_arready[2]),
    .s_rdata(s_rdata[95:64]), .s_rresp(s_rresp[5:4]), .s_rvalid(s_rvalid[2]), .s_rready(s_rready[2]),
    .tx_pin(uart_tx), .rx_pin(rx_s));
endmodule
