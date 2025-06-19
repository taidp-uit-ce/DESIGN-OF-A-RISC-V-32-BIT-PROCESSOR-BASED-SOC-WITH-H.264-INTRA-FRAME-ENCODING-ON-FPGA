module rptr_handler #(parameter PTR_WIDTH=3) (
    rd_clk,
    rd_rst_n,
    rd_en_i,
    g_wptr_sync_i,
    b_rptr_o,
    g_rptr_o,
    empty_o
);

    input                       rd_clk, rd_rst_n, rd_en_i;
    input [PTR_WIDTH:0]         g_wptr_sync_i;
    output reg [PTR_WIDTH:0]    b_rptr_o, g_rptr_o;
    output reg                  empty_o;
    
    wire [PTR_WIDTH:0] b_rptr_next;
    wire [PTR_WIDTH:0] g_rptr_next;
    wire               rempty_o;
    
    assign b_rptr_next = b_rptr_o+(rd_en_i & !empty_o);
    assign g_rptr_next = (b_rptr_next >>1)^b_rptr_next;
    assign rempty_o = (g_wptr_sync_i == g_rptr_next);
    
    always@(posedge rd_clk or negedge rd_rst_n) begin
        if(!rd_rst_n) begin
            b_rptr_o <= 0;
            g_rptr_o <= 0;
        end
        else begin
            b_rptr_o <= b_rptr_next;
            g_rptr_o <= g_rptr_next;
        end
    end
    
    always@(posedge rd_clk or negedge rd_rst_n) begin
        if(!rd_rst_n)
            empty_o <= 1;
        else
            empty_o <= rempty_o;
    end
endmodule