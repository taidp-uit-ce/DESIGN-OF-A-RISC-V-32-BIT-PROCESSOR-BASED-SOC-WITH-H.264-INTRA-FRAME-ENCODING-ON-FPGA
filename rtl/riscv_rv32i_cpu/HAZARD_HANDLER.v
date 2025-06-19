`timescale 1ns / 1ps
module HAZARD_HANDLER(
    id_opcode_i,
    ex_opcode_i,
    ma_opcode_i,
    ex_reg_we_i,
    ma_reg_we_i,
    id_rs1_i,
    id_rs2_i,
    ex_rd_i,
    ma_rd_i,
    m_axi_stall_i,
    pc4_i,
    pc_o,
    id_stall_load_o,
    ex_flush_load_o
);
    input           m_axi_stall_i;
    input   [31:0]  pc4_i;
    output  [31:0]  pc_o;
    input [6:0]     id_opcode_i, ex_opcode_i, ma_opcode_i;
    input           ex_reg_we_i, ma_reg_we_i;
    input [4:0]     id_rs1_i, id_rs2_i, ex_rd_i, ma_rd_i;
    output          id_stall_load_o, ex_flush_load_o;
    
    reg [31:0]      pc_hold;
    wire            load_hazard, load_detect, br_detect, load_hz_ex, load_hz_ma;
    //use flipflop (cause clk delay)
//    always @(posedge clk or negedge rst_n) begin
//        if(!rst_n)
//            pc_hold <= 32'b0;
//        else if(m_axi_stall_i)
//            pc_hold <= pc_hold
//        else
//            pc_hold <= pc4_i;
//    end
    
    //use latch
    always @(*) begin
        if(m_axi_stall_i)
            pc_hold = pc_hold;
        else
            pc_hold = pc4_i;
    end
    assign pc_o     =   pc_hold;
    
    //    example:
    //    lw x1, 2(x2)
    //    sub x3, x1, x2
    //    load opcode = 0000011;
    //    example:
    //    lw x1, 2(x2)
    //    bne x1, x2, loop
    assign load_detect  = (ex_opcode_i==7'b0000011)||(ma_opcode_i==7'b0000011) ? 1'b1 : 1'b0;
    assign br_detect    = (id_opcode_i==7'b1100011) ? 1'b1 : 1'b0;
    assign load_hz_ex   = (ex_reg_we_i) && ((id_rs1_i == ex_rd_i) || (id_rs2_i == ex_rd_i)) ? 1'b1 : 1'b0;
    assign load_hz_ma   = (ma_reg_we_i) && ((id_rs1_i == ma_rd_i) || (id_rs2_i == ma_rd_i)) ? 1'b1 : 1'b0;
    assign load_hazard  = (load_detect && (load_hz_ex || (load_hz_ma && br_detect))) ? 1'b1 : 1'b0;
    assign id_stall_load_o = load_hazard;
    assign ex_flush_load_o = load_hazard;

endmodule
