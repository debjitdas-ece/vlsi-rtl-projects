// HDLBits: vector2
// 32-bit to 4 bytes
module top_module (
    input  [31:0] vec,
    output [7:0]  out3, out2, out1, out0
);
    assign out3 = vec[31:24];
    assign out2 = vec[23:16];
    assign out1 = vec[15:8];
    assign out0 = vec[7:0];
endmodule
