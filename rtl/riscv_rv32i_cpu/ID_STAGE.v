`timescale 1ns / 1ps
module ID_STAGE (
    clk,
    rst_n,
    flush_i,
    inst_i,
    pc_i,
    pc4_i,
    reg_we_i,
    addr_d_i,
    data_d_i,
    m_axi_reg_we_i,
    m_axi_addr_d_i,
    m_axi_data_d_i,
    fwd_br_sel_a_i,
    fwd_br_sel_b_i,
    ex_alu_result_i,
    ma_alu_result_i,
    wb_result_i,
    pc_o,
    pc4_o, 
    data_a_o,
    data_b_o,
    imm_o,    
    addr_a_o,
    addr_b_o, 
    addr_d_o,
    reg_we_o, 
    a_sel_o, 
    b_sel_o, 
    mem_we_o,
    mem_re_o,
    alu_sel_o,
    wb_sel_o,
    funct3_o,
    opcode_o,
    opcode_cur_o,
    addr_a_cur_o,
    addr_b_cur_o,
    pc_sel_o
);
    input               clk, rst_n;
    input               flush_i;
    input [31:0]        inst_i, pc_i, pc4_i;
    input               reg_we_i, m_axi_reg_we_i;
    input [4:0]         addr_d_i, m_axi_addr_d_i;
    input [31:0]        data_d_i, m_axi_data_d_i;
    input [1:0]         fwd_br_sel_a_i, fwd_br_sel_b_i;
    input [31:0]        ex_alu_result_i, ma_alu_result_i, wb_result_i;//, ma_data_r_i;
    output reg [31:0]   pc_o, pc4_o, data_a_o, data_b_o, imm_o;    
    output [4:0]        addr_a_cur_o, addr_b_cur_o;
    output reg [4:0]    addr_a_o, addr_b_o, addr_d_o;
    output reg          pc_sel_o, reg_we_o, a_sel_o, b_sel_o, mem_we_o, mem_re_o;
    output reg [3:0]    alu_sel_o;
    output reg [1:0]    wb_sel_o;
    output reg [2:0]    funct3_o;
    output reg [6:0]    opcode_o;
    output [6:0]        opcode_cur_o;
    //reg wire
    reg    [4:0]        addr_a, addr_b; //taidao changed assign => always comb
    wire   [4:0]        addr_d;
    wire   [31:0]       reg_data_a, br_data_a, reg_data_b, br_data_b;
    //controller wire
    wire                pc_sel, reg_we, a_sel, b_sel, mem_we, mem_re,
                        br_un, br_eq, br_lt, br_ge;               
    wire   [2:0]        imm_sel;
    wire   [1:0]        wb_sel;
    wire   [3:0]        alu_sel;
    //ImmGen wire
    wire   [31:0]       imm_data;

    assign  addr_d = inst_i[11:7];
    assign  addr_a_cur_o = addr_a;
    assign  addr_b_cur_o = addr_b;
    assign  opcode_cur_o = inst_i[6:0];
    //Branch Compare
    assign br_eq = (br_data_a == br_data_b);
    assign br_lt = br_un ? (br_data_a < br_data_b) : ($signed(br_data_a) < $signed(br_data_b));
    assign br_ge = ~br_lt;
    always @(*) begin
        case (inst_i[6:0])
            7'b0110011: begin // R-type
                addr_a = inst_i[19:15];
                addr_b = inst_i[24:20];
            end
            7'b0010011: begin // I-type immediate
                addr_a = inst_i[19:15];
                addr_b = 5'b0;
            end
            7'b0000011: begin // I-type load
                addr_a = inst_i[19:15];
                addr_b = 5'b0;
            end
            7'b1100111: begin // I-type JALR
                addr_a = inst_i[19:15];
                addr_b = 5'b0;
            end
            7'b0100011: begin // S-type store
                addr_a = inst_i[19:15];
                addr_b = inst_i[24:20];
            end
            7'b1100011: begin // B-type branch
                addr_a = inst_i[19:15];
                addr_b = inst_i[24:20];
            end
            default: begin
                addr_a = 5'b0;
                addr_b = 5'b0;
            end
        endcase
    end
    REG_FILE    ID_REG_32x32(
                            .clk            ( clk           ),
                            .rst_n          ( rst_n         ),
                            .reg_we_i       ( reg_we_i      ), 
                            .addr_d_i       ( addr_d_i      ), 
                            .data_d_i       ( data_d_i      ), 
                            .axi_reg_we_i   ( m_axi_reg_we_i),
                            .axi_addr_d_i   ( m_axi_addr_d_i),
                            .axi_data_d_i   ( m_axi_data_d_i),
                            .addr_a_i       ( addr_a        ),
                            .addr_b_i       ( addr_b        ), 
                            .data_a_o       ( reg_data_a    ), 
                            .data_b_o       ( reg_data_b    )
                        );
    
    CONTROLLER  ID_CTRL(
                            .br_eq_i        ( br_eq         ), 
                            .br_lt_i        ( br_lt         ), 
                            .br_ge_i        ( br_ge         ),
                            .inst_i         ( inst_i        ), 
                            .pc_sel_o       ( pc_sel        ), 
                            .reg_we_o       ( reg_we        ),
                            .br_un_o        ( br_un         ), 
                            .a_sel_o        ( a_sel         ), 
                            .b_sel_o        ( b_sel         ), 
                            .mem_we_o       ( mem_we        ), 
                            .mem_re_o       ( mem_re        ),
                            .alu_sel_o      ( alu_sel       ), 
                            .imm_sel_o      ( imm_sel       ),
                            .wb_sel_o       ( wb_sel        )
                    );

    MUX41       ID_MUX41A   (  
                            .mux_sel_i      ( fwd_br_sel_a_i    ),
                            .in_1           ( reg_data_a        ),
                            .in_2           ( ex_alu_result_i   ),
                            .in_3           ( ma_alu_result_i   ),
                            .in_4           ( wb_result_i       ),
                            .out            ( br_data_a         )
                            );
    MUX41       ID_MUX41B   (  
                            .mux_sel_i      ( fwd_br_sel_b_i    ),
                            .in_1           ( reg_data_b        ),
                            .in_2           ( ex_alu_result_i   ),
                            .in_3           ( ma_alu_result_i   ),
                            .in_4           ( wb_result_i       ),
                            .out            ( br_data_b         )
                            );
                            
//    MUX81       ID_MUX51A   (  
//                            .mux_sel_i      ( fwd_br_sel_a_i    ),
//                            .in_1           ( reg_data_a        ),
//                            .in_2           ( ex_alu_result_i   ),
//                            .in_3           ( ma_alu_result_i   ),
//                            .in_4           ( ma_data_r_i       ),
//                            .in_5           ( wb_result_i       ),
//                            .out            ( br_data_a         )
//                            );
//    MUX81       ID_MUX51B   (  
//                            .mux_sel_i      ( fwd_br_sel_b_i    ),
//                            .in_1           ( reg_data_b        ),
//                            .in_2           ( ex_alu_result_i   ),
//                            .in_3           ( ma_alu_result_i   ),
//                            .in_4           ( ma_data_r_i       ),
//                            .in_5           ( wb_result_i       ),
//                            .out            ( br_data_b         )
//                            );
    
    
    IMM_GEN     ID_IMM_GEN  (
                            .inst_i         ( inst_i            ),
                            .imm_sel_i      ( imm_sel           ),
                            .imm_data_o     ( imm_data          )
                            );
                        
    //reg
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_i) begin
            pc_o        <= 32'b0;
            pc4_o       <= 32'b0;
            data_a_o    <= 32'b0;
            data_b_o    <= 32'b0;
            addr_a_o    <= 5'b0;
            addr_b_o    <= 5'b0;
            addr_d_o    <= 5'b0;
            imm_o       <= 32'b0;
            pc_sel_o    <= 1'b0;
            reg_we_o    <= 1'b0;
            a_sel_o     <= 1'b0;
            b_sel_o     <= 1'b0;
            alu_sel_o   <= 4'b0;
            mem_we_o    <= 1'b0;
            mem_re_o    <= 1'b0;
            wb_sel_o    <= 2'b0;
            funct3_o    <= 3'b0;
            opcode_o    <= 7'b0;
        end
        else begin
            pc_o        <= pc_i;
            pc4_o       <= pc4_i;
            data_a_o    <= reg_data_a;
            data_b_o    <= reg_data_b;
            addr_a_o    <= addr_a;
            addr_b_o    <= addr_b;
            addr_d_o    <= addr_d;
            imm_o       <= imm_data;
            pc_sel_o    <= pc_sel;
            reg_we_o    <= reg_we;
            a_sel_o     <= a_sel;
            b_sel_o     <= b_sel;
            alu_sel_o   <= alu_sel;
            mem_we_o    <= mem_we;
            mem_re_o    <= mem_re;
            wb_sel_o    <= wb_sel;
            funct3_o    <= inst_i[14:12];
            opcode_o    <= inst_i[6:0];
        end
    end

endmodule
