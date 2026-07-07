`timescale 1ns/1ps
module pwm_trip #(
    parameter N = 3,
    parameter SAFE_STATE = 1'b0
) (
    input clk, rst_n, t_i, t_m, t_c, z_f,
    input  [N-1:0] pwm_in,
    output reg [N-1:0] pwm_out,
    output reg trip_active
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trip_active <= 1'b0; pwm_out <= {N{SAFE_STATE}};
        end else begin
            trip_active <= t_i ? 1'b1 : t_m ? (t_c ? 1'b0 : trip_active) : (z_f ? 1'b0 : trip_active);
            pwm_out     <= (t_i | trip_active) ? {N{SAFE_STATE}} : pwm_in;
        end
    end
endmodule
