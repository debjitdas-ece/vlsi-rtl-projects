// Generic AXI4-Lite slave -> single-cycle register bus adapter.
// Waits for AW and W together (legal for a slave), responds OKAY.
// Used by ROM, SRAM, GPIO and PWM. UART has its own slave (TX back-pressure).
module axil_reg_if #(parameter AW = 32) (
  input  clk, input rst_n,
  input  [AW-1:0] s_awaddr, input s_awvalid, output s_awready,
  input  [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output reg s_bvalid, input s_bready,
  input  [AW-1:0] s_araddr, input s_arvalid, output s_arready,
  output reg [31:0] s_rdata, output [1:0] s_rresp, output reg s_rvalid, input s_rready,
  output reg_we, output [AW-1:0] reg_wa, output [31:0] reg_wd, output [3:0] reg_ws,
  output reg_re, output [AW-1:0] reg_ra, input [31:0] reg_rd
);
  wire wacc = s_awvalid & s_wvalid & ~s_bvalid;
  wire racc = s_arvalid & ~s_rvalid;
  assign s_awready = wacc;
  assign s_wready  = wacc;
  assign s_arready = racc;
  assign s_bresp   = 2'b00;
  assign s_rresp   = 2'b00;
  assign reg_we = wacc;  assign reg_wa = s_awaddr; assign reg_wd = s_wdata; assign reg_ws = s_wstrb;
  assign reg_re = racc;  assign reg_ra = s_araddr;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin s_bvalid <= 1'b0; s_rvalid <= 1'b0; s_rdata <= 32'b0; end
    else begin
      s_bvalid <= wacc ? 1'b1 : (s_bready ? 1'b0 : s_bvalid);
      s_rvalid <= racc ? 1'b1 : (s_rready ? 1'b0 : s_rvalid);
      s_rdata  <= racc ? reg_rd : s_rdata;
    end
endmodule
