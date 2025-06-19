`timescale 1ns / 1ps
module EX_STAGE(
    clk,
    rst_n,
    flush_i,
    pc_i,
    pc4_i,
    data_a_i,
    data_b_i, 
    imm_i, 
    ma_alu_result_i,
    wb_data_wb_i,
    addr_d_i,
    reg_we_i,
    a_sel_i,
    b_sel_i,
    mem_we_i, 
    mem_re_i,  
    alu_sel_i,
    wb_sel_i,
    funct3_i,
    fwd_sel_a_i,
    fwd_sel_b_i,
    opcode_i,
    reg_we_o,
    mem_we_o,
    mem_re_o,
    wb_sel_o,
    funct3_o,
    alu_result_o,
    ex_alu_result_o,
    data_b_o,
    pc_o,
    pc4_o,
    addr_d_o,
    opcode_o
);
    input               clk, rst_n, flush_i;
    input [31:0]        pc_i, pc4_i,
                        data_a_i, data_b_i, 
                        imm_i, ma_alu_result_i, wb_data_wb_i;
    input [ 4:0]        addr_d_i;
    input               reg_we_i, a_sel_i, b_sel_i, mem_we_i, mem_re_i;
    input [ 3:0]        alu_sel_i;
    input [ 2:0]        funct3_i;
    input [ 1:0]        wb_sel_i, fwd_sel_a_i, fwd_sel_b_i;
    input [ 6:0]        opcode_i;
    ///
    output reg           reg_we_o, mem_we_o, mem_re_o;
    output reg  [ 1:0]   wb_sel_o;
    output reg  [ 2:0]   funct3_o;
    output reg  [31:0]   alu_result_o, pc_o, pc4_o;
    output      [31:0]   ex_alu_result_o;
    output reg  [31:0]   data_b_o;
    output reg  [ 4:0]   addr_d_o;
    output reg  [ 6:0]   opcode_o;
    
    wire   [31:0]   alu_in_a, 
                    alu_in_b, 
                    alu_result,
                    fwd_data_a, 
                    fwd_data_b;
    assign          ex_alu_result_o = alu_result;
    MUX41   EX_MUX41_A(
                        .mux_sel_i      ( fwd_sel_a_i    ), 
                        .in_1           ( data_a_i       ), 
                        .in_2           ( ma_alu_result_i), 
                        .in_3           ( wb_data_wb_i   ), 
                        .in_4           ( 32'b0          ),
                        .out            ( fwd_data_a     )
                    );
    MUX41   EX_MUX41_B(
                        .mux_sel_i      ( fwd_sel_b_i    ), 
                        .in_1           ( data_b_i       ), 
                        .in_2           ( ma_alu_result_i), 
                        .in_3           ( wb_data_wb_i   ),
                        .in_4           ( 32'b0          ),
                        .out            ( fwd_data_b     )
                    );
    MUX21   EX_MUX21_A(
                        .mux_sel_i      ( a_sel_i    ), 
                        .in_1           ( fwd_data_a ), 
                        .in_2           ( pc_i       ), 
                        .out            ( alu_in_a   )
                    );
    MUX21   EX_MUX21_B(
                        .mux_sel_i      ( b_sel_i    ), 
                        .in_1           ( fwd_data_b ), 
                        .in_2           ( imm_i      ), 
                        .out            ( alu_in_b   )
                    );
    ALU     EX_ALU  (
                        .A              ( alu_in_a   ), 
                        .B              ( alu_in_b   ), 
                        .alu_sel_i      ( alu_sel_i  ), 
                        .alu_result_o   ( alu_result )
                    );
                    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_i) begin
            addr_d_o        <=  5'b0;
            reg_we_o        <=  1'b0;
            mem_we_o        <=  1'b0;
            mem_re_o        <=  1'b0;
            wb_sel_o        <=  2'b0;
            funct3_o        <=  3'b0;
            alu_result_o    <= 32'b0;
            data_b_o        <= 32'b0;
            pc4_o           <= 32'b0;
            pc_o            <= 32'b0;
            opcode_o        <=  7'b0;
        end
        else begin
            addr_d_o        <= addr_d_i;
            reg_we_o        <= reg_we_i;
            mem_we_o        <= mem_we_i;
            mem_re_o        <= mem_re_i;
            wb_sel_o        <= wb_sel_i;
            funct3_o        <= funct3_i;
            alu_result_o    <= alu_result;
            data_b_o        <= fwd_data_b;
            pc4_o           <= pc4_i;        
            pc_o            <= pc_i; 
            opcode_o        <= opcode_i;                       
        end
    end

endmodule

