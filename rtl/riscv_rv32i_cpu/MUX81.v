`timescale 1ns / 1ps
module MUX81 (
    mux_sel_i, 
    in_1, in_2, in_3, in_4, in_5,// in_6, in_7, in_8,
    out
);
    input   [2:0]   mux_sel_i;
    input   [31:0]  in_1, in_2, in_3, in_4, in_5;//, in_6, in_7, in_8;
    output  [31:0]  out;
    
    assign out = (mux_sel_i == 3'b000) ? in_1 :
                (mux_sel_i == 3'b001) ? in_2 :
                (mux_sel_i == 3'b010) ? in_3 :
                (mux_sel_i == 3'b011) ? in_4 :
                (mux_sel_i == 3'b100) ? in_5 : 32'b0;
//                (mux_sel_i == 3'b101) ? in_6 :
//                (mux_sel_i == 3'b110) ? in_7 :
//                (mux_sel_i == 3'b111) ? in_8 : 32'b0;
                
endmodule
