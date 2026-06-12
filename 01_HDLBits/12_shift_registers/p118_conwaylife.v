// HDLBits Problem 118: Conway's Game of Life 16x16
// Author: Debjit Das | JGEC ECE

module top_module (input clk, load, input [255:0] data, output reg [255:0] q);
    integer i, r, c, n;
    always @(posedge clk) begin
        if (load) q <= data;
        else begin
            for (i=0; i<256; i=i+1) begin
                r = i/16; c = i%16;
                n = q[((r?r:16)-1)*16+((c?c:16)-1)]+q[((r?r:16)-1)*16+c]+
                    q[((r?r:16)-1)*16+((c==15)?0:c+1)]+q[r*16+((c?c:16)-1)]+
                    q[r*16+((c==15)?0:c+1)]+q[((r==15)?0:r+1)*16+((c?c:16)-1)]+
                    q[((r==15)?0:r+1)*16+c]+q[((r==15)?0:r+1)*16+((c==15)?0:c+1)];
                q[i] <= (n==3) || (n==2 && q[i]);
            end
        end
    end
endmodule
