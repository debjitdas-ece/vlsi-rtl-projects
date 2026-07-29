module axi_ic_arbiter (
    input  clk, rst_n,
    input  [1:0] req,
    output reg [1:0] grant
);
reg [1:0] last_grant;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        grant <= 2'b00;
        last_grant <= 2'b00;
    end else begin
        grant <= (req == 2'b01) ? 2'b01 : (req == 2'b10) ? 2'b10 : (req == 2'b11) ? (last_grant == 2'b01 ? 2'b10 : 2'b01) : 2'b00;
        last_grant <= grant;
    end
end
    
endmodule