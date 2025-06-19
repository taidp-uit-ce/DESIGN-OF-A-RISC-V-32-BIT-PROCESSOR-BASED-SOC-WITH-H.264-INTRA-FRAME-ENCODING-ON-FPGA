`timescale 1ns / 1ps
module MUX41 (
    mux_sel_i, 
    in_1, in_2, in_3, in_4,
    out
);
    input   [1:0]   mux_sel_i;
    input   [31:0]  in_1, in_2, in_3, in_4;
    output  [31:0]  out;

    assign  out =   (mux_sel_i == 2'b00) ? in_1 :
                    (mux_sel_i == 2'b01) ? in_2 :
                    (mux_sel_i == 2'b10) ? in_3 :
                    (mux_sel_i == 2'b11) ? in_4: 32'b0;
endmodule
