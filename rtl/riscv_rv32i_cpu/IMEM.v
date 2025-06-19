`timescale 1ns / 1ps
module IMEM #(parameter RV32I_IMEM_DEPTH = 1)(
    clk,
    s_axi_wr_en_i,
    s_axi_addr_i,
    s_axi_data_i,
    addr_i,
    inst_o
);
    input           clk;
    input           s_axi_wr_en_i;
    input [31:0]    s_axi_addr_i, s_axi_data_i;
    input [31:0]    addr_i;                 
    output [31:0]   inst_o;
    
    localparam IMEM_DEPTH_WORDS = (RV32I_IMEM_DEPTH * 1024) / 4;
    localparam ADDR_WIDTH = $clog2(IMEM_DEPTH_WORDS);
    
//    (* ram_style = "block" *)
//    (* ram_decomp = "power" *)
    reg [31:0]              imem_reg [IMEM_DEPTH_WORDS-1:0];
    wire [ADDR_WIDTH-1:0]   word_addr;
    
    assign word_addr = s_axi_addr_i[ADDR_WIDTH+1:2];
    
    always @(posedge clk) begin
        if(s_axi_wr_en_i)
            imem_reg[word_addr]   <= s_axi_data_i;
    end
    
    assign inst_o = imem_reg[addr_i];
endmodule 
/*
module IMEM(
    addr_i,
    inst_o
);
    input [31:0]    addr_i;                 
    output [31:0]   inst_o;

    localparam IMEM_FILE = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\rtl\\ip_repo\\RV32I_CORE_IP\\imem_hex\\imem_soc.hex";
    reg [31:0] imem_reg [1023:0];
    
    integer file_status; 
    initial begin 
        file_status = $fopen(IMEM_FILE, "r");
        if (file_status == 0) begin
            $display("Error: Could not open file %s", IMEM_FILE);
            $finish;
        end else begin
            $display("File %s opened successfully", IMEM_FILE);
            $fclose(file_status);
        end   
        $readmemh(IMEM_FILE, imem_reg);
    end
    
    assign inst_o = imem_reg[addr_i];
endmodule */
