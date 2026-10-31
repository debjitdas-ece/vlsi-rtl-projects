// 8N1 UART receiver, mid-bit sampling. Input must already be synchronized (sync2).
module uart_rx (
  input clk, input rst_n, input [15:0] div, input rx,
  output reg [7:0] dout, output reg dv, output reg ferr
);
  localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
  reg [1:0] st; reg [15:0] cc; reg [2:0] bi; reg [7:0] sh;
  wire [15:0] dm1  = (div == 16'd0) ? 16'd0 : div - 16'd1;
  wire [15:0] hm1  = {1'b0, div[15:1]} - 16'd1;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin st <= IDLE; cc <= 16'd0; bi <= 3'd0; sh <= 8'd0; dout <= 8'd0; dv <= 1'b0; ferr <= 1'b0; end
    else begin
      dv <= 1'b0;
      case (st)
        IDLE:  begin cc <= 16'd0; bi <= 3'd0; st <= rx ? IDLE : START; end
        START: begin
                 if (cc == hm1) begin cc <= 16'd0; st <= rx ? IDLE : DATA; end   // glitch reject
                 else cc <= cc + 16'd1;
               end
        DATA:  begin
                 if (cc == dm1) begin
                   cc <= 16'd0; sh <= {rx, sh[7:1]}; bi <= bi + 3'd1;
                   st <= (bi == 3'd7) ? STOP : DATA;
                 end else cc <= cc + 16'd1;
               end
        STOP:  begin
                 if (cc == dm1) begin dout <= sh; dv <= 1'b1; ferr <= ~rx; cc <= 16'd0; st <= IDLE; end
                 else cc <= cc + 16'd1;
               end
      endcase
    end
endmodule
