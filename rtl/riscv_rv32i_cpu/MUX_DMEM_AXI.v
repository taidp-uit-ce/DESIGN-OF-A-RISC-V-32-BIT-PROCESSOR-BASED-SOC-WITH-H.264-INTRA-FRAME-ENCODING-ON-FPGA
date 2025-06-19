`timescale 1ns / 1ps
module MUX_DMEM_AXI #(RV32I_DMEM_DEPTH = 4)(
    opcode_i,
    addr_i,
    data_w_i,
    reg_we_i,
    mem_we_i,
    mem_re_i,
    funct3_i,
    addr_d_i,
    dmem_addr_o,   
    dmem_data_w_o,
    dmem_mem_we_o,
    dmem_mem_re_o,
    dmem_funct3_o,
    axi_addr_o,
    axi_data_w_o,
    axi_mem_we_o,
    axi_funct3_o,
    axi_init_o,
    reg_we_o,
    addr_d_o
);
    input   [6:0]   opcode_i;
    input   [31:0]  addr_i;
    input   [31:0]  data_w_i;
    input           reg_we_i;
    input           mem_we_i, mem_re_i;
    input   [2:0]   funct3_i;
    input   [4:0]   addr_d_i;

    output  [31:0]  dmem_addr_o;
    output  [31:0]  dmem_data_w_o;
    output          dmem_mem_we_o, dmem_mem_re_o;
    output  [2:0]   dmem_funct3_o;
    output  [31:0]  axi_addr_o;
    output  [31:0]  axi_data_w_o;
    output          axi_mem_we_o;
    output  [2:0]   axi_funct3_o;
    output          axi_init_o;
    output          reg_we_o;
    output  [4:0]   addr_d_o;  
    
    localparam [31:0]   DMEM_SIZE_BYTE = RV32I_DMEM_DEPTH * 1024;
    localparam [31:0]   DMEM_MAX_ADDR  = DMEM_SIZE_BYTE - 1;
    wire   lw_sw, ext_access;
    assign lw_sw            = (opcode_i == 7'b0000011 || opcode_i ==  7'b0100011) ? 1'b1 : 1'b0;
    assign ext_access       = (addr_i > DMEM_MAX_ADDR) ? 1'b1 : 1'b0;
    
    assign dmem_addr_o      = (lw_sw && !ext_access)? addr_i   : 32'b0;
    assign dmem_data_w_o    = (lw_sw && !ext_access)? data_w_i : 32'b0;
    assign dmem_mem_we_o    = (lw_sw && !ext_access)? mem_we_i : 1'b0;
    assign dmem_mem_re_o    = (lw_sw && !ext_access)? mem_re_i : 1'b0; //taidao added 30/5
    assign dmem_funct3_o    = (lw_sw && !ext_access)? funct3_i : 3'b0;
    
    assign axi_addr_o       = (lw_sw && ext_access)? addr_i   : 32'b0;
    assign axi_data_w_o     = (lw_sw && ext_access)? data_w_i : 32'b0;
    assign axi_mem_we_o     = (lw_sw && ext_access)? mem_we_i : 1'b0;
    assign axi_funct3_o     = (lw_sw && ext_access)? funct3_i : 3'b0;
    
    assign axi_init_o       = (lw_sw && ext_access)? 1'b1 : 1'b0;
    
    assign reg_we_o         = ((!lw_sw) || (lw_sw && !ext_access))? reg_we_i : 1'b0; //should base on is_load (just lw cmd)
    assign addr_d_o         = ((!lw_sw) || (lw_sw && !ext_access))? addr_d_i : 5'b0;

endmodule