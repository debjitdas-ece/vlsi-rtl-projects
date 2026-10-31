module pwm_compare #(parameter N = 3) (
  input [15:0] cnt, input [16*N-1:0] duty,
  output [N-1:0] raw
);
  genvar i;
  generate for (i = 0; i < N; i = i + 1) begin : g
    assign raw[i] = (cnt < duty[16*i +: 16]);
  end endgenerate
endmodule
