// AXI4-Lite UART slave (TX + RX) with TX back-pressure (AWREADY/WREADY low while buf_valid).
//   0x0 TX      (W)  transmit byte           0x4 RX     (R) received byte, clears rx_buf_valid
//   0x8 STATUS  (R)  b0 tx_busy b1 rx_buf_valid b2 rx_overrun b3 frame_err
//   0xC BAUDDIV (RW) bit period in clocks (reset: 434 = 115200 baud @ 50 MHz)
module uart_axi #(parameter [15:0] DIV0 = 16'd434) (
  input clk, input rst_n,
  input  [31:0] s_awaddr, input s_awvalid, output s_awready,
  input  [31:0] s_wdata, input [3:0] s_wstrb, input s_wvalid, output s_wready,
  output [1:0] s_bresp, output reg s_bvalid, input s_bready,
  input  [31:0] s_araddr, input s_arvalid, output s_arready,
  output reg [31:0] s_rdata, output [1:0] s_rresp, output reg s_rvalid, input s_rready,
  output tx_pin, input rx_pin
);
  reg [15:0] div; reg [7:0] tx_byte; reg buf_valid, aw_got, w_got; reg [1:0] aw_a; reg [31:0] w_d; reg [3:0] w_s;
  wire tx_busy; wire tx_start = buf_valid & ~tx_busy;
  assign s_bresp = 2'b00; assign s_rresp = 2'b00;
  assign s_awready = ~aw_got & ~s_bvalid & ~buf_valid;
  assign s_wready  = ~w_got  & ~s_bvalid & ~buf_valid;

  uart_tx u_tx (.clk(clk), .rst_n(rst_n), .div(div), .start(tx_start), .din(tx_byte), .tx(tx_pin), .busy(tx_busy));
  wire [7:0] rx_d; wire rx_dv, rx_fe;
  uart_rx u_rx (.clk(clk), .rst_n(rst_n), .div(div), .rx(rx_pin), .dout(rx_d), .dv(rx_dv), .ferr(rx_fe));

  reg [7:0] rx_buf; reg rx_buf_valid, rx_ovr, rx_ferr;
  wire [31:0] status = {28'b0, rx_ferr, rx_ovr, rx_buf_valid, (buf_valid | tx_busy)};
  wire do_wr = aw_got & w_got & ~s_bvalid;
  wire arhs  = s_arvalid & s_arready;
  assign s_arready = ~s_rvalid;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      div <= DIV0; tx_byte <= 8'd0; buf_valid <= 1'b0; aw_got <= 1'b0; w_got <= 1'b0; aw_a <= 2'd0; w_d <= 32'd0; w_s <= 4'd0;
      s_bvalid <= 1'b0; s_rvalid <= 1'b0; s_rdata <= 32'd0;
      rx_buf <= 8'd0; rx_buf_valid <= 1'b0; rx_ovr <= 1'b0; rx_ferr <= 1'b0;
    end else begin
      // ---- write path
      if (s_awvalid & s_awready) begin aw_got <= 1'b1; aw_a <= s_awaddr[3:2]; end
      if (s_wvalid  & s_wready)  begin w_got  <= 1'b1; w_d <= s_wdata; w_s <= s_wstrb; end
      if (tx_start) buf_valid <= 1'b0;
      if (do_wr) begin
        aw_got <= 1'b0; w_got <= 1'b0; s_bvalid <= 1'b1;
        if (aw_a == 2'd0 && w_s[0]) begin tx_byte <= w_d[7:0]; buf_valid <= 1'b1; end
        if (aw_a == 2'd3)           div <= (w_d[15:0] < 16'd4) ? 16'd4 : w_d[15:0];
      end else if (s_bready) s_bvalid <= 1'b0;
      // ---- read path
      if (arhs) begin
        s_rvalid <= 1'b1;
        s_rdata  <= (s_araddr[3:2] == 2'd1) ? {24'b0, rx_buf} :
                    (s_araddr[3:2] == 2'd2) ? status :
                    (s_araddr[3:2] == 2'd3) ? {16'b0, div} : 32'd0;
        if (s_araddr[3:2] == 2'd1) begin rx_buf_valid <= 1'b0; rx_ovr <= 1'b0; rx_ferr <= 1'b0; end
      end else if (s_rready) s_rvalid <= 1'b0;
      // ---- RX capture (later assignment wins over clear-on-read)
      if (rx_dv) begin rx_buf <= rx_d; rx_buf_valid <= 1'b1; rx_ovr <= rx_buf_valid; rx_ferr <= rx_fe; end
    end
endmodule
