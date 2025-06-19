`timescale 1ns / 1ps
module WB_STAGE(
    wb_sel_i,
    data_r_i,
    alu_result_i,
    pc4_i,
    data_wb_o
);
    input [1:0]         wb_sel_i;
    input [31:0]        data_r_i;
    input [31:0]        alu_result_i;
    input [31:0]        pc4_i;
    output [31:0]       data_wb_o;

    MUX41  U_WB_MUX31(
                        .mux_sel_i  ( wb_sel_i      ), 
                        .in_1       ( data_r_i      ), 
                        .in_2       ( alu_result_i  ), 
                        .in_3       ( pc4_i         ), 
                        .in_4       ( 32'b0         ),
                        .out        ( data_wb_o     )
                    ); 

endmodule
