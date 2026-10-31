// Word-organised flop SRAM with byte strobes (swap for a sky130 SRAM macro later).
module sram #(parameter WORDS = 256) (
  input  clk, input rst_n,
  input  [31:0] s_awaddr, input s_awvalid, output s_awready,
  input  [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output s_bvalid, input s_bready,
  input  [31:0] s_araddr, input s_arvalid, output s_arready,
  output [31:0] s_rdata, output [1:0] s_rresp, output s_rvalid, input s_rready
);
  localparam AB = $clog2(WORDS);
  reg [31:0] mem [0:WORDS-1];
  wire we; wire [31:0] wa, wd, ra; wire [3:0] ws;
  axil_reg_if u_if (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .reg_we(we), .reg_wa(wa), .reg_wd(wd), .reg_ws(ws), .reg_re(), .reg_ra(ra),
    .reg_rd(mem[ra[2 +: AB]]));
  always @(posedge clk)
    if (we) begin
      if (ws[0]) mem[wa[2 +: AB]][ 7: 0] <= wd[ 7: 0];
      if (ws[1]) mem[wa[2 +: AB]][15: 8] <= wd[15: 8];
      if (ws[2]) mem[wa[2 +: AB]][23:16] <= wd[23:16];
      if (ws[3]) mem[wa[2 +: AB]][31:24] <= wd[31:24];
    end
endmodule
