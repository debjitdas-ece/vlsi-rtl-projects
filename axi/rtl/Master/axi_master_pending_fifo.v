module axi_master_pending_fifo #(
    parameter DEPTH = 4,
    parameter ID_WIDTH = 4
) (
    input clk,rst_n,
    input push_valid,pop_valid,
    input [31:0] push_addr,
    input [7:0] push_len,
    input [2:0] push_size,
    input [1:0] push_burst,
    input [ID_WIDTH-1:0] push_id,
    output push_ready,pop_ready,
    output [31:0] pop_addr,
    output [7:0] pop_len,
    output [2:0] pop_size,
    output [1:0] pop_burst,
    output [ID_WIDTH-1:0] pop_id
);
    localparam PTR_WIDTH = $clog2(DEPTH);
    reg [31:0] addr_fifo [DEPTH-1:0];
    reg [7:0] len_fifo [DEPTH-1:0];
    reg [2:0] size_fifo [DEPTH-1:0];
    reg [1:0] burst_fifo [DEPTH-1:0];
    reg [ID_WIDTH-1:0] id_fifo [DEPTH-1:0];
    reg [PTR_WIDTH-1:0] wr_ptr,rd_ptr;
    reg [PTR_WIDTH:0] count;
    assign push_ready = (count < DEPTH);
    assign pop_ready = (count > 0);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if(push_valid && push_ready) begin
                addr_fifo[wr_ptr] <= push_addr;
                len_fifo[wr_ptr] <= push_len;
                size_fifo[wr_ptr] <= push_size;
                burst_fifo[wr_ptr] <= push_burst;
                id_fifo[wr_ptr] <= push_id;
                wr_ptr <= wr_ptr + 1;
            end
            if(pop_valid && pop_ready) begin
                rd_ptr <= rd_ptr + 1;
            end
           count <= count + (push_valid && push_ready) - (pop_valid && pop_ready);
        end
    end

    assign {pop_addr,pop_len,pop_size,pop_burst,pop_id} = {addr_fifo[rd_ptr],len_fifo[rd_ptr],size_fifo[rd_ptr],burst_fifo[rd_ptr],id_fifo[rd_ptr]};

endmodule