// HDLBits Problem 111: 3-bit LFSR
// Author: Debjit Das | JGEC ECE

module top_module (input [2:0] SW, input [1:0] KEY, output [2:0] LEDR);
    always @(posedge KEY[0])
        LEDR <= KEY[1] ? SW : {(LEDR[1]^LEDR[2]), LEDR[0], LEDR[2]};
endmodule
