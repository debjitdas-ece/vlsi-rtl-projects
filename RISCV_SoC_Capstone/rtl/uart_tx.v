// 8N1 UART transmitter. Bit period = div clocks (434 @ 50 MHz = 115200 baud).
module uart_tx (
  input clk, input rst_n, input [15:0] div,
  input start, input [7:0] din,
  output reg tx, output busy
);
  localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
  reg [1:0] st; reg [15:0] cc; reg [2:0] bi; reg [7:0] sh;
  wire [15:0] dm1  = (div == 16'd0) ? 16'd0 : div - 16'd1;
  wire        tick = (cc == dm1);
  assign busy = (st != IDLE);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin st <= IDLE; cc <= 16'd0; bi <= 3'd0; sh <= 8'd0; tx <= 1'b1; end
    else case (st)
      IDLE:  begin tx <= start ? 1'b0 : 1'b1; cc <= 16'd0; bi <= 3'd0;
                   sh <= start ? din : sh; st <= start ? START : IDLE; end
      START: begin cc <= tick ? 16'd0 : cc + 16'd1;
                   if (tick) begin tx <= sh[0]; sh <= {1'b0, sh[7:1]}; bi <= 3'd0; st <= DATA; end end
      DATA:  begin cc <= tick ? 16'd0 : cc + 16'd1;
                   if (tick) begin
                     if (bi == 3'd7) begin tx <= 1'b1; st <= STOP; end
                     else begin tx <= sh[0]; sh <= {1'b0, sh[7:1]}; bi <= bi + 3'd1; end
                   end end
      STOP:  begin cc <= tick ? 16'd0 : cc + 16'd1; st <= tick ? IDLE : STOP; end
    endcase
endmodule
