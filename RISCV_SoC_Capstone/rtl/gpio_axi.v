// AXI4-Lite GPIO @0x3000_0000: 0x0 OUT[7:0] (RW), 0x4 IN[7:0] (RO, pre-synchronized), 0x8 STATUS b0 bus_err (sticky, write clears)
module gpio_axi (
  input clk, input rst_n,
  input  [31:0] s_awaddr, input s_awvalid, output s_awready,
  input  [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output s_bvalid, input s_bready,
  input  [31:0] s_araddr, input s_arvalid, output s_arready,
  output [31:0] s_rdata, output [1:0] s_rresp, output s_rvalid, input s_rready,
  input [7:0] gpio_in, output reg [7:0] gpio_out, input bus_err_p
);
  wire we; wire [31:0] wa, wd, ra; wire [3:0] ws; reg [31:0] rd; reg berr;
  axil_reg_if u_if (.clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .reg_we(we), .reg_wa(wa), .reg_wd(wd), .reg_ws(ws), .reg_re(), .reg_ra(ra), .reg_rd(rd));
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin gpio_out <= 8'd0; berr <= 1'b0; end
    else begin
      gpio_out <= (we & (wa[3:2] == 2'd0)) ? wd[7:0] : gpio_out;
      berr     <= bus_err_p ? 1'b1 : (we & (wa[3:2] == 2'd2)) ? 1'b0 : berr;
    end
  always @* rd = (ra[3:2] == 2'd0) ? {24'd0, gpio_out} : (ra[3:2] == 2'd1) ? {24'd0, gpio_in} :
                 (ra[3:2] == 2'd2) ? {31'd0, berr} : 32'd0;
endmodule
