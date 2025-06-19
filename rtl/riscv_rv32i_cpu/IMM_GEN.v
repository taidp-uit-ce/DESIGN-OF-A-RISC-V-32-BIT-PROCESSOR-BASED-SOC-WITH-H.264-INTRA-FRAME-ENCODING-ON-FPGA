module IMM_GEN(
    inst_i,
    imm_sel_i,
    imm_data_o
);
	input [31:0]   inst_i;
	input [2:0]    imm_sel_i;
	output [31:0]  imm_data_o;
	
	reg [31:0]     imm_reg;
	always @(*) begin
        case (imm_sel_i)
            //I - type
            3'b000: imm_reg = {{21{inst_i[31]}}, inst_i[30:20]};
            
            //J - type
            3'b001: imm_reg = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            
            //S - type 
            3'b010: imm_reg = {{21{inst_i[31]}}, inst_i[30:25], inst_i[11:7]};
            
            //U - type
            3'b011: imm_reg = {12'b0, inst_i[31:12]};
            
            //B - type
            3'b100: imm_reg = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8] ,1'b0};
            
            default: imm_reg = 32'b0;
        endcase
	end
	assign imm_data_o = imm_reg;
endmodule