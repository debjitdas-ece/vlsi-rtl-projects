module fifo_sync #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ALMOST_FULL_THRESH  = 2,   
    parameter ALMOST_EMPTY_THRESH = 2   
) (
    input clk, rst, wr_en, rd_en,
    input [WIDTH-1:0] wr_data,
    output full, empty, almost_full, almost_empty,
    output [WIDTH-1:0] rd_data,
    output reg [$clog2(DEPTH + 1) - 1:0] count
);
    assign full         = (count == DEPTH);
    assign empty        = (count == 0);
    assign almost_full  = (count >= (DEPTH - ALMOST_FULL_THRESH));
    assign almost_empty = (count <= ALMOST_EMPTY_THRESH);

    wire inc = wr_en && !full;
    wire dec = rd_en && !empty;

    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [$clog2(DEPTH) - 1:0] wr_ptr, rd_ptr;
    assign rd_data = fifo_mem[rd_ptr];

    always @(posedge clk or posedge rst) begin
     if (rst) begin
            count  <= 0;
            wr_ptr <= 0;
            rd_ptr <= 0;
     end else begin
    case ({inc, dec})
         2'b10: begin                       
            count  <= count + 1;
            wr_ptr <= wr_ptr + 1;
            fifo_mem[wr_ptr] <= wr_data;
         end
        2'b01: begin                       
            count  <= count - 1;
            rd_ptr <= rd_ptr + 1;
        end
        2'b11: begin                       
            wr_ptr <= wr_ptr + 1;
            rd_ptr <= rd_ptr + 1;
            fifo_mem[wr_ptr] <= wr_data;
        end
        default: ;                         
    endcase
    end
    end
endmodule