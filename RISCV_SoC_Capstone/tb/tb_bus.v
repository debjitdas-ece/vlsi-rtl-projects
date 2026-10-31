`timescale 1ns/1ps
`ifndef SRAM_WORDS_DEF
`define SRAM_WORDS_DEF 256
`endif
// Bus-level self-checking test: AXI4-Lite master model -> interconnect -> real ROM + real SRAM + 3 stub slaves.
// Part 1: directed checks (memory-map edges, aliasing, byte strobes, DECERR/SLVERR).
// Part 2: constrained-random traffic checked against a reference model.
// The master drives 1 ns after each posedge and samples at negedge (mid-cycle): no simulator race.
module stub_slave #(parameter [31:0] ID = 0) (
  input clk, input rst_n,
  input [31:0] s_awaddr, input s_awvalid, output s_awready,
  input [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output s_bvalid, input s_bready,
  input [31:0] s_araddr, input s_arvalid, output s_arready,
  output [31:0] s_rdata, output [1:0] s_rresp, output s_rvalid, input s_rready);
  axil_reg_if u_if (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .reg_we(), .reg_wa(), .reg_wd(), .reg_ws(), .reg_re(), .reg_ra(), .reg_rd(32'hA5A5_0000 | ID));
endmodule

module tb_bus;
  localparam SW = `SRAM_WORDS_DEF, SRAM_BYTES = SW*4, ROM_WORDS = 1024, ROM_BYTES = ROM_WORDS*4;
  reg clk = 0, rst_n = 0; always #10 clk = ~clk;

  // master side
  reg  [31:0] awaddr = 32'hFFFF_FFF0, wdata = 0, araddr = 32'hFFFF_FFF0; reg [3:0] wstrb = 0;   // idle on an unmapped address (also kicks always @* at t=0)
  reg  awvalid = 0, wvalid = 0, bready = 0, arvalid = 0, rready = 0;
  wire awready, wready, bvalid, arready, rvalid; wire [1:0] bresp, rresp; wire [31:0] rdata;
  // slave side
  wire [31:0] s_awaddr, s_wdata, s_araddr; wire [3:0] s_wstrb;
  wire [4:0] s_awvalid, s_awready, s_wvalid, s_wready, s_bvalid, s_bready, s_arvalid, s_arready, s_rvalid, s_rready;
  wire [9:0] s_bresp, s_rresp; wire [159:0] s_rdata;

  axi_lite_interconnect #(.PLUS(1), .ROM_BYTES(ROM_BYTES), .SRAM_BYTES(SRAM_BYTES)) u_ic (.clk(clk), .rst_n(rst_n),
    .m_awaddr(awaddr), .m_awvalid(awvalid), .m_awready(awready),
    .m_wdata(wdata), .m_wstrb(wstrb), .m_wvalid(wvalid), .m_wready(wready),
    .m_bresp(bresp), .m_bvalid(bvalid), .m_bready(bready),
    .m_araddr(araddr), .m_arvalid(arvalid), .m_arready(arready),
    .m_rdata(rdata), .m_rresp(rresp), .m_rvalid(rvalid), .m_rready(rready),
    .s_awaddr(s_awaddr), .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_araddr(s_araddr),
    .s_awvalid(s_awvalid), .s_awready(s_awready), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready));

  rom  #(.WORDS(ROM_WORDS)) u_rom (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[0]), .s_awready(s_awready[0]),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[0]), .s_wready(s_wready[0]),
    .s_bresp(s_bresp[1:0]), .s_bvalid(s_bvalid[0]), .s_bready(s_bready[0]),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid[0]), .s_arready(s_arready[0]),
    .s_rdata(s_rdata[31:0]), .s_rresp(s_rresp[1:0]), .s_rvalid(s_rvalid[0]), .s_rready(s_rready[0]));
  sram #(.WORDS(SW)) u_sram (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[1]), .s_awready(s_awready[1]),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[1]), .s_wready(s_wready[1]),
    .s_bresp(s_bresp[3:2]), .s_bvalid(s_bvalid[1]), .s_bready(s_bready[1]),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid[1]), .s_arready(s_arready[1]),
    .s_rdata(s_rdata[63:32]), .s_rresp(s_rresp[3:2]), .s_rvalid(s_rvalid[1]), .s_rready(s_rready[1]));
  genvar g;
  generate for (g = 2; g < 5; g = g + 1) begin : stubs
    stub_slave #(.ID(g)) u (.clk(clk), .rst_n(rst_n),
      .s_awaddr(s_awaddr), .s_awvalid(s_awvalid[g]), .s_awready(s_awready[g]),
      .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid[g]), .s_wready(s_wready[g]),
      .s_bresp(s_bresp[2*g +: 2]), .s_bvalid(s_bvalid[g]), .s_bready(s_bready[g]),
      .s_araddr(s_araddr), .s_arvalid(s_arvalid[g]), .s_arready(s_arready[g]),
      .s_rdata(s_rdata[32*g +: 32]), .s_rresp(s_rresp[2*g +: 2]), .s_rvalid(s_rvalid[g]), .s_rready(s_rready[g]));
  end endgenerate

  // ---- protocol checkers: CPU-side bus, ROM port, SRAM port ----
  axil_checker #(.NAME("master")) c_m (.clk(clk), .rst_n(rst_n),
    .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb),
    .bvalid(bvalid), .bready(bready), .bresp(bresp), .arvalid(arvalid), .arready(arready), .araddr(araddr),
    .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp));
  axil_checker #(.NAME("rom")) c_r (.clk(clk), .rst_n(rst_n),
    .awvalid(s_awvalid[0]), .awready(s_awready[0]), .awaddr(s_awaddr), .wvalid(s_wvalid[0]), .wready(s_wready[0]), .wdata(s_wdata), .wstrb(s_wstrb),
    .bvalid(s_bvalid[0]), .bready(s_bready[0]), .bresp(s_bresp[1:0]), .arvalid(s_arvalid[0]), .arready(s_arready[0]), .araddr(s_araddr),
    .rvalid(s_rvalid[0]), .rready(s_rready[0]), .rdata(s_rdata[31:0]), .rresp(s_rresp[1:0]));
  axil_checker #(.NAME("sram")) c_s (.clk(clk), .rst_n(rst_n),
    .awvalid(s_awvalid[1]), .awready(s_awready[1]), .awaddr(s_awaddr), .wvalid(s_wvalid[1]), .wready(s_wready[1]), .wdata(s_wdata), .wstrb(s_wstrb),
    .bvalid(s_bvalid[1]), .bready(s_bready[1]), .bresp(s_bresp[3:2]), .arvalid(s_arvalid[1]), .arready(s_arready[1]), .araddr(s_araddr),
    .rvalid(s_rvalid[1]), .rready(s_rready[1]), .rdata(s_rdata[63:32]), .rresp(s_rresp[3:2]));

  // ---- master tasks ----
  task axi_write(input [31:0] a, input [31:0] d, input [3:0] s, output [1:0] resp);
    reg hs_aw, hs_w, got_aw, got_w, done; begin
    @(posedge clk); #1; awaddr = a; wdata = d; wstrb = s; awvalid = 1; wvalid = 1; bready = 1;
    got_aw = 0; got_w = 0;
    while (!(got_aw && got_w)) begin
      @(negedge clk); hs_aw = awvalid & awready; hs_w = wvalid & wready;
      @(posedge clk); #1;
      if (hs_aw) begin awvalid = 0; got_aw = 1; end
      if (hs_w)  begin wvalid  = 0; got_w  = 1; end
    end
    done = 0;
    while (!done) begin
      @(negedge clk);
      if (bvalid) begin resp = bresp; done = 1; end
      @(posedge clk); #1;
    end
    bready = 0;
  end endtask
  task axi_read(input [31:0] a, output [31:0] d, output [1:0] resp);
    reg hs, done; begin
    @(posedge clk); #1; araddr = a; arvalid = 1; rready = 1; hs = 0;
    while (!hs) begin
      @(negedge clk); hs = arvalid & arready;
      @(posedge clk); #1;
    end
    arvalid = 0; done = 0;
    while (!done) begin
      @(negedge clk);
      if (rvalid) begin d = rdata; resp = rresp; done = 1; end
      @(posedge clk); #1;
    end
    rready = 0;
  end endtask

  // ---- reference model ----
  reg [31:0] rom_model [0:ROM_WORDS-1];
  reg [31:0] sram_model [0:SW-1];
  integer errors = 0, checks = 0, i, n;
  localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10, DECERR = 2'b11;
  function [31:0] rom_pat(input integer k); rom_pat = (k * 32'h9E37_79B1) ^ 32'hC0DE_0000; endfunction
  function [31:0] mask_of(input [3:0] s); mask_of = {{8{s[3]}}, {8{s[2]}}, {8{s[1]}}, {8{s[0]}}}; endfunction
  // region: 0 ROM, 1 SRAM, 2 UART, 3 PWM, 4 GPIO, 5 unmapped
  function integer region(input [31:0] a); begin
    region = 5;
    if      (a[31:16] == 16'h0000 && a[15:0] < ROM_BYTES)  region = 0;
    else if (a[31:16] == 16'h0001 && a[15:0] < SRAM_BYTES) region = 1;
    else if (a[31:4]  == 28'h1000000) region = 2;
    else if (a[31:12] == 20'h20000)   region = 3;
    else if (a[31:4]  == 28'h3000000) region = 4;
  end endfunction

  reg [31:0] rd; reg [1:0] rr, wr_r; reg [31:0] exp_d; reg [1:0] exp_r;
  task chk(input cond, input [8*24-1:0] what, input [31:0] a); begin
    checks = checks + 1;
    if (!cond) begin errors = errors + 1; if (errors <= 20) $display("[TB_BUS] FAIL %0s addr=%h rd=%h rresp=%b bresp=%b", what, a, rd, rr, wr_r); end
  end endtask

  // checked read / write against the model
  task rd_chk(input [31:0] a); integer r; begin
    axi_read(a, rd, rr); r = region(a);
    case (r)
      0: begin exp_d = rom_model[a[11:2]]; exp_r = OKAY; end
      1: begin exp_d = sram_model[a[2 +: $clog2(SW)]]; exp_r = OKAY; end
      2,3,4: begin exp_d = 32'hA5A5_0000 | r; exp_r = OKAY; end
      default: begin exp_d = 32'hDEAD_BEEF; exp_r = DECERR; end
    endcase
    chk(rr === exp_r, "read resp", a);
    chk(rd === exp_d, "read data", a);
  end endtask
  task wr_chk(input [31:0] a, input [31:0] d, input [3:0] s); integer r; begin
    axi_write(a, d, s, wr_r); r = region(a);
    case (r)
      0: exp_r = SLVERR;
      1: begin exp_r = OKAY; sram_model[a[2 +: $clog2(SW)]] = (sram_model[a[2 +: $clog2(SW)]] & ~mask_of(s)) | (d & mask_of(s)); end
      2,3,4: exp_r = OKAY;
      default: exp_r = DECERR;
    endcase
    chk(wr_r === exp_r, "write resp", a);
  end endtask

  integer seed = 32'h1234_5678;
  reg [31:0] ra, rv; reg [3:0] rs;
  initial begin
    for (i = 0; i < ROM_WORDS; i = i + 1) begin u_rom.mem[i] = rom_pat(i); rom_model[i] = rom_pat(i); end
    for (i = 0; i < SW; i = i + 1) begin u_sram.mem[i] = 32'h0; sram_model[i] = 32'h0; end
    repeat (5) @(posedge clk); #1; rst_n = 1; repeat (2) @(posedge clk);

    $display("[TB_BUS] directed checks (SRAM = %0d bytes, ROM = %0d bytes)", SRAM_BYTES, ROM_BYTES);
    // ROM: first / middle / last word readable, first word past the end is DECERR (no wrap-around)
    rd_chk(32'h0000_0000); rd_chk(32'h0000_0004); rd_chk(32'h0000_07FC); rd_chk(ROM_BYTES-4);
    rd_chk(ROM_BYTES);   rd_chk(ROM_BYTES+4); rd_chk(32'h0000_8000); rd_chk(32'h0000_FFFC);
    // ROM write must be rejected with SLVERR and leave contents untouched
    wr_chk(32'h0000_0000, 32'hFFFF_FFFF, 4'hF); wr_chk(ROM_BYTES-4, 32'h1234_5678, 4'hF);
    rd_chk(32'h0000_0000); rd_chk(ROM_BYTES-4);
    // SRAM: edges
    wr_chk(32'h0001_0000, 32'h1111_1111, 4'hF); wr_chk(32'h0001_0000 + SRAM_BYTES - 4, 32'h2222_2222, 4'hF);
    rd_chk(32'h0001_0000); rd_chk(32'h0001_0000 + SRAM_BYTES - 4);
    // SRAM: first word past the end must NOT alias word 0 and must be DECERR
    wr_chk(32'h0001_0000 + SRAM_BYTES, 32'hBAD0_BAD0, 4'hF);
    rd_chk(32'h0001_0000 + SRAM_BYTES); rd_chk(32'h0001_0000); rd_chk(32'h0001_0000 + 2*SRAM_BYTES);
    rd_chk(32'h0001_FFFC); wr_chk(32'h0001_FFFC, 32'h5, 4'hF);
    // SRAM: all 16 byte-strobe patterns on word 1
    wr_chk(32'h0001_0004, 32'h0, 4'hF);
    for (i = 0; i < 16; i = i + 1) begin wr_chk(32'h0001_0004, {8'hA0 + i[7:0], 8'hB0 + i[7:0], 8'hC0 + i[7:0], 8'hD0 + i[7:0]}, i[3:0]); rd_chk(32'h0001_0004); end
    // peripherals: stub slaves respond OKAY with their ID; just outside each window -> DECERR
    rd_chk(32'h1000_0000); rd_chk(32'h1000_000C); rd_chk(32'h1000_0010);
    rd_chk(32'h2000_0000); rd_chk(32'h2000_0FFC); rd_chk(32'h2000_1000);
    rd_chk(32'h3000_0000); rd_chk(32'h3000_000C); rd_chk(32'h3000_0010);
    wr_chk(32'h1000_0000, 32'h55, 4'h1); wr_chk(32'h2000_0020, 32'h55, 4'hF); wr_chk(32'h3000_0000, 32'h55, 4'h1);
    wr_chk(32'h1000_0010, 32'h55, 4'h1); wr_chk(32'h2000_1000, 32'h55, 4'hF); wr_chk(32'h3000_0010, 32'h55, 4'h1);
    // unmapped
    rd_chk(32'h0800_0000); rd_chk(32'h4000_0000); rd_chk(32'hFFFF_FFFC); wr_chk(32'h8000_0000, 32'h1, 4'hF);
    $display("[TB_BUS] directed: %0d checks, %0d errors so far", checks, errors);

    $display("[TB_BUS] random traffic: 3000 operations");
    for (n = 0; n < 3000; n = n + 1) begin
      case ($urandom(seed) % 8)
        0: ra = {$urandom % ROM_WORDS, 2'b00};                            // ROM
        1,2,3: ra = 32'h0001_0000 + ({$urandom, 2'b00} % (SRAM_BYTES));    // SRAM in range
        4: ra = 32'h0001_0000 + SRAM_BYTES + ({$urandom, 2'b00} % 4096);   // just past SRAM
        5: ra = {4'h1 + 4'($urandom % 3), 24'h0, 2'($urandom % 8), 2'b00};  // peripheral regs and nearby
        6: ra = ROM_BYTES + ({$urandom, 2'b00} % 4096);                     // just past ROM
        default: ra = {$urandom, 2'b00};                                    // anywhere
      endcase
      ra[1:0] = 2'b00; rv = $urandom; rs = $urandom;
      if ($urandom % 2) wr_chk(ra, rv, rs); else rd_chk(ra);
    end
    // final sweep: every SRAM word must match the model
    for (i = 0; i < SW; i = i + 1) begin axi_read(32'h0001_0000 + 4*i, rd, rr); chk(rd === sram_model[i], "sram final sweep", 32'h0001_0000 + 4*i); end
    for (i = 0; i < ROM_WORDS; i = i + 1) begin axi_read(4*i, rd, rr); chk(rd === rom_model[i], "rom final sweep", 4*i); end

    $display("[TB_BUS] %0d checks, %0d data errors, protocol violations: master=%0d rom=%0d sram=%0d",
             checks, errors, c_m.viol, c_r.viol, c_s.viol);
    if (errors == 0 && c_m.viol == 0 && c_r.viol == 0 && c_s.viol == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
  initial begin #50_000_000; $display("[TB_BUS] GLOBAL TIMEOUT"); $display("TEST FAILED"); $finish; end
endmodule
