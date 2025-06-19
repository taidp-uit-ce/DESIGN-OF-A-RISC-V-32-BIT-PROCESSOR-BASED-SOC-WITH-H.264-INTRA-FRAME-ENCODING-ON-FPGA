module DMEM #(parameter RV32I_DMEM_DEPTH = 4)(
    clk, rst_n,
    mem_we_i,
    mem_re_i,
    funct3_i,
    addr_i,
    data_w_i,
    data_r_o,
    s_axi_re_i,
    s_axi_addr_i,
    s_axi_data_o
);
    input               clk, rst_n;
    input               mem_we_i, mem_re_i, s_axi_re_i;
    input [2:0]         funct3_i;
    input [31:0]        addr_i;
    input [31:0]        data_w_i, s_axi_addr_i;
    output reg [31:0]   data_r_o, s_axi_data_o;
    
    // Calculate memory depth in words (32-bit)
    localparam DMEM_DEPTH_WORDS = (RV32I_DMEM_DEPTH * 1024) / 4;
    localparam ADDR_WIDTH = $clog2(DMEM_DEPTH_WORDS);
    
    (* ram_style = "block" *)
    (* ram_decomp = "power" *)
    reg [31:0]              MA_DMEM [DMEM_DEPTH_WORDS-1:0];
    reg [31:0]              raw_read_data;
    wire [ADDR_WIDTH-1:0]   word_addr;
    wire [1:0]              byte_offset;
    reg [1:0]               byte_offset_r;
    reg [2:0]               funct3_r;
    assign word_addr    = addr_i[ADDR_WIDTH+1:2];
    assign byte_offset  = addr_i[1:0];
    
    always @(posedge clk) begin
        if (mem_we_i) begin
            case(funct3_i)
                3'b000: begin //sb
                    case(byte_offset)
                        2'b00: MA_DMEM[word_addr][7:0]      <= data_w_i[7:0];   
                        2'b01: MA_DMEM[word_addr][15:8]     <= data_w_i[7:0];   
                        2'b10: MA_DMEM[word_addr][23:16]    <= data_w_i[7:0];   
                        2'b11: MA_DMEM[word_addr][31:24]    <= data_w_i[7:0];   
                    endcase      
                end
                3'b001: begin
                    if (byte_offset[0] == 1'b0) //sh
                        case(byte_offset[1])
                            1'b0: MA_DMEM[word_addr][15:0]  <= data_w_i[15:0];
                            1'b1: MA_DMEM[word_addr][31:16] <= data_w_i[15:0];
                        endcase
                end
                3'b010: begin
                    if(byte_offset == 2'b0) //sw
                        MA_DMEM[word_addr]  <= data_w_i;
                end
                default:;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            funct3_r        <= 'b0;
            byte_offset_r   <= 3'b0;
            raw_read_data   <= 32'b0;   
        end
        else if (mem_re_i) begin
            funct3_r        <= funct3_i;
            byte_offset_r   <= byte_offset;
            raw_read_data   <= MA_DMEM[word_addr];
        end
    end
    always @(*) begin
        if (mem_re_i) begin
            case(funct3_r)
                3'b000: begin //lb
                    case(byte_offset_r)
                        2'b00: data_r_o = {{24{raw_read_data[7]}},  raw_read_data[7:0]};  
                        2'b01: data_r_o = {{24{raw_read_data[15]}}, raw_read_data[15:8]};  
                        2'b10: data_r_o = {{24{raw_read_data[23]}}, raw_read_data[23:16]};  
                        2'b11: data_r_o = {{24{raw_read_data[31]}}, raw_read_data[31:24]};  
                    endcase
                end
                                                
                3'b001: begin //lh
                    if(byte_offset_r[0] == 1'b0) begin
                        case(byte_offset_r[1])
                            1'b0: data_r_o = {{16{raw_read_data[15]}}, raw_read_data[15:0]};
                            1'b1: data_r_o = {{16{raw_read_data[31]}}, raw_read_data[31:16]};
                        endcase
                    end
                    else begin
                        data_r_o        = 32'bx;
                    end         
                end
                3'b010: begin //lw
                    if(byte_offset_r == 2'b0) begin
                        data_r_o = raw_read_data; 
                    end
                    else begin
                        data_r_o        = 32'bx;
                    end
                end  
                3'b100: begin //lbu
                    case(byte_offset_r)
                        2'b00: data_r_o = {24'b0, raw_read_data[7:0]};  
                        2'b01: data_r_o = {24'b0, raw_read_data[15:8]};  
                        2'b10: data_r_o = {24'b0, raw_read_data[23:16]};  
                        2'b11: data_r_o = {24'b0, raw_read_data[31:24]};  
                    endcase                                                  
                end
                3'b101: begin //lhu
                    if(byte_offset_r[0] == 1'b0) begin
                        case(byte_offset_r[1])
                            1'b0: data_r_o = {16'b0, raw_read_data[15:0]};
                            1'b1: data_r_o = {16'b0, raw_read_data[31:16]};
                        endcase
                    end
                    else begin
                        data_r_o        = 32'bx;
                    end                                 
                end
                default: begin
                    data_r_o        = 32'bx;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            s_axi_data_o   <= 32'b0;
        else if (s_axi_re_i) begin
            s_axi_data_o    <= MA_DMEM[s_axi_addr_i>>2];
        end
    end
