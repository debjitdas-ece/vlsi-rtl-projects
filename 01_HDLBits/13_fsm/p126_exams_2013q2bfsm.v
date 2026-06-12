// HDLBits Problem 126: Water level FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, input [3:1] s,
    output fr3, fr2, fr1, dfr);
    parameter L0=4'b1111, L1_R=4'b0110, L1_F=4'b0111,
              L2_R=4'b0010, L2_F=4'b0011, L3=4'b0000;
    reg [3:0] state;
    always @(posedge clk) begin
        if (reset) state <= L0;
        else case(state)
            L0:   state <= (s==3'b001)?L1_R:(s==3'b011)?L2_R:(s==3'b111)?L3:L0;
            L1_R: state <= (s==3'b011)?L2_R:(s==3'b000)?L0:L1_R;
            L1_F: state <= (s==3'b000)?L0:(s==3'b011)?L2_R:L1_F;
            L2_R: state <= (s==3'b111)?L3:(s==3'b001)?L1_F:L2_R;
            L2_F: state <= (s==3'b001)?L1_F:(s==3'b111)?L3:L2_F;
            L3:   state <= (s==3'b011)?L2_F:(s==3'b001)?L1_F:(s==3'b000)?L0:L3;
            default: state <= L0;
        endcase
    end
    assign {fr3,fr2,fr1,dfr} = state;
endmodule
