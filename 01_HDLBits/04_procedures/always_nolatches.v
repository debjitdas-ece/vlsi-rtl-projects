// HDLBits Problem 36: Avoiding latches
// Author: Debjit Das | JGEC ECE

module top_module (input [15:0] scancode,
    output reg left, down, right, up);
    always @(*) begin
        {left, down, right, up} = 4'b0;
        case (scancode)
            16'he06b: left  = 1; 16'he072: down  = 1;
            16'he074: right = 1; 16'he075: up    = 1;
        endcase
    end
endmodule
