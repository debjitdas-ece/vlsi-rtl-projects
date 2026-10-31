// 1-master / 5-slave AXI4-Lite interconnect with default (DECERR) responder.
// Address/data are broadcast; valids are gated by the one-hot select; responses are muxed.
module axi_lite_interconnect #(parameter PLUS = 0, parameter ROM_BYTES = 4096, parameter SRAM_BYTES = 1024) (
  input clk, input rst_n,
  // master side
  input  [31:0] m_awaddr, input m_awvalid, output m_awready,
  input  [31:0] m_wdata, input [3:0] m_wstrb, input m_wvalid, output m_wready,
  output [1:0] m_bresp, output m_bvalid, input m_bready,
  input  [31:0] m_araddr, input m_arvalid, output m_arready,
  output [31:0] m_rdata, output [1:0] m_rresp, output m_rvalid, input m_rready,
  // slave side (broadcast)
  output [31:0] s_awaddr, output [31:0] s_wdata, output [3:0] s_wstrb, output [31:0] s_araddr,
  // slave side (per slave)
  output [4:0] s_awvalid, input [4:0] s_awready,
  output [4:0] s_wvalid,  input [4:0] s_wready,
  input  [9:0] s_bresp,   input [4:0] s_bvalid, output [4:0] s_bready,
  output [4:0] s_arvalid, input [4:0] s_arready,
  input  [159:0] s_rdata, input [9:0] s_rresp, input [4:0] s_rvalid, output [4:0] s_rready
);
  wire [4:0] wr_sel, rd_sel;
  axi_decoder #(.PLUS(PLUS), .ROM_BYTES(ROM_BYTES), .SRAM_BYTES(SRAM_BYTES)) u_dec_w (.addr(m_awaddr), .sel(wr_sel));
  axi_decoder #(.PLUS(PLUS), .ROM_BYTES(ROM_BYTES), .SRAM_BYTES(SRAM_BYTES)) u_dec_r (.addr(m_araddr), .sel(rd_sel));

  assign s_awaddr = m_awaddr;  assign s_wdata = m_wdata;
  assign s_wstrb  = m_wstrb;   assign s_araddr = m_araddr;
  assign s_awvalid = {5{m_awvalid}} & wr_sel;
  assign s_wvalid  = {5{m_wvalid}}  & wr_sel;
  assign s_bready  = {5{m_bready}}  & wr_sel;
  assign s_arvalid = {5{m_arvalid}} & rd_sel;
  assign s_rready  = {5{m_rready}}  & rd_sel;

  // default responder (unmapped address)
  wire wr_none = (wr_sel == 5'b0);
  wire rd_none = (rd_sel == 5'b0);
  reg  dbv, drv;
  wire dwacc = wr_none & m_awvalid & m_wvalid & ~dbv;
  wire dracc = rd_none & m_arvalid & ~drv;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin dbv <= 1'b0; drv <= 1'b0; end
    else begin
      dbv <= dwacc ? 1'b1 : (m_bready ? 1'b0 : dbv);
      drv <= dracc ? 1'b1 : (m_rready ? 1'b0 : drv);
    end

  integer i;
  reg [31:0] rd_mux; reg [1:0] rr_mux, br_mux;
  always @* begin
    rd_mux = 32'b0; rr_mux = 2'b0; br_mux = 2'b0;
    for (i = 0; i < 5; i = i + 1) begin
      rd_mux = rd_mux | (rd_sel[i] ? s_rdata[32*i +: 32] : 32'b0);
      rr_mux = rr_mux | (rd_sel[i] ? s_rresp[2*i +: 2]   : 2'b0);
      br_mux = br_mux | (wr_sel[i] ? s_bresp[2*i +: 2]   : 2'b0);
    end
  end
  assign m_awready = (|(wr_sel & s_awready)) | dwacc;
  assign m_wready  = (|(wr_sel & s_wready))  | dwacc;
  assign m_bvalid  = (|(wr_sel & s_bvalid))  | dbv;
  assign m_bresp   = wr_none ? 2'b11 : (wr_sel[0] ? 2'b10 : br_mux);   // DECERR unmapped, SLVERR write-to-ROM
  assign m_arready = (|(rd_sel & s_arready)) | dracc;
  assign m_rvalid  = (|(rd_sel & s_rvalid))  | drv;
  assign m_rdata   = rd_none ? 32'hDEAD_BEEF : rd_mux;
  assign m_rresp   = rd_none ? 2'b11 : rr_mux;
endmodule
