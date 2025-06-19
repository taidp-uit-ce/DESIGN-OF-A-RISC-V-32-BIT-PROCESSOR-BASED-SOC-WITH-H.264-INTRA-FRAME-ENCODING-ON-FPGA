module wptr_handler #(parameter PTR_WIDTH=3) (
    wr_clk,
    wr_rst_n,
    wr_en_i,
    g_rptr_sync_i,
    b_wptr_o,
    g_wptr_o,
    full_o
);
    input                     wr_clk, wr_rst_n, wr_en_i;
    input [PTR_WIDTH:0]       g_rptr_sync_i;
    output reg [PTR_WIDTH:0]  b_wptr_o, g_wptr_o;
    output reg                full_o;
    
    
    wire [PTR_WIDTH:0] b_wptr_next;
    wire [PTR_WIDTH:0] g_wptr_next;
    
    wire wfull_o;
    
    assign b_wptr_next = b_wptr_o+(wr_en_i & !full_o);
    assign g_wptr_next = (b_wptr_next >>1)^b_wptr_next;
    
    always@(posedge wr_clk or negedge wr_rst_n) begin
        if(!wr_rst_n) begin
            b_wptr_o <= 0; // set default value
            g_wptr_o <= 0;
        end
    else begin
        b_wptr_o <= b_wptr_next; // incr binary write pointer
        g_wptr_o <= g_wptr_next; // incr gray write pointer
    end
    end
    
    always@(posedge wr_clk or negedge wr_rst_n) begin
        if(!wr_rst_n)
            full_o <= 0;
        else        
            full_o <= wfull_o;
    end
    
    assign wfull_o = (g_wptr_next == {~g_rptr_sync_i[PTR_WIDTH:PTR_WIDTH-1], g_rptr_sync_i[PTR_WIDTH-2:0]});
    
endmodule