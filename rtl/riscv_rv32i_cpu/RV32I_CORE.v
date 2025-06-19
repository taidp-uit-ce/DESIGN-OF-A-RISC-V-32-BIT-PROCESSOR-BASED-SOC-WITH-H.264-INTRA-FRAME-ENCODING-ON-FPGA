`timescale 1ns / 1ps
module RV32I_CORE #(parameter RV32I_DMEM_DEPTH = 4, parameter RV32I_IMEM_DEPTH = 1)(
    clk,
    rst_n,
    m_axi_stall_i,
    m_axi_reg_we_i,
    m_axi_addr_d_i,
    m_axi_data_d_i,
    m_axi_funct3_o,
    m_axi_init_o,
    m_axi_reg_we_o,
    m_axi_mem_we_o, 
    m_axi_addr_d_o,
    m_axi_addr_o,
    m_axi_data_w_o,
    
    s_axi_id_pc_o,
    s_axi_id_inst_o,
    s_axi_start_i,
    s_axi_imem_we_i,
    s_axi_imem_addr_i,
    s_axi_imem_data_i,
    s_axi_dmem_re_i,
    s_axi_dmem_addr_i,
    s_axi_dmem_data_r_o
);
    input           clk, rst_n;
    input           m_axi_stall_i, m_axi_reg_we_i;
    input [4:0]     m_axi_addr_d_i;
    input [31:0]    m_axi_data_d_i;
    output [2:0]    m_axi_funct3_o;
    output [4:0]    m_axi_addr_d_o;
    output [31:0]   m_axi_addr_o, m_axi_data_w_o;
    output          m_axi_reg_we_o, m_axi_mem_we_o, m_axi_init_o;
    
    input           s_axi_start_i, s_axi_imem_we_i, s_axi_dmem_re_i;
    input [31:0]    s_axi_imem_addr_i, s_axi_imem_data_i, s_axi_dmem_addr_i;
    output [31:0]   s_axi_id_pc_o, s_axi_id_inst_o, s_axi_dmem_data_r_o;
    //IF wire
    wire            if_pc_sel;
    //ID wire
    wire [31:0]     id_inst, id_pc, id_pc4, m_axi_pc_stall;
    wire [4:0]      id_addr_a, id_addr_b;
    wire [6:0]      id_opcode;
    //EX wire
    wire            ex_reg_we, ex_a_sel, ex_b_sel, ex_mem_we, ex_mem_re;
    wire [1:0]      ex_wb_sel;
    wire [2:0]      ex_funct3;
    wire [3:0]      ex_alu_sel;
    wire [4:0]      ex_addr_a, ex_addr_b, ex_addr_d;             
    wire [31:0]     ex_pc, ex_pc4, ex_data_a, ex_data_b, ex_imm;
    wire [6:0]      ex_opcode;
    //MA wire
    wire            ma_reg_we, ma_mem_we, ma_mem_re;
    wire [1:0]      ma_wb_sel;
    wire [2:0]      ma_funct3;
    wire [4:0]      ma_addr_d;
    wire [31:0]     ma_alu_result, ma_alu_data_b, ma_pc4, ma_pc;
    wire [6:0]      ma_opcode;
    //WB wire
    wire            wb_reg_we;
    wire [1:0]      wb_wb_sel;
    wire [4:0]      wb_addr_d;
    wire [31:0]     wb_data_r;
    wire [31:0]     wb_alu_result;
    wire [31:0]     wb_pc4;
    wire [31:0]     wb_data_wb;
    //directed access wire
    wire [31:0]     ex_alu_result;//, ma_data_r;
    //forwarding wire
    wire [1:0]      fwd_alu_sel_a, fwd_alu_sel_b;
    wire [1:0]      fwd_br_sel_a, fwd_br_sel_b;
    //stall & flush wire
    wire            id_stall_load, id_stall_jmp, axi_stall_en;
    wire            id_flush_final, ex_flush_final, ex_flush_load, ma_flush_final;
    
    wire            sys_single_start;
    reg             start_pulse_reg, start_pulse_reg_r;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            start_pulse_reg     <= 1'b0;
            start_pulse_reg_r   <= 1'b0;
        end
        else begin
            start_pulse_reg     <= s_axi_start_i;
            start_pulse_reg_r   <= start_pulse_reg;
        end
    end
    assign sys_single_start = (start_pulse_reg && !start_pulse_reg_r) ? 1'b1 : 1'b0;
    
    assign m_axi_reg_we_o = ma_reg_we;
    assign m_axi_addr_d_o = ma_addr_d;
    
    assign id_stall_jmp = ( id_inst[6:0] == 7'b1100011 ||   // Branch
                            id_inst[6:0] == 7'b1101111 ||   // JAL
                            id_inst[6:0] == 7'b1100111      // JALR
                          ) ? 1'b1 : 1'b0;
    assign id_stall_final   = (id_stall_jmp || id_stall_load || !s_axi_start_i);
    assign id_flush_final   = ((id_stall_jmp && !id_stall_load) || if_pc_sel || m_axi_stall_i)? 1'b1 : 1'b0;
    assign ex_flush_final   = (ex_flush_load  || if_pc_sel || m_axi_stall_i)? 1'b1 : 1'b0; //taidao 13/5 add ex_flush from FWD
    assign ma_flush_final   = (m_axi_stall_i == 1'b1); //taidao 16/5
    
    IF_STAGE #(.RV32I_IMEM_DEPTH(RV32I_IMEM_DEPTH))    U_IF_STAGE(
                            .clk            ( clk               ),
                            .rst_n          ( rst_n             ),
                            .s_axi_wr_en_i  ( s_axi_imem_we_i   ),
                            .s_axi_addr_i   ( s_axi_imem_addr_i ),
                            .s_axi_data_i   ( s_axi_imem_data_i ),
                            .m_axi_stall_i  ( m_axi_stall_i     ),
                            .m_axi_pc_i     ( m_axi_pc_stall    ),
                            .local_stall_i  ( id_stall_final    ),
                            .flush_i        ( id_flush_final    ),
                            .pc_sel_i       ( if_pc_sel         ),
                            .alu_i          ( ex_alu_result     ),

                            .inst_o         ( id_inst           ),
                            .pc_o           ( id_pc             ),
                            .pc4_o          ( id_pc4            ),
                            .s_axi_id_pc_o  ( s_axi_id_pc_o     ),
                            .s_axi_id_inst_o( s_axi_id_inst_o   )
    );    
                       
    ID_STAGE    U_ID_STAGE(
                            .clk            ( clk           ),
                            .rst_n          ( rst_n         ),
                            .flush_i        ( ex_flush_final),
                            .inst_i         ( id_inst       ),
                            .pc_i           ( id_pc         ),
                            .pc4_i          ( id_pc4        ),
                            .reg_we_i       ( wb_reg_we     ),
                            .addr_d_i       ( wb_addr_d     ),
                            .data_d_i       ( wb_data_wb    ),
                            .m_axi_reg_we_i ( m_axi_reg_we_i  ), 
                            .m_axi_addr_d_i ( m_axi_addr_d_i  ), 
                            .m_axi_data_d_i ( m_axi_data_d_i  ), 
                            .fwd_br_sel_a_i ( fwd_br_sel_a  ),
                            .fwd_br_sel_b_i ( fwd_br_sel_b  ),
                            .ex_alu_result_i( ex_alu_result ),
                            .ma_alu_result_i( ma_alu_result ),
                            .wb_result_i    ( wb_data_wb    ),
                            
                            .pc_o           ( ex_pc         ),
                            .pc4_o          ( ex_pc4        ), 
                            .data_a_o       ( ex_data_a     ),
                            .data_b_o       ( ex_data_b     ),
                            .imm_o          ( ex_imm        ),    
                            .addr_a_o       ( ex_addr_a     ), //for fwd unit
                            .addr_b_o       ( ex_addr_b     ), //for fwd unit
                            .addr_d_o       ( ex_addr_d     ),
                            .reg_we_o       ( ex_reg_we     ), 
                            .a_sel_o        ( ex_a_sel      ), 
                            .b_sel_o        ( ex_b_sel      ), 
                            .mem_we_o       ( ex_mem_we     ),
                            .mem_re_o       ( ex_mem_re     ), 
                            .alu_sel_o      ( ex_alu_sel    ),
                            .wb_sel_o       ( ex_wb_sel     ),
                            .funct3_o       ( ex_funct3     ),
                            .opcode_o       ( ex_opcode     ),
                            .opcode_cur_o   ( id_opcode     ),
                            .addr_a_cur_o   ( id_addr_a     ), 
                            .addr_b_cur_o   ( id_addr_b     ),
                            .pc_sel_o       ( if_pc_sel     )
                        );
    EX_STAGE    U_EX_STAGE(
                            .clk            ( clk           ),
                            .rst_n          ( rst_n         ),
                            .flush_i        ( ma_flush_final), //taidao added 16/5
                            .pc_i           ( ex_pc         ),
                            .pc4_i          ( ex_pc4        ),
                            .data_a_i       ( ex_data_a     ),
                            .data_b_i       ( ex_data_b     ), 
                            .imm_i          ( ex_imm        ), 
                            .ma_alu_result_i( ma_alu_result ),
                            .wb_data_wb_i   ( wb_data_wb    ),
                            .addr_d_i       ( ex_addr_d     ),
                            .reg_we_i       ( ex_reg_we     ),
                            .a_sel_i        ( ex_a_sel      ),
                            .b_sel_i        ( ex_b_sel      ),
                            .mem_we_i       ( ex_mem_we     ),   
                            .mem_re_i       ( ex_mem_re     ), 
                            .alu_sel_i      ( ex_alu_sel    ),
                            .wb_sel_i       ( ex_wb_sel     ),
                            .funct3_i       ( ex_funct3     ),
                            .fwd_sel_a_i    ( fwd_alu_sel_a ),
                            .fwd_sel_b_i    ( fwd_alu_sel_b ),
                            .opcode_i       ( ex_opcode     ),
                            
                            .reg_we_o       ( ma_reg_we     ),
                            .mem_we_o       ( ma_mem_we     ),
                            .mem_re_o       ( ma_mem_re     ),
                            .wb_sel_o       ( ma_wb_sel     ),
                            .funct3_o       ( ma_funct3     ),
                            .alu_result_o   ( ma_alu_result ),
                            .ex_alu_result_o( ex_alu_result ), //direct alu result output
                            .data_b_o       ( ma_alu_data_b ),
                            .pc_o           ( ma_pc         ), //need check
                            .pc4_o          ( ma_pc4        ),
                            .addr_d_o       ( ma_addr_d     ),
                            .opcode_o       ( ma_opcode     )
                        );
    MA_STAGE #(.RV32I_DMEM_DEPTH(RV32I_DMEM_DEPTH)) U_MA_STAGE (
                            .clk            ( clk           ),
                            .rst_n          ( rst_n         ),
                            .reg_we_i       ( ma_reg_we     ),
                            .mem_we_i       ( ma_mem_we     ),
                            .mem_re_i       ( ma_mem_re     ),
                            .wb_sel_i       ( ma_wb_sel     ),
                            .funct3_i       ( ma_funct3     ),
                            .alu_result_i   ( ma_alu_result ),
                            .data_w_i       ( ma_alu_data_b ),
                            .pc4_i          ( ma_pc4        ),
                            .addr_d_i       ( ma_addr_d     ), //for fwd unit
                            .opcode_i       ( ma_opcode     ),
                            
                            .reg_we_o           ( wb_reg_we     ),
                            .wb_sel_o           ( wb_wb_sel     ),
                            .alu_result_o       ( wb_alu_result ),
                            .data_r_o           ( wb_data_r     ),
//                            .dmem_data_r_o      ( ma_data_r     ),
                            .pc4_o              ( wb_pc4        ),
                            .addr_d_o           ( wb_addr_d     ), //for fwd unit
                            .m_axi_addr_o       ( m_axi_addr_o  ),
                            .m_axi_data_w_o     ( m_axi_data_w_o),
                            .m_axi_mem_we_o     ( m_axi_mem_we_o), 
                            .m_axi_funct3_o     ( m_axi_funct3_o),  
                            .m_axi_init_o       ( m_axi_init_o  ),
                            .s_axi_dmem_re_i    ( s_axi_dmem_re_i       ), //taidao added 24/5
                            .s_axi_dmem_addr_i  ( s_axi_dmem_addr_i     ), //taidao added 24/5
                            .s_axi_dmem_data_o  ( s_axi_dmem_data_r_o   )  //taidao added 24/5
                        );
                       
    WB_STAGE U_WB_STAGE(
                            .wb_sel_i       ( wb_wb_sel     ),
                            .data_r_i       ( wb_data_r     ),
                            .alu_result_i   ( wb_alu_result ),
                            .pc4_i          ( wb_pc4        ), 
                            .data_wb_o      ( wb_data_wb    )
                        );
    FOWARDING_UNIT U_FOWARDING_UNIT(
                            .id_rs1_i       ( id_addr_a     ),
                            .id_rs2_i       ( id_addr_b     ),
                            .ex_rs1_i       ( ex_addr_a     ), 
                            .ex_rs2_i       ( ex_addr_b     ), 
                            .ex_rd_i        ( ex_addr_d     ),
                            .ma_rd_i        ( ma_addr_d     ), 
                            .wb_rd_i        ( wb_addr_d     ),
                            .ex_reg_we_i    ( ex_reg_we     ),
                            .ma_reg_we_i    ( ma_reg_we     ),
                            .wb_reg_we_i    ( wb_reg_we     ),
                            
                            .alu_sel_a_o    ( fwd_alu_sel_a ), 
                            .alu_sel_b_o    ( fwd_alu_sel_b ),
                            .br_sel_a_o     ( fwd_br_sel_a  ),
                            .br_sel_b_o     ( fwd_br_sel_b  )
                        );
    HAZARD_HANDLER U_HAZARD_HANDLER(
                            .id_opcode_i    ( id_opcode     ),
                            .ex_opcode_i    ( ex_opcode     ),
                            .ma_opcode_i    ( ma_opcode     ),
                            .ex_reg_we_i    ( ex_reg_we     ),
                            .ma_reg_we_i    ( ma_reg_we     ),
                            .id_rs1_i       ( id_addr_a     ),
                            .id_rs2_i       ( id_addr_b     ),
                            .ex_rd_i        ( ex_addr_d     ),
                            .ma_rd_i        ( ma_addr_d     ),
                            .m_axi_stall_i  ( m_axi_stall_i ),
                            .pc4_i          ( ma_pc4        ),
                            .pc_o           ( m_axi_pc_stall),
                            .id_stall_load_o( id_stall_load ),
                            .ex_flush_load_o( ex_flush_load )
                    );

endmodule


