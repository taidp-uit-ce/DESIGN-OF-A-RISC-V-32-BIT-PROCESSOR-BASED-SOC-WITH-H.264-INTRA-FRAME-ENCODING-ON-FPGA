module ALU (A, B, alu_sel_i, alu_result_o);
	input [3:0]        alu_sel_i;
	input [31:0]       A, B;
	output reg [31:0]  alu_result_o;

	always @(*) begin
		case(alu_sel_i)
			4'b0000: alu_result_o = A & B;
			4'b0001: alu_result_o = A | B;
			4'b0010: alu_result_o = A + B;
			4'b0011: alu_result_o = A - B;
			4'b0100: alu_result_o = ($signed(A) < $signed(B))?32'd1:32'd0;
			4'b0101: alu_result_o = !(A|B);
			4'b0110: alu_result_o = B << 12;
			4'b0111: alu_result_o = A ^ B;
			4'b1000: alu_result_o = A << B[4:0];
			4'b1001: alu_result_o = A >> B[4:0]; 
			4'b1010: alu_result_o = A + (B << 12); //auipc
			4'b1011: alu_result_o = ($unsigned(A) < $unsigned(B))?32'd1:32'd0;
			4'b1100: begin
			     if (A[31] == 1'b0)
                    alu_result_o = A >> B[4:0];
                 else
                    alu_result_o = ~((~A) >> B[4:0]); //sra
			end
			default: alu_result_o = 0;
		endcase
	end
endmodule