`timescale 1ns / 1ps
module FOWARDING_UNIT(
    id_rs1_i,
    id_rs2_i,
    ex_rs1_i, 
    ex_rs2_i, 
    ma_rd_i, 
    wb_rd_i,
    ex_rd_i,
    ex_reg_we_i,
    ma_reg_we_i,
//    ma_wb_sel_i,
    wb_reg_we_i,
    alu_sel_a_o, 
    alu_sel_b_o,
    br_sel_a_o,
    br_sel_b_o
);
    input [4:0]     id_rs1_i, id_rs2_i, ex_rs1_i, ex_rs2_i, ex_rd_i, ma_rd_i, wb_rd_i;
    input           ex_reg_we_i, ma_reg_we_i, wb_reg_we_i;
//    input [1:0]     ma_wb_sel_i;
    output [1:0]    alu_sel_a_o, alu_sel_b_o;
    output [1:0]    br_sel_a_o, br_sel_b_o;
    
//    wire            load_detect;
    
//    assign load_detect  =   (ma_wb_sel_i == 2'b00); //lw = store data from DMEM to REGISTER
    assign alu_sel_a_o  =   (ma_reg_we_i && (ex_rs1_i == ma_rd_i)) ? 2'b01 :
                            (wb_reg_we_i && (ex_rs1_i == wb_rd_i)) ? 2'b10 : 2'b00; 

    assign alu_sel_b_o  =   (ma_reg_we_i && (ex_rs2_i == ma_rd_i)) ? 2'b01 : 
                            (wb_reg_we_i && (ex_rs2_i == wb_rd_i)) ? 2'b10 : 2'b00;  
    
    assign br_sel_a_o   =   (ex_reg_we_i && (id_rs1_i == ex_rd_i)) ? 2'b01 : 
                            (ma_reg_we_i && (id_rs1_i == ma_rd_i)) ? 2'b10 :
                            (wb_reg_we_i && (id_rs1_i == wb_rd_i)) ? 2'b11 : 2'b00;
                                
    assign br_sel_b_o   =   (ex_reg_we_i && (id_rs2_i == ex_rd_i)) ? 2'b01 :
                            (ma_reg_we_i && (id_rs2_i == ma_rd_i)) ? 2'b10 :
                            (wb_reg_we_i && (id_rs2_i == wb_rd_i)) ? 2'b11 : 2'b00;                            
//    assign br_sel_a_o   =   (ex_reg_we_i && (id_rs1_i == ex_rd_i)) ? 3'b001 : 
//                            (ma_reg_we_i && (id_rs1_i == ma_rd_i) && !load_detect) ? 3'b010 :
//                            (ma_reg_we_i && (id_rs1_i == ma_rd_i) &&  load_detect) ? 3'b011 : 
//                            (wb_reg_we_i && (id_rs1_i == wb_rd_i)) ? 3'b100 : 3'b000;
                                
//    assign br_sel_b_o   =   (ex_reg_we_i && (id_rs2_i == ex_rd_i)) ? 3'b001 :
//                            (ma_reg_we_i && (id_rs2_i == ma_rd_i) && !load_detect) ? 3'b010 :
//                            (ma_reg_we_i && (id_rs2_i == ma_rd_i) &&  load_detect) ? 3'b011 :
//                            (wb_reg_we_i && (id_rs2_i == wb_rd_i)) ? 3'b100 : 3'b000;

endmodule





//`timescale 1ns / 1ps
//module FOWARDING_UNIT(
//    rst_n,
//    id_rs1_i,
//    id_rs2_i,
//    ex_rs1_i, 
//    ex_rs2_i, 
//    ma_rd_i, 
//    wb_rd_i,
//    ex_rd_i,
//    ex_reg_we_i,
//    ex_opcode_i, //taidao 13/5 added
//    ma_reg_we_i,
//    ma_wb_sel_i,
//    wb_reg_we_i,
//    alu_sel_a_o, 
//    alu_sel_b_o,
//    br_sel_a_o,
//    br_sel_b_o,
//    id_stall_load_o, //taidao 13/5 added
//    ex_flush_load_o  //taidao 13/5 added
//);
//    input           rst_n;
//    input [4:0]     id_rs1_i, id_rs2_i, ex_rs1_i, ex_rs2_i, ex_rd_i, ma_rd_i, wb_rd_i;
//    input [6:0]     ex_opcode_i;
//    input           ex_reg_we_i, ma_reg_we_i, wb_reg_we_i;
//    input [1:0]     ma_wb_sel_i;
//    output [1:0]    alu_sel_a_o, alu_sel_b_o, id_stall_load_o, ex_flush_load_o;
//    output [2:0]    br_sel_a_o, br_sel_b_o;
    
//    wire            load_hazard, load_detect;
    
//    assign load_detect  =   (ma_wb_sel_i == 2'b00); //lw = store data from DMEM to REGISTER
//    assign alu_sel_a_o  =   (ma_reg_we_i && (ex_rs1_i == ma_rd_i)) ? 2'b01 :
//                            (wb_reg_we_i && (ex_rs1_i == wb_rd_i)) ? 2'b10 : 2'b00; 

//    assign alu_sel_b_o  =   (ma_reg_we_i && (ex_rs2_i == ma_rd_i)) ? 2'b01 : 
//                            (wb_reg_we_i && (ex_rs2_i == wb_rd_i)) ? 2'b10 : 2'b00;  
                                
//    assign br_sel_a_o   =   (ex_reg_we_i && (id_rs1_i == ex_rd_i)) ? 3'b001 : 
//                            (ma_reg_we_i && (id_rs1_i == ma_rd_i) && !load_detect) ? 3'b010 :
//                            (ma_reg_we_i && (id_rs1_i == ma_rd_i) &&  load_detect) ? 3'b011 : 
//                            (wb_reg_we_i && (id_rs1_i == wb_rd_i)) ? 3'b100 : 3'b000;
                                
//    assign br_sel_b_o   =   (ex_reg_we_i && (id_rs2_i == ex_rd_i)) ? 3'b001 :
//                            (ma_reg_we_i && (id_rs2_i == ma_rd_i) && !load_detect) ? 3'b010 :
//                            (ma_reg_we_i && (id_rs2_i == ma_rd_i) &&  load_detect) ? 3'b011 :
//                            (wb_reg_we_i && (id_rs2_i == wb_rd_i)) ? 3'b100 : 3'b000;

////    example:
////    lw x1, 2(x2)
////    sub x3, x1, x2
////    load opcode = 0000011;
//    assign load_hazard = ((ex_opcode_i==7'b0000011) && (ex_reg_we_i) && ((id_rs1_i == ex_rd_i) || (id_rs2_i == ex_rd_i))) ? 1'b1 : 1'b0;
//    assign id_stall_load_o = load_hazard;
//    assign ex_flush_load_o = load_hazard;
    
//    //lw-branch hazard
////    example:
////    lw x1, 2(x2)
////    bne x1, x2, loop
//    //resolved using load_detect
//    //taidao end
//endmodule