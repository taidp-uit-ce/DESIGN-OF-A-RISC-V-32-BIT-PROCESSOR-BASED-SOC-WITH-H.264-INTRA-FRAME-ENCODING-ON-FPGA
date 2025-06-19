module MUX21(mux_sel_i, in_1, in_2, out);
	input          mux_sel_i;
	input [31:0]   in_1;
	input [31:0]   in_2;
	output [31:0]  out;

	assign         out = (mux_sel_i==1'b0)?in_1:in_2;
endmodule