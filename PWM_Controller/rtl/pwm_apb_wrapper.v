module pwm_apb_wrapper #(
    parameter integer P_S = 2,
    parameter integer N   = 3,
    parameter SAFE_STATE  = 1'b0
) (
    input  clk, rst_n,
    input  [7:0]  paddr,
    input  psel, penable, pwrite,
    input  [31:0] pwdata,
    output reg [31:0] prdata,
    output pready, pslverr,
    input  sync_in,
    output sync_out,
    input  trip_in_ext,
    output [2*N-1:0] pwm_out,
    output adc_trig_a, adc_trig_b
);
    localparam ADDR_CTRL=8'h00, ADDR_PHASE=8'h04, ADDR_TOP=8'h08;
    localparam ADDR_DUTY0=8'h0C, ADDR_DUTY1=8'h10, ADDR_DUTY2=8'h14;
    localparam ADDR_POLARITY=8'h18, ADDR_DEADTIME=8'h1C, ADDR_TRIP_CTRL=8'h20;
    localparam ADDR_TRIG_CTRL=8'h24, ADDR_TRIG_POINT_A=8'h28, ADDR_TRIG_POINT_B=8'h2C;
    localparam ADDR_STATUS=8'h30, ADDR_LOCK=8'h34;

    assign pready  = 1'b1;
    assign pslverr = 1'b0;
    wire apb_write = psel & penable & pwrite;

    reg [1:0]  ctrl_reg;
    reg [10:0] phase_reg, top_reg;
    reg [10:0] duty_reg [0:2];
    reg [2:0]  polarity_reg;
    reg [15:0] deadtime_reg;
    reg        trip_mode_reg, soft_trip_reg;
    reg [3:0]  trig_ctrl_reg;
    reg [10:0] trig_point_a_reg, trig_point_b_reg;
    reg        lock_reg;
    reg        top_id_d, duty_id_d [0:2], trip_clear_d;
    wire       trip_active_w;
    wire       lock_blocks_write = lock_reg & ((paddr == ADDR_TRIP_CTRL) | (paddr == ADDR_DEADTIME));

    reg trip_ext_meta, trip_ext_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin trip_ext_meta <= 1'b0; trip_ext_sync <= 1'b0; end
        else begin trip_ext_meta <= trip_in_ext; trip_ext_sync <= trip_ext_meta; end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 2'b00; phase_reg <= 11'd0; top_reg <= 11'd0;
            duty_reg[0] <= 11'd0; duty_reg[1] <= 11'd0; duty_reg[2] <= 11'd0;
            polarity_reg <= 3'b000; deadtime_reg <= 16'd0;
            trip_mode_reg <= 1'b0; soft_trip_reg <= 1'b0;
            trig_ctrl_reg <= 4'b0000; trig_point_a_reg <= 11'd0; trig_point_b_reg <= 11'd0;
            lock_reg <= 1'b0;
            top_id_d <= 1'b0; duty_id_d[0] <= 1'b0; duty_id_d[1] <= 1'b0; duty_id_d[2] <= 1'b0;
            trip_clear_d <= 1'b0;
        end else begin
            top_id_d <= 1'b0; duty_id_d[0] <= 1'b0; duty_id_d[1] <= 1'b0; duty_id_d[2] <= 1'b0;
            trip_clear_d <= 1'b0;
            if (apb_write && !lock_blocks_write) begin
                case (paddr)
                    ADDR_CTRL:      ctrl_reg <= pwdata[1:0];
                    ADDR_PHASE:     phase_reg <= pwdata[10:0];
                    ADDR_TOP:       begin top_reg <= pwdata[10:0]; top_id_d <= 1'b1; end
                    ADDR_DUTY0:     begin duty_reg[0] <= pwdata[10:0]; duty_id_d[0] <= 1'b1; end
                    ADDR_DUTY1:     begin duty_reg[1] <= pwdata[10:0]; duty_id_d[1] <= 1'b1; end
                    ADDR_DUTY2:     begin duty_reg[2] <= pwdata[10:0]; duty_id_d[2] <= 1'b1; end
                    ADDR_POLARITY:  polarity_reg <= pwdata[2:0];
                    ADDR_DEADTIME:  deadtime_reg <= pwdata[15:0];
                    ADDR_TRIP_CTRL: begin trip_mode_reg <= pwdata[0]; soft_trip_reg <= pwdata[2]; trip_clear_d <= pwdata[1]; end
                    ADDR_TRIG_CTRL: trig_ctrl_reg <= pwdata[3:0];
                    ADDR_TRIG_POINT_A: trig_point_a_reg <= pwdata[10:0];
                    ADDR_TRIG_POINT_B: trig_point_b_reg <= pwdata[10:0];
                    ADDR_LOCK:      lock_reg <= pwdata[0];
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (paddr)
            ADDR_CTRL:      prdata = {30'd0, ctrl_reg};
            ADDR_PHASE:     prdata = {21'd0, phase_reg};
            ADDR_TOP:       prdata = {21'd0, top_reg};
            ADDR_DUTY0:     prdata = {21'd0, duty_reg[0]};
            ADDR_DUTY1:     prdata = {21'd0, duty_reg[1]};
            ADDR_DUTY2:     prdata = {21'd0, duty_reg[2]};
            ADDR_POLARITY:  prdata = {29'd0, polarity_reg};
            ADDR_DEADTIME:  prdata = {16'd0, deadtime_reg};
            ADDR_TRIP_CTRL: prdata = {29'd0, soft_trip_reg, 1'b0, trip_mode_reg};
            ADDR_TRIG_CTRL: prdata = {28'd0, trig_ctrl_reg};
            ADDR_TRIG_POINT_A: prdata = {21'd0, trig_point_a_reg};
            ADDR_TRIG_POINT_B: prdata = {21'd0, trig_point_b_reg};
            ADDR_STATUS:    prdata = {29'd0, adc_trig_b, adc_trig_a, trip_active_w};
            ADDR_LOCK:      prdata = {31'd0, lock_reg};
            default:        prdata = 32'd0;
        endcase
    end

    pwm_top #(.P_S(P_S), .N(N), .SAFE_STATE(SAFE_STATE)) dut (
        .clk(clk), .rst_n(rst_n), .mode_sel(ctrl_reg[0]),
        .sync_in(sync_in), .sync_en(ctrl_reg[1]), .sync_out(sync_out),
        .phase_offset(phase_reg), .top_val(top_reg), .top_id(top_id_d),
        .duty_in({duty_reg[2], duty_reg[1], duty_reg[0]}),
        .duty_id({duty_id_d[2], duty_id_d[1], duty_id_d[0]}),
        .polarity(polarity_reg),
        .rising_dt_cycles(deadtime_reg[7:0]), .falling_dt_cycles(deadtime_reg[15:8]),
        .trip_in(trip_ext_sync | soft_trip_reg), .trip_mode(trip_mode_reg), .trip_clear(trip_clear_d),
        .trip_active(trip_active_w),
        .trig_en_a(trig_ctrl_reg[0]), .dir_qual_a(trig_ctrl_reg[1]),
        .trig_en_b(trig_ctrl_reg[2]), .dir_qual_b(trig_ctrl_reg[3]),
        .trig_point_a(trig_point_a_reg), .trig_point_b(trig_point_b_reg),
        .adc_trig_a(adc_trig_a), .adc_trig_b(adc_trig_b),
        .pwm_out(pwm_out)
    );
endmodule
