// PicoRV32 native memory interface -> AXI4-Lite master FSM (one outstanding transaction).
// b_state: 0 IDLE, 1 WR (AW+W+B), 3 RD_AR, 4 RD_R  (matches the Module 6 waveform labs)
module axi_bridge (
  input clk, input rst_n,
  input  mem_valid, output mem_ready, input [31:0] mem_addr, input [31:0] mem_wdata,
  input  [3:0] mem_wstrb, output [31:0] mem_rdata,
  output [31:0] m_awaddr, output m_awvalid, input m_awready,
  output [31:0] m_wdata, output [3:0] m_wstrb, output m_wvalid, input m_wready,
  input  [1:0] m_bresp, input m_bvalid, output m_bready,
  output [31:0] m_araddr, output m_arvalid, input m_arready,
  input  [31:0] m_rdata, input [1:0] m_rresp, input m_rvalid, output m_rready,
  output err_p          // 1-cycle pulse on SLVERR/DECERR response
);
  localparam ST_IDLE = 3'd0, ST_WR_AW = 3'd1, ST_RD_AR = 3'd3, ST_RD_R = 3'd4;
  reg [2:0] b_state;
  reg aw_d, w_d;
  assign m_awaddr  = mem_addr;   assign m_araddr = mem_addr;
  assign m_wdata   = mem_wdata;  assign m_wstrb  = mem_wstrb;
  assign m_awvalid = (b_state == ST_WR_AW) & ~aw_d;
  assign m_wvalid  = (b_state == ST_WR_AW) & ~w_d;
  assign m_bready  = (b_state == ST_WR_AW);
  assign m_arvalid = (b_state == ST_RD_AR);
  assign m_rready  = (b_state == ST_RD_R);
  assign mem_ready = ((b_state == ST_WR_AW) & m_bvalid) | ((b_state == ST_RD_R) & m_rvalid);
  assign mem_rdata = m_rdata;
  assign err_p = (((b_state == ST_WR_AW) & m_bvalid & (m_bresp != 2'b00)) |
                  ((b_state == ST_RD_R)  & m_rvalid & (m_rresp != 2'b00)));
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin b_state <= ST_IDLE; aw_d <= 1'b0; w_d <= 1'b0; end
    else case (b_state)
      ST_IDLE:  begin aw_d <= 1'b0; w_d <= 1'b0;
                      b_state <= !mem_valid ? ST_IDLE : (|mem_wstrb ? ST_WR_AW : ST_RD_AR); end
      ST_WR_AW: begin aw_d <= aw_d | (m_awvalid & m_awready);
                      w_d  <= w_d  | (m_wvalid  & m_wready);
                      b_state <= m_bvalid ? ST_IDLE : ST_WR_AW; end
      ST_RD_AR: b_state <= m_arready ? ST_RD_R : ST_RD_AR;
      ST_RD_R:  b_state <= m_rvalid  ? ST_IDLE : ST_RD_R;
      default:  b_state <= ST_IDLE;
    endcase
endmodule
