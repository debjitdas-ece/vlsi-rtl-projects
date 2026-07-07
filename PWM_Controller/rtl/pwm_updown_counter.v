`timescale 1ns/1ps
module pwm_updown_counter (
    input clk, rst_n, tick, mode_sel,
    input [10:0] top_val,
    input sync_in, sync_en,
    input [10:0] phase_offset,
    output reg [10:0] cnt,
    output reg dir,
    output z_f);

    wire flip_center = (!dir && cnt == top_val) || (dir && cnt == 0);
    wire flip_edge   = (cnt == top_val);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0; dir <= 0;
        end else if (sync_en && sync_in) begin
            cnt <= phase_offset;
            dir <= 1'b0;
        end else if (tick) begin
            if (mode_sel) begin
                dir <= 1'b0;
                cnt <= (top_val == 0) ? cnt : (flip_edge ? 11'd0 : cnt + 1'b1);
            end else begin
                dir <= flip_center ? ~dir : dir;
                cnt <= (top_val == 0) ? cnt : (flip_center ? (dir ? cnt + 1 : cnt - 1) : (dir ? cnt - 1 : cnt + 1));
            end
        end
    end
    assign z_f = (cnt == 0);
endmodule