endmodule

//module DMEM(
//    clk,
//    mem_we_i,
//    funct3_i,
//    addr_i,
//    data_w_i,
//    data_r_o,
//    s_axi_re_i,
//    s_axi_addr_i,
//    s_axi_data_o
//);
//    input           clk, mem_we_i, s_axi_re_i;
//    input [2:0]     funct3_i;
//    input [31:0]    addr_i;
//    input [31:0]    data_w_i, s_axi_addr_i;
//    output [31:0]   data_r_o, s_axi_data_o;
    
//    reg [31:0]      data_temp;
//    (* ram_style = "block" *) reg [7:0]       MA_DMEM [1<<12 - 1:0]; //4KB
//    integer i;

//    always @(posedge clk) begin
//        if(mem_we_i) begin
//            case(funct3_i)
//                3'b000: MA_DMEM[addr_i] <= data_w_i[7:0];      //sb
//                3'b001: begin
//                    MA_DMEM[addr_i]     <= data_w_i[7:0];      //sh
//                    MA_DMEM[addr_i + 1] <= data_w_i[15:8];
//                end
//                3'b010: begin
//                    MA_DMEM[addr_i]     <= data_w_i[7:0];      //sw
//                    MA_DMEM[addr_i + 1] <= data_w_i[15:8];
//                    MA_DMEM[addr_i + 2] <= data_w_i[23:16];
//                    MA_DMEM[addr_i + 3] <= data_w_i[31:24];
//                end
////                default: //taidao 25/5 added default case
////                    //do-nothing
//            endcase
//        end
//    end
//    always @(*) begin
//        case(funct3_i)
//            3'b000: data_temp = {{25{MA_DMEM[addr_i][7]}}, MA_DMEM[addr_i][6:0]};                              //lb
//            3'b001: data_temp = {{17{MA_DMEM[addr_i + 1][7]}}, MA_DMEM[addr_i + 1][6:0], MA_DMEM[addr_i]};     //lh
//            3'b010: data_temp = {MA_DMEM[addr_i +3], MA_DMEM[addr_i +2], MA_DMEM[addr_i +1], MA_DMEM[addr_i]}; //lw                                   //lw
//            3'b100: data_temp = {24'b0, MA_DMEM[addr_i]};                                                      //lbu
//            3'b101: data_temp = {16'b0, MA_DMEM[addr_i + 1], MA_DMEM[addr_i]};                                 //lhu
//            default: //taidao 25/5 added default case
//                    data_temp = 32'b0;
//        endcase
//    end
//    assign s_axi_data_o = (s_axi_re_i) ? {MA_DMEM[s_axi_addr_i + 3], MA_DMEM[s_axi_addr_i +2], MA_DMEM[s_axi_addr_i +1], MA_DMEM[s_axi_addr_i]} : 32'b0;
//    assign data_r_o     = data_temp;
//endmodule