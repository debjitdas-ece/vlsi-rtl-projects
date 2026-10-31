// Reset synchronizer: asynchronous assert, synchronous de-assert (Module 2: RDC).
module rst_sync (
  input  clk,
  input  arst,     // active-high asynchronous board reset
  output rst_n     // active-low, de-asserted synchronously to clk
);
  reg [1:0] r;
  always @(posedge clk or posedge arst)
    if (arst) r <= 2'b00;
    else      r <= {r[0], 1'b1};
  assign rst_n = r[1];
endmodule
