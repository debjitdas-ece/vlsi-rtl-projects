// HDLBits: popcount255
// Count number of 1s in 255-bit vector
module top_module (
    input  [254:0] in,
    output [7:0]   out
);
    integer i;
    always @(*) begin
        out = 8'd0;
        for (i = 0; i < 255; i = i+1)
            out = out + in[i];
    end
endmodule
