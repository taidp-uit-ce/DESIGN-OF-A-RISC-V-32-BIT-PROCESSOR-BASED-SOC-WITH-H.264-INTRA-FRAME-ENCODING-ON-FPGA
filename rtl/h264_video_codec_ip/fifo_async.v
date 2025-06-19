module fifo_async #(parameter DEPTH=8, DATA_WIDTH=8) (
    wr_clk,
    wr_rst_n,
    wr_data_i,
    wr_en_i, 
    wr_full_o,
    rd_clk,
    rd_rst_n,
    rd_empty_o,  
    rd_en_i,
//    rd_valid_o,
    rd_data_o    
);
    input                   wr_clk, wr_rst_n;
    input                   rd_clk, rd_rst_n;
    input                   wr_en_i, rd_en_i;
    input [DATA_WIDTH-1:0]  wr_data_i;
    output [DATA_WIDTH-1:0] rd_data_o;
    output                  wr_full_o, rd_empty_o;//, rd_valid_o;
    
    
    localparam PTR_WIDTH = $clog2(DEPTH);
    
    wire [PTR_WIDTH:0] g_wptr_sync, g_rptr_sync;
    wire [PTR_WIDTH:0] b_wptr, b_rptr;
    wire [PTR_WIDTH:0] g_wptr, g_rptr;
    
    wire fifo_full, fifo_empty;
    synchronizer #(PTR_WIDTH) u_sync_wptr (
                                            .clk    (rd_clk),
                                            .rst_n  (rd_rst_n),
                                            .data_i (g_wptr),
                                            .data_o (g_wptr_sync)
                                            ); //write pointer to read clock domain
    synchronizer #(PTR_WIDTH) u_sync_rptr (
                                            .clk    (wr_clk),
                                            .rst_n  (wr_rst_n),
                                            .data_i (g_rptr),
                                            .data_o (g_rptr_sync)
                                            ); //read pointer to write clock domain 
    
    wptr_handler #(PTR_WIDTH) u_wptr_h    (
                                            .wr_clk         (wr_clk),
                                            .wr_rst_n       (wr_rst_n),
                                            .wr_en_i        (wr_en_i),
                                            .g_rptr_sync_i  (g_rptr_sync),
                                            .b_wptr_o       (b_wptr),
                                            .g_wptr_o       (g_wptr),
                                            .full_o         (fifo_full)
                                            );
    rptr_handler #(PTR_WIDTH) u_rptr_h    (
                                            .rd_clk         (rd_clk),
                                            .rd_rst_n       (rd_rst_n),
                                            .rd_en_i        (rd_en_i),
                                            .g_wptr_sync_i  (g_wptr_sync),
                                            .b_rptr_o       (b_rptr),
                                            .g_rptr_o       (g_rptr),
                                            .empty_o        (fifo_empty)
                                            );
    fifo_mem #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH), .PTR_WIDTH(PTR_WIDTH)) u_fifo_mem (
                                            .wr_clk         (wr_clk),
                                            .wr_en          (wr_en_i),
                                            .rd_clk         (rd_clk),
//                                            .rd_ready_i     (rd_en_i),
//                                            .rd_valid_o     (rd_valid_o),
                                            .b_wptr_i       (b_wptr),
                                            .b_rptr_i       (b_rptr),
                                            .data_i         (wr_data_i),
                                            .full_i         (fifo_full),
//                                            .empty_i        (fifo_empty),
                                            .data_o         (rd_data_o)
                                            );
    
    assign wr_full_o = fifo_full;
    assign rd_empty_o = fifo_empty;
endmodule
