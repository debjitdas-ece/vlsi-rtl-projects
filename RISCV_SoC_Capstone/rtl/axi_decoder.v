// One-hot address decoder. Windows match the REAL memory sizes, so out-of-range accesses select
// nothing and the interconnect's default responder returns DECERR (no silent wrap-around aliasing).
//   ROM  0x0000_0000 .. ROM_BYTES-1      SRAM 0x0001_0000 .. 0x0001_0000+SRAM_BYTES-1
module axi_decoder #(parameter PLUS = 0, parameter ROM_BYTES = 4096, parameter SRAM_BYTES = 1024) (
  input  [31:0] addr,
  output reg [4:0] sel   // [0]=ROM [1]=SRAM [2]=UART [3]=PWM [4]=GPIO
);
  localparam [15:0] ROM_LIM  = ROM_BYTES[15:0];    // both windows are < 64 KB
  localparam [15:0] SRAM_LIM = SRAM_BYTES[15:0];
  always @* begin
    sel = 5'b00000;
    if      (addr[31:16] == 16'h0000 && addr[15:0] < ROM_LIM)  sel = 5'b00001;  // ROM
    else if (addr[31:16] == 16'h0001 && addr[15:0] < SRAM_LIM) sel = 5'b00010;  // SRAM
    else if (addr[31:4]  == 28'h1000000)                               sel = 5'b00100;  // UART
    else if (PLUS && addr[31:12] == 20'h20000)                         sel = 5'b01000;  // PWM
    else if (PLUS && addr[31:4]  == 28'h3000000)                       sel = 5'b10000;  // GPIO
  end
endmodule
