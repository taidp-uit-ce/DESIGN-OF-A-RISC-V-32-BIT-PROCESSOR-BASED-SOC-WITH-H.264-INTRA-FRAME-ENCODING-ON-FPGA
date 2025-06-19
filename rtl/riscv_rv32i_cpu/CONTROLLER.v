`timescale 1ns / 1ps
module CONTROLLER(
    br_eq_i,
    br_lt_i,
    br_ge_i,
	inst_i,
	pc_sel_o,
	reg_we_o,
	br_un_o,
	a_sel_o,
	b_sel_o,
	mem_we_o,
	mem_re_o,
	wb_sel_o,
	imm_sel_o,
	alu_sel_o
);
    input          br_eq_i, br_lt_i, br_ge_i;
	input  [31:0]  inst_i;
	output reg     pc_sel_o;
	output         reg_we_o, a_sel_o, b_sel_o, mem_we_o, mem_re_o, br_un_o;
	output [1:0]   wb_sel_o;
	output reg [2:0]   imm_sel_o;
	output reg [3:0]   alu_sel_o;
    
	localparam R_type        = 7'b0110011;
    localparam I_type        = 7'b0010011;
    localparam I_type_load   = 7'b0000011;
    localparam I_type_jalr   = 7'b1100111;
    localparam S_type        = 7'b0100011;
    localparam B_type        = 7'b1100011;
    localparam J_type        = 7'b1101111;
    localparam U_type_lui    = 7'b0110111;
    localparam U_type_auipc  = 7'b0010111;
    
    //alu
    localparam ALU_AND          = 4'b0000;
    localparam ALU_OR           = 4'b0001;
    localparam ALU_ADD          = 4'b0010;
    localparam ALU_SUB          = 4'b0011;
    localparam ALU_SLT          = 4'b0100;
    localparam ALU_NOR          = 4'b0101;
    localparam ALU_SL12         = 4'b0110;
    localparam ALU_XOR          = 4'b0111;
    localparam ALU_A_SL_B       = 4'b1000;
    localparam ALU_A_SR_B       = 4'b1001;
    localparam ALU_A_PLUS_B_SL  = 4'b1010;
    localparam ALU_SLTU         = 4'b1011;
    localparam ALU_SRA          = 4'b1100;
    localparam ALU_NO_OP        = 4'b1111;
	wire [6:0]     opcode;
	wire [2:0]     funct3;
	wire [6:0]     funct7;
	wire [4:0]     rd;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];
    assign rd     = inst_i[11:7];
//    wire illegal_instr;
//    assign illegal_instr = !(opcode == R_type || opcode == I_type || opcode == I_type_load || 
//                         opcode == I_type_jalr || opcode == S_type || opcode == B_type || 
//                         opcode == J_type || opcode == U_type_lui || opcode == U_type_auipc);

    //reg_we_o
    assign reg_we_o = ((rd != 5'b0) && ((opcode == R_type) || (opcode == I_type) || (opcode == I_type_load) || 
                       (opcode == I_type_jalr) || (opcode == J_type) || (opcode == U_type_lui) || (opcode == U_type_auipc))) ? 1'b1 : 1'b0;
    
    //a_sel_o
    assign a_sel_o = (opcode == B_type || opcode == J_type || opcode == U_type_auipc) ? 1'b1 : 1'b0;
    
    //b_sel_o
    assign b_sel_o = (opcode == R_type) ? 1'b0 : 1'b1;
    
    //mem_we_o
    assign mem_we_o = (opcode == S_type) ? 1'b1 : 1'b0;
    
    //mem_re_o
    assign mem_re_o = (opcode == I_type_load) ? 1'b1 : 1'b0;
    
    //wb_sel_o
    assign wb_sel_o = (opcode == I_type_load)?2'b00:(opcode == R_type || opcode == I_type || opcode == U_type_lui || opcode == U_type_auipc)?2'b01:
                      (opcode == J_type || opcode == I_type_jalr) ? 2'b10 : 2'b11;
                      
    //br_un_o (for branch command)
    assign br_un_o = ((opcode == B_type) && ((funct3 == 3'b110) || (funct3 == 3'b111))) ? 1'b1 : 1'b0; //bltu || bgeu

    //pc_sel
    always @(*) begin
        case(opcode)
            B_type: case(funct3)
                3'b000: pc_sel_o =  br_eq_i ;   //beq
                3'b001: pc_sel_o = !br_eq_i ;   //bne
                3'b100: pc_sel_o =  br_lt_i ;   //blt
                3'b101: pc_sel_o =  br_ge_i ;   //bge
                3'b110: pc_sel_o =  br_lt_i ;   //bltu
                3'b111: pc_sel_o = !br_lt_i ;   //bgeu
                default: pc_sel_o = 1'b0;
            endcase
            J_type, I_type_jalr:
                pc_sel_o = 1'b1;
            default:
                pc_sel_o = 1'b0;
        endcase
    end
    
    //imm_sel
    always @(*) begin
        case(opcode)
            I_type, I_type_load, I_type_jalr:
                imm_sel_o = 3'b000;
            S_type:
                imm_sel_o = 3'b010;
            B_type:
                imm_sel_o = 3'b100;
            J_type:
                imm_sel_o = 3'b001;
            U_type_auipc, U_type_lui:
                imm_sel_o = 3'b011;  
            default:
                imm_sel_o = 3'b111;
        endcase
    end
    
    //alu_sel_o
    always @(*) begin
		case(opcode)
				R_type: case(funct3)
				    3'b000: case(funct7)
				        7'b0000000: alu_sel_o = ALU_ADD; //add
				        7'b0100000: alu_sel_o = ALU_SUB; //sub
				        default:    alu_sel_o = ALU_NO_OP; //
				    endcase
				    3'b001:         alu_sel_o = ALU_A_SL_B; //sll
				    3'b010:         alu_sel_o = ALU_SLT; //slt
				    3'b011:         alu_sel_o = ALU_SLTU; //sltu
				    3'b100:         alu_sel_o = ALU_XOR; //xor
				    3'b101: case(funct7)
				        7'b0000000: alu_sel_o = ALU_A_SR_B; //srl
				        7'b0100000: alu_sel_o = ALU_SRA; //sra
				        default:    alu_sel_o = ALU_NO_OP; //
				    endcase
				    3'b110:         alu_sel_o = ALU_OR; //or
				    3'b111:         alu_sel_o = ALU_AND; //and
				endcase
				
				I_type:     case(funct3)
				    3'b000:         alu_sel_o = ALU_ADD; //addi
				    3'b001:         alu_sel_o = ALU_A_SL_B; //slli
				    3'b010:         alu_sel_o = ALU_SLT; //slti
				    3'b011:         alu_sel_o = ALU_SLTU; //sltiu
				    3'b100:         alu_sel_o = ALU_XOR; //xori
				    3'b101: case(inst_i[31:25]) //imm[11:5]
				        7'b0000000: alu_sel_o = ALU_A_SR_B; //srli
				        7'b0100000: alu_sel_o = ALU_SRA; //srai
				        default:    alu_sel_o = ALU_NO_OP; //
				            endcase
				    3'b110:         alu_sel_o = ALU_OR; //ori
				    3'b111:         alu_sel_o = ALU_AND; //andi
				endcase
				
				S_type, B_type, I_type_load, J_type, I_type_jalr: 
				    alu_sel_o = ALU_ADD;
				    
				U_type_lui:
				    alu_sel_o = ALU_SL12; //lui
				
				U_type_auipc:
				    alu_sel_o = ALU_A_PLUS_B_SL; //auipc
				
				default:
					alu_sel_o = ALU_NO_OP; 
		endcase
	end
endmodule
