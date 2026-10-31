// 2-FF synchronizer for asynchronous inputs (Module 2: CDC). RV = reset/idle value.
module sync2 #(parameter W = 1, parameter [W-1:0] RV = {W{1'b0}}) (
  input  clk,
  input  rst_n,
  input  [W-1:0] d,
  output [W-1:0] q
);
  reg [W-1:0] m, s;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin m <= RV; s <= RV; end
    else        begin m <= d;  s <= m;  end
  assign q = s;
endmodule
