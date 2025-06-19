`timescale 1ns / 1ps
module REG_FILE(
    clk,
    rst_n,
    reg_we_i,
    addr_d_i,
    data_d_i,
    axi_reg_we_i,
    axi_addr_d_i,
    axi_data_d_i,
    addr_a_i,
    addr_b_i,
    data_a_o,
    data_b_o
);
	input          clk, rst_n;
	input          reg_we_i, axi_reg_we_i;
	input [4:0]    addr_a_i, addr_b_i, addr_d_i, axi_addr_d_i;
	input [31:0]   data_d_i, axi_data_d_i;

	output [31:0]  data_a_o;
	output [31:0]  data_b_o;

	reg [31:0]     reg_32x32 [31:0];
	integer i;
 	always @(negedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 32; i = i + 1)
                reg_32x32[i] <= 32'b0;
        end
        else if(axi_reg_we_i && (axi_addr_d_i != 5'b0)) begin
            reg_32x32[axi_addr_d_i] <= axi_data_d_i;
        end
        else if(reg_we_i && (addr_d_i!=5'b0)) begin
            reg_32x32[addr_d_i] <= data_d_i;
        end 
    end
	assign data_a_o = reg_32x32[addr_a_i];
	assign data_b_o = reg_32x32[addr_b_i];
endmodule
