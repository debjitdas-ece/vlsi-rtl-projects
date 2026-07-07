`timescale 1ns/1ps
module pwm_prescaler #(
    parameter integer PRESCALER = 2
) (
    input  wire clk, rst_n,
    output wire tick
);
    localparam integer P_W = (PRESCALER <= 1) ? 1 : $clog2(PRESCALER);
    reg [P_W-1:0] cnt;
    reg tick_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= {P_W{1'b0}}; tick_r <= 1'b0;
        end else if (cnt == $unsigned(PRESCALER - 1)) begin
            cnt <= {P_W{1'b0}}; tick_r <= 1'b1;
        end else begin
            cnt <= cnt + 1'b1; tick_r <= 1'b0;
        end
    end
    assign tick = tick_r;
endmodule
