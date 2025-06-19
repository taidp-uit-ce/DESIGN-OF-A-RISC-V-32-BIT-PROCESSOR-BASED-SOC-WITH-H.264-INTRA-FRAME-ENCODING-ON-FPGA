`timescale 1ns / 1ps
module IF_STAGE #(RV32I_IMEM_DEPTH = 1)(
    clk             ,
    rst_n           ,
    s_axi_wr_en_i   ,
    s_axi_addr_i    ,
    s_axi_data_i    ,
    m_axi_stall_i   ,
    m_axi_pc_i      ,
    local_stall_i   , //taidao 13/5
    flush_i         ,
    pc_sel_i        ,
    alu_i           ,
    inst_o          ,
    pc_o            ,
    pc4_o           ,
    s_axi_id_pc_o   ,
    s_axi_id_inst_o
);
    input               clk, rst_n;
    input               local_stall_i, m_axi_stall_i, flush_i;
    input               pc_sel_i;
    input  [31:0]       alu_i, m_axi_pc_i;
    input               s_axi_wr_en_i;
    input [31:0]        s_axi_addr_i, s_axi_data_i;
    output reg [31:0]   inst_o, pc_o, pc4_o;
    output [31:0]       s_axi_id_pc_o, s_axi_id_inst_o;
    
	wire   [31:0]       pc_next, pc4_cur, imem_addr, inst;          
	reg    [31:0]       pc_cur;
	
	assign s_axi_id_pc_o   = pc_cur;
	assign s_axi_id_inst_o = inst;
	
    assign  imem_addr    = pc_cur >> 2; 
//    assign  imem_addr    = (m_axi_stall_i) ? (m_axi_pc_i>>2) : pc_cur>>2; 
    assign  pc4_cur = pc_cur + 32'd4;
    assign  pc_next = (pc_sel_i) ? alu_i : pc4_cur;
    
    always @(posedge clk or negedge rst_n) begin
		if(!rst_n)
			pc_cur <= 32'b0;
	    else begin
            if(local_stall_i) //jump: b-type, jar, jalr
                pc_cur <= pc_cur;
            else if(m_axi_stall_i) //delay by axi-interface
                pc_cur <= m_axi_pc_i; //ma_pc4
            else
                pc_cur <= pc_next;
        end
	end                
                          
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_i) begin
            pc_o    <= 32'b0;
            inst_o  <= 32'b0;
            pc4_o   <= 32'b0;
        end
        else if (local_stall_i) begin //taidao added 13/2
            pc_o    <= pc_o;
            inst_o  <= inst_o;
            pc4_o   <= pc4_o;
        end
//        else if (m_axi_stall_i) begin
//            pc_o    <= m_axi_pc_i;
//            inst_o  <= inst;
//            pc4_o   <= m_axi_pc_i + 32'd4;
//        end
        else begin
            pc_o    <= pc_cur;
            inst_o  <= inst;
            pc4_o   <= pc4_cur;
        end 
    end  
    
    IMEM #(.RV32I_IMEM_DEPTH(RV32I_IMEM_DEPTH))  IF_IMEM (
                .clk            ( clk           ),
                .s_axi_wr_en_i  ( s_axi_wr_en_i ),
                .s_axi_addr_i   ( s_axi_addr_i  ),
                .s_axi_data_i   ( s_axi_data_i  ),
                .addr_i         ( imem_addr     ),
                .inst_o         ( inst          )
                ); 
    
endmodule
/*
`timescale 1ns / 1ps
module IF_STAGE(
    clk             ,
    rst_n           ,
    stall_jmp_i     ,
    m_axi_stall_i     ,
    flush_i         ,
    pc_sel_i        ,
    alu_i           ,
    m_axi_pc_i        ,
    inst_o          ,
    pc_o            ,
    pc4_o
);
    input               clk, rst_n;
    input               stall_jmp_i, m_axi_stall_i, flush_i;
    input               pc_sel_i;
    input  [31:0]       alu_i, m_axi_pc_i;
    output reg [31:0]   inst_o, pc_o, pc4_o;
    
	wire   [31:0]  pc_next, pc4_cur, addr, inst;          
	wire           pc_sel;
	reg    [31:0]  pc_cur;
	
    assign  pc_sel  = ((pc_sel_i === 1'bx) || (pc_sel_i === 1'bz))?1'b0:pc_sel_i;   
    assign  addr    = {2'b0, pc_cur[31:2]}; 
    assign  pc4_cur = pc_cur + 32'd4;
    assign  pc_next = (!pc_sel)?pc4_cur:alu_i;
    
    always @(posedge clk or negedge rst_n) begin
		if(!rst_n)
			pc_cur <= 32'b0;
	    else begin
            if(stall_jmp_i) //jump: b-type, jar, jalr
                pc_cur <= pc_cur;
            else if(m_axi_stall_i) //delay by axi-interface
                pc_cur <= m_axi_pc_i; //ma_pc4
            else
                pc_cur <= pc_next;
        end
	end                
	               
	IMEM   IF_IMEM (.addr_i(addr), .inst_o(inst)); 
                                 
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_i) begin
            pc_o    <= 32'b0;
            inst_o  <= 32'b0;
            pc4_o   <= 32'b0;
        end
        else begin
            pc_o    <= pc_cur;
            inst_o  <= inst;
            pc4_o   <= pc4_cur;
        end 
    end  
endmodule

*/