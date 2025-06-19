`timescale 1ns / 1ps
module MA_STAGE #(parameter RV32I_DMEM_DEPTH = 4)(
    clk,
    rst_n,
    reg_we_i,
    mem_we_i,
    mem_re_i,
    wb_sel_i,
    funct3_i,
    alu_result_i,
    data_w_i,
    pc4_i,
    addr_d_i,
    opcode_i,
    reg_we_o,
    wb_sel_o,
    alu_result_o,
    data_r_o,
    pc4_o,
    addr_d_o,
    m_axi_addr_o,
    m_axi_data_w_o,
    m_axi_mem_we_o,
    m_axi_funct3_o,   
    m_axi_init_o,
    s_axi_dmem_re_i,
    s_axi_dmem_addr_i,
    s_axi_dmem_data_o
);
    input           clk; 
    input           rst_n;
    input           reg_we_i, mem_we_i, mem_re_i;
    input [1:0]     wb_sel_i;
    input [2:0]     funct3_i;
    input [31:0]    alu_result_i;
    input [31:0]    data_w_i;
    input [31:0]    pc4_i;
    input [4:0]     addr_d_i;
    input [6:0]     opcode_i;
    
    output reg           reg_we_o;
    output reg [1:0]     wb_sel_o;
    output [31:0]        data_r_o;
    output reg [31:0]    alu_result_o;
    output reg [31:0]    pc4_o;
    output reg [4:0]     addr_d_o;
    
    output [2:0]    m_axi_funct3_o;
    output [31:0]   m_axi_addr_o;
    output [31:0]   m_axi_data_w_o;
    output          m_axi_mem_we_o,
                    m_axi_init_o;
                    
    input           s_axi_dmem_re_i;
    input [31:0]    s_axi_dmem_addr_i;
    output [31:0]   s_axi_dmem_data_o;
    
    wire [31:0]     dmem_addr;
    wire [31:0]     dmem_data_w;
    wire            dmem_mem_we, dmem_mem_re;
    wire [2:0]      dmem_funct3;
    wire [4:0]      addr_d;
    wire            reg_we;
         
    MUX_DMEM_AXI #(.RV32I_DMEM_DEPTH(RV32I_DMEM_DEPTH)) U_MUX_DMEM_AXI(
                        .opcode_i       ( opcode_i      ),
                        .addr_i         ( alu_result_i  ),
                        .data_w_i       ( data_w_i      ),
                        .reg_we_i       ( reg_we_i      ),
                        .mem_we_i       ( mem_we_i      ),
                        .mem_re_i       ( mem_re_i      ),
                        .funct3_i       ( funct3_i      ),
                        .addr_d_i       ( addr_d_i      ),
                        
                        .dmem_addr_o    ( dmem_addr     ),   
                        .dmem_data_w_o  ( dmem_data_w   ),
                        .dmem_mem_we_o  ( dmem_mem_we   ),
                        .dmem_mem_re_o  ( dmem_mem_re   ),
                        .dmem_funct3_o  ( dmem_funct3   ),
                        
                        .axi_addr_o     ( m_axi_addr_o    ),
                        .axi_data_w_o   ( m_axi_data_w_o  ),
                        .axi_mem_we_o   ( m_axi_mem_we_o  ),
                        .axi_funct3_o   ( m_axi_funct3_o  ),
                        .axi_init_o     ( m_axi_init_o    ),
                        
                        .reg_we_o       ( reg_we        ),
                        .addr_d_o       ( addr_d        )
                    ); 

   DMEM #(.RV32I_DMEM_DEPTH(RV32I_DMEM_DEPTH)) U_DMEM(       
                        .clk            ( clk               ),
                        .rst_n          ( rst_n             ),
                        .mem_we_i       ( dmem_mem_we       ),
                        .mem_re_i       ( dmem_mem_re       ),
                        .addr_i         ( dmem_addr         ),
                        .funct3_i       ( dmem_funct3       ),
                        .data_w_i       ( dmem_data_w       ),
                        .data_r_o       ( data_r_o          ), //dmem_data_r
                        .s_axi_re_i     ( s_axi_dmem_re_i   ),
                        .s_axi_addr_i   ( s_axi_dmem_addr_i ),
                        .s_axi_data_o   ( s_axi_dmem_data_o )
                    );  
                           
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            reg_we_o    <= 1'b0;
            wb_sel_o    <= 2'b0;
            addr_d_o    <= 5'b0;
//            data_r_o    <= 32'b0;
            alu_result_o<= 32'b0;
            pc4_o       <= 32'b0;
        end
        else begin
            reg_we_o    <= reg_we;
            wb_sel_o    <= wb_sel_i;
            addr_d_o    <= addr_d;
//            data_r_o    <= dmem_data_r;
            alu_result_o<= alu_result_i;
            pc4_o       <= pc4_i;
        end
    end

endmodule
