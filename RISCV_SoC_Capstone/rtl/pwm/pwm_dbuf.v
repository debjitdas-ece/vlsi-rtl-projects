// Double-buffered duty registers: shadow -> active only at counter zero (or while disabled).
module pwm_dbuf #(parameter N = 3) (
  input clk, input rst_n, input ld,
  input [16*N-1:0] d, output reg [16*N-1:0] q
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) q <= {16*N{1'b0}};
    else q <= ld ? d : q;
endmodule
