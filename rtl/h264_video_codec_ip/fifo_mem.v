module fifo_mem #(parameter DEPTH=8, DATA_WIDTH=8, PTR_WIDTH=3) (
    wr_clk,
    wr_en,
    rd_clk,
//    rd_ready_i,
//    rd_valid_o,
    b_wptr_i,
    b_rptr_i,
    data_i,
    full_i,
//    empty_i,
    data_o
);
    input                   wr_clk, wr_en, rd_clk;//, rd_ready_i;
    input [PTR_WIDTH:0]     b_wptr_i, b_rptr_i;
    input [DATA_WIDTH-1:0]  data_i;
    input                   full_i;//, empty_i;
//    output                  rd_valid_o;
    output [DATA_WIDTH-1:0] data_o;
    
    reg [DATA_WIDTH-1:0] fifo[0:DEPTH-1];
    
//    assign rd_valid_o = !empty_i;
    
    always@(posedge wr_clk) begin
        if(wr_en & !full_i) begin
          fifo[b_wptr_i[PTR_WIDTH-1:0]] <= data_i;
        end
    end
    
    assign data_o = fifo[b_rptr_i[PTR_WIDTH-1:0]];
endmodule
