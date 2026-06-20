`timescale 1ns/1ns
module spi_slave_bfm #(
    parameter DW = 8
)(
    input  wire          sclk,
    input  wire          ss,        
    input  wire          cpol,
    input  wire          cpha,
    input  wire          mosi,
    output wire          miso,
    input  wire [DW-1:0] tx_data,   
    output reg  [DW-1:0] rx_data,   
    output reg           rx_valid   
);

    reg [DW-1:0] tx_sh;
    reg [DW-1:0] rx_sh;
    reg [3:0]    bit_cnt;
    reg [3:0]    tcnt;    

    wire mode_xor = cpol ^ cpha;

    assign miso = tx_sh[DW-1];

    
    always @(negedge ss) begin
        tx_sh    = tx_data;
        bit_cnt  = 0;
        tcnt     = 0;
        rx_valid = 1'b0;
    end

    always @(negedge ss) rx_sh = {DW{1'b0}};

    always @(posedge sclk) if (!ss) tcnt <= tcnt + 1'b1;
    always @(negedge sclk) if (!ss) tcnt <= tcnt + 1'b1;

    
    always @(posedge sclk) begin
        if (!ss && !mode_xor) begin
            rx_sh   <= {rx_sh[DW-2:0], mosi};
            bit_cnt <= bit_cnt + 1'b1;
            if (bit_cnt == DW-1) begin
                rx_data  <= {rx_sh[DW-2:0], mosi};
                rx_valid <= 1'b1;
            end else
                rx_valid <= 1'b0;
        end
    end

    always @(negedge sclk) begin
        if (!ss && mode_xor) begin
            rx_sh   <= {rx_sh[DW-2:0], mosi};
            bit_cnt <= bit_cnt + 1'b1;
            if (bit_cnt == DW-1) begin
                rx_data  <= {rx_sh[DW-2:0], mosi};
                rx_valid <= 1'b1;
            end else
                rx_valid <= 1'b0;
        end
    end

    wire shift_now = !(cpha && tcnt == 0);
    always @(posedge sclk) if (!ss &&  mode_xor && shift_now) tx_sh <= {tx_sh[DW-2:0], 1'b0};
    always @(negedge sclk) if (!ss && !mode_xor && shift_now) tx_sh <= {tx_sh[DW-2:0], 1'b0};

endmodule