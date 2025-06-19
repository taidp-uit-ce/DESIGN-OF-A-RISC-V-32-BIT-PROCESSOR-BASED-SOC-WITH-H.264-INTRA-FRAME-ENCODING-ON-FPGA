module synchronizer #(parameter WIDTH=3) (
    clk,
    rst_n,
    data_i,
    data_o
);
    input                   clk, rst_n;
    input [WIDTH:0]         data_i;
    output reg [WIDTH:0]    data_o;
    
    reg [WIDTH:0] q1;
    always @(posedge clk) begin
        if(!rst_n) begin
            q1      <= 0;
            data_o  <= 0;
        end
    else begin
        q1          <= data_i;
        data_o      <= q1;
    end
    end
endmodule