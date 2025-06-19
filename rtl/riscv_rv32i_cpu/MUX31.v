`timescale 1ns / 1ps
module MUX31 (mux_sel, in_1, in_2, in_3, out);
    input   [31:0]  in_1, in_2, in_3;
    input   [1:0]   mux_sel;
    output  [31:0]  out;

    assign  out =   (mux_sel == 2'b00) ? in_1 :
                    (mux_sel == 2'b01) ? in_2 :
                    (mux_sel == 2'b10) ? in_3 : 32'b0;
endmodule
