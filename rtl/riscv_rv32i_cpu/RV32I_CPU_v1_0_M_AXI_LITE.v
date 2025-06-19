`timescale 1ns / 1ps
module RV32I_CPU_v1_0_M_AXI_LITE#
	(
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_DATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		input wire  [31:0]  addr_per_i,  //periperal address
        input wire  [2:0]   funct3_i,
        input wire  [31:0]  data_w_i,
        input wire          mem_we_i,
        input wire          reg_we_i,
        input wire  [4:0]   addr_d_i, //register address  
        output reg [31:0]   data_r_o,
        output wire         reg_we_o,
        output wire [4:0]   addr_d_o,
        output reg          stall_o,
		// User ports ends
		// Do not modify the ports beyond this line
        input         TXN_AXI_INIT,
		// Asserts when ERROR is detected
//		output reg    ERROR,
		// Asserts when AXI transactions is complete
		output wire   TXN_DONE,
		// AXI clock signal
		input wire    M_AXI_ACLK,
		// AXI active low reset signal
		input wire    M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		output wire   M_AXI_AWVALID,
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
	);

    localparam [1:0]    IDLE        = 2'b00,
                        INIT_WRITE  = 2'b01,
                        INIT_READ   = 2'b10,
                        WADDR       = 2'b01, 
                        WDATA       = 2'b10, 
                        BRESP       = 2'b11,
                        RADDR       = 2'b10, 
                        RDATA       = 2'b11;

	reg [1:0] mst_exec_state;
	reg [1:0] state_write;
	reg [1:0] state_read;
    reg [31:0] axi_rdata; //taidao channged reg to wire
	// AXI4LITE signals
	reg  	axi_awvalid;
	reg  	axi_wvalid;
	reg  	axi_arvalid;
	reg  	axi_rready;
	reg  	axi_bready;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	   axi_awaddr;
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	   axi_wdata;
	reg [C_M_AXI_DATA_WIDTH/8 -1 : 0]  axi_wstrb; //10/6
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	   axi_araddr;
	
	//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
	reg  	writes_done;
	//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
	reg  	reads_done;
	
	reg  	        init_txn_ff2;
	wire  	        init_txn_pulse;
    wire    [31:0]  write_data;
    wire    [31:0]  read_data;
    wire  	        init_txn_ff;
    reg     [2:0]   reg_funct3;
    reg     [31:0]  reg_dataw;
    reg     [31:0]  reg_mmio_addr; //periperal address
    reg             reg_reg_we;
    reg     [4:0]   reg_addr_d;
    wire [1:0]      write_offset, read_offset; //30/5 - 10/6
    
	reg  [C_M_AXI_DATA_WIDTH/8 -1 : 0]      reg_wstrb; //30/5
	
	// I/O Connections assignments
    
	//Adding the offset address to the base addr of the slave
//	assign M_AXI_AWADDR	= axi_awaddr;
	assign M_AXI_AWADDR	= {axi_awaddr[31:2], 2'b0}; //word_address taidao 10/6
	assign M_AXI_WDATA	= axi_wdata;
	assign M_AXI_AWPROT	= 3'b000;
	assign M_AXI_AWVALID= axi_awvalid;
	assign M_AXI_WVALID	= axi_wvalid;
	//taidao config strb 30/5
	assign write_offset = reg_mmio_addr[1:0];//M_AXI_AWADDR[1:0];
	always @(*) begin
        case (reg_funct3)
            3'b000:  // SB - store byte
                case (write_offset)
                    2'b00: reg_wstrb = 4'b0001;
                    2'b01: reg_wstrb = 4'b0010;
                    2'b10: reg_wstrb = 4'b0100;
                    2'b11: reg_wstrb = 4'b1000;
                endcase
            3'b001:  // SH - store halfword
                case (write_offset)
                    2'b00: reg_wstrb = 4'b0011;
                    2'b10: reg_wstrb = 4'b1100;
                    default: reg_wstrb = 4'b0000; // unaligned ? optionally raise error
                endcase
            3'b010:  // SW - store word
                reg_wstrb = 4'b1111;
            default:
                reg_wstrb = 4'b0000;  // unknown access
        endcase
    end
	//taidao end
	assign M_AXI_WSTRB	= axi_wstrb; //4'b1111;
	assign M_AXI_BREADY	= axi_bready;
//	assign M_AXI_ARADDR	= axi_araddr;
    assign M_AXI_ARADDR	= {axi_araddr[31:2], 2'b0}; //word_address taidao 10/6
	assign M_AXI_ARVALID= axi_arvalid;
	assign M_AXI_ARPROT	= 3'b001;
	assign M_AXI_RREADY	= axi_rready;
	
	assign init_txn_ff = TXN_AXI_INIT;
	assign init_txn_pulse	= (!init_txn_ff2) && init_txn_ff;
//    assign write_data   =   (funct3_i==3'b000) ? {24'b0,{data_w_i[7:0]}}    :
//                            (funct3_i==3'b001) ? {16'b0,{data_w_i[15:0]}}   :
//                            (funct3_i==3'b010) ? data_w_i                   : 32'b0;
    assign write_data   = data_w_i;
//    assign data_r_o     =   (reg_funct3==3'b000) ? {{24{read_data[7]}}, read_data[7:0]}   :           //lb                          
//                            (reg_funct3==3'b001) ? {{16{read_data[15]}}, read_data[15:0]} :           //lh
//                            (reg_funct3==3'b010) ? read_data                               :           //lw                                 
//                            (reg_funct3==3'b100) ? {24'b0, read_data[7:0]}                 :           //lbu                                            
//                            (reg_funct3==3'b101) ? {16'b0, read_data[15:0]}                : 32'b0;    //lhu
    assign read_data    = (axi_rready && M_AXI_RVALID) ? M_AXI_RDATA    : 32'b0;
    assign reg_we_o     = (axi_rready && M_AXI_RVALID) ? reg_reg_we     : 1'b0;  
    assign addr_d_o     = (axi_rready && M_AXI_RVALID) ? reg_addr_d     : 5'b0;                   
	assign TXN_DONE     = reads_done || writes_done;
	assign read_offset  = reg_mmio_addr[1:0]; //taidao add 10/6
	always @(*) begin
        case(reg_funct3)
            3'b000: begin //lb
                case(read_offset)
                    2'b00: data_r_o = {{24{read_data[7]}},  read_data[7:0]};  
                    2'b01: data_r_o = {{24{read_data[15]}}, read_data[15:8]};  
                    2'b10: data_r_o = {{24{read_data[23]}}, read_data[23:16]};  
                    2'b11: data_r_o = {{24{read_data[31]}}, read_data[31:24]};  
                endcase
            end
                                            
            3'b001: begin //lh
                if(read_offset[0] == 1'b0) begin
                    case(read_offset[1])
                        1'b0: data_r_o = {{16{read_data[15]}}, read_data[15:0]};
                        1'b1: data_r_o = {{16{read_data[31]}}, read_data[31:16]};
                    endcase
                end
                else begin
                    data_r_o        = 32'bx;
                end         
            end
            3'b010: begin //lw
                if(read_offset == 2'b0) begin
                    data_r_o = read_data; 
                end
                else begin
                    data_r_o        = 32'bx;
                end
            end  
            3'b100: begin //lbu
                case(read_offset)
                    2'b00: data_r_o = {24'b0, read_data[7:0]};  
                    2'b01: data_r_o = {24'b0, read_data[15:8]};  
                    2'b10: data_r_o = {24'b0, read_data[23:16]};  
                    2'b11: data_r_o = {24'b0, read_data[31:24]};  
                endcase                                                  
            end
            3'b101: begin //lhu
                if(read_offset[0] == 1'b0) begin
                    case(read_offset[1])
                        1'b0: data_r_o = {16'b0, read_data[15:0]};
                        1'b1: data_r_o = {16'b0, read_data[31:16]};
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
    
    always @(posedge M_AXI_ACLK) begin                                                                        
        if (M_AXI_ARESETN == 0 )                                                   
            init_txn_ff2       <= 1'b0;                                                     
        else                                                                       
            init_txn_ff2       <= init_txn_ff;                                                                 
    end     

    always @(posedge M_AXI_ACLK) begin                                                                        
        if (M_AXI_ARESETN == 0 || init_txn_pulse) begin                                                                    
            axi_awvalid    <= 1'b0;                                                   
            axi_awaddr     <= 1'b0;                                                   
            axi_wvalid     <= 1'b0;                                                                                                  
            axi_wdata      <= 32'h0; 
            axi_wstrb      <= 4'b0;                                                  
            axi_bready     <= 1'b0;                                                   
            if (init_txn_pulse)
                state_write <= IDLE;                                                    
        end                                                                      
        else begin                                                                    
            case(state_write)                                                
                IDLE: begin                                               
                    if (init_txn_pulse == 0 && mst_exec_state == INIT_WRITE && writes_done == 0) begin                                                          
                        axi_awvalid  <= 1;                                            
                        axi_wvalid   <= 0; 
                        axi_awaddr   <= reg_mmio_addr;         	                                                    
                        state_write  <= WADDR;                                           
                    end                                             
                    else                                             
                        state_write  <= state_write;                                                                                          
                end                                             
                WADDR: begin										      
                    if (M_AXI_AWREADY && axi_awvalid) begin										      										      
                        axi_wvalid    <= 1;										      									      									      
                        axi_awvalid   <= 0;										      
                        axi_bready    <= 0;										      
                        axi_wdata     <= reg_dataw;	
                        axi_wstrb     <= reg_wstrb;									      
                        state_write   <= WDATA;										      										      
                    end										      									      
                end										      
                WDATA: begin										      
                    if (axi_wvalid && M_AXI_WREADY) begin										      										      										      
                        axi_wvalid    <= 0;										      								      								      
                        axi_bready    <= 1;										      
                        state_write   <= BRESP;
                    end
                    else
                        state_write  <= state_write;										      								      
                end	 
                BRESP: begin
                    if (axi_bready  && M_AXI_BVALID) begin
                        axi_bready    <= 0;
                        state_write   <= IDLE;
                    end	
                    else
                        state_write  <= state_write;	
                end								      
            endcase										      
        end										      
    end										      
                                                   
    always @(posedge M_AXI_ACLK) begin                                                     
        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1) begin                                                                                                               
            axi_arvalid  <= 1'b0;                                                     
            axi_rready   <= 1'b0;                                                        
            axi_araddr   <= 0;                                                                                                  
	        if (init_txn_pulse)
	           state_read <=  IDLE;                                                                                     
        end                                                                                                                          
        else begin                                                     
            case(state_read)                                                     
	            IDLE: begin                                                     
                    if (init_txn_pulse ==  0 && mst_exec_state == INIT_READ && reads_done == 0) begin                                                     
                        axi_arvalid    <= 1;                                                     
                        state_read     <= RADDR;                                                    
                        axi_araddr     <= reg_mmio_addr;                                                      
                    end                                                     
                    else
                        state_read    <= state_read;                                                     
                end                                                     
	            RADDR: begin                                                       
                    if(axi_arvalid && M_AXI_ARREADY) begin    
//                        axi_araddr     <= addr_per_i;                                                      
                        axi_arvalid    <= 0;                                                       
                        axi_rready     <= 1;                                                                                                              
                        state_read     <= RDATA;                                                       
                    end                                                       
                    else
                        state_read    <= state_read;                                                       
                end                                                       
	            RDATA: begin                                                     
                    if (axi_rready && M_AXI_RVALID) begin                                                                                                                                                         
                        axi_rready <= 0;                                                                                                    
                        state_read <= IDLE;
                    end                                                                                              
                end                                                     
            endcase                                                     
        end                                                                                   
    end                                                     
	                                                                        
	//User Logic
	//--------------------------------                      
    always @ ( posedge M_AXI_ACLK) begin                                                                             
        if (M_AXI_ARESETN == 1'b0)                                                     
            mst_exec_state  <= IDLE;                                            
	    else begin                                                                         
            case (mst_exec_state)                                                       
                IDLE: begin                                                             
                    if (init_txn_pulse == 1'b1 &&  mem_we_i == 1'b1) begin                                                                
                        mst_exec_state     <= INIT_WRITE;
//                        writes_done        <= 0;                                      
                    end       
                    else if (init_txn_pulse == 1'b1 && mem_we_i == 1'b0) begin
                        mst_exec_state  <= INIT_READ;
//                        reads_done      <= 0;
                    end                                                             
                    else                                                                    
                        mst_exec_state  <= IDLE;                                    
                end                                                                         
                INIT_WRITE: begin                                                             
                    if (writes_done)                                                        
                        mst_exec_state <= IDLE;                                    
                    else                                                                    
                        mst_exec_state  <= INIT_WRITE;                                      
                end                                                       
                INIT_READ: begin                                                             
                    if (reads_done)                                                        
                        mst_exec_state <= IDLE;                                    
                    else                                                                   
                        mst_exec_state  <= INIT_READ;                                      
                end
	           default :                                                                
	               mst_exec_state  <= IDLE;                                     
	        endcase                                                                     
        end                                                                             
    end                                                     
                                                                                                                                          
    always @(posedge M_AXI_ACLK) begin                                                                             
        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
            writes_done <= 1'b0;                                                                                                                                                             
        else if (M_AXI_BVALID && axi_bready)                              
            writes_done <= 1'b1;                                                          
        else                                                                            
            writes_done <= writes_done;                                                   
    end                                                                               
                                                                                                                                                                                                                             
    always @(posedge M_AXI_ACLK) begin                                                                             
        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
            reads_done <= 1'b0;                                                           
        else if (M_AXI_RVALID && axi_rready)                               
            reads_done <= 1'b1;                                                           
        else                                                                            
            reads_done <= reads_done;                                                     
    end                                                                             
	                                                                                                                                         
	// Add user logic here
    always @(*) begin                                                                             
        if (M_AXI_ARESETN == 0 )                                                         
            stall_o <= 1'b0;                                                          	                                                                                    
        else if (TXN_AXI_INIT)                               
            stall_o <= 1'b1;                                                           
        else if (TXN_DONE)                                                                           
            stall_o <= 1'b0;
        else
            stall_o <= stall_o;                                                    
    end
   
    always @(posedge M_AXI_ACLK) begin                                                                             
        if (M_AXI_ARESETN == 0 ) begin                                                                                                    	                                                                                    
            reg_mmio_addr       <= 32'h0;	 
            reg_dataw           <= 32'h0;
            reg_reg_we          <= 1'b0;
            reg_addr_d          <= 4'b0;
            reg_funct3          <= 3'b0; 
        end                
        else if (init_txn_pulse) begin                        
            reg_mmio_addr       <= addr_per_i;	 
            reg_dataw           <= write_data;
            reg_reg_we          <= reg_we_i;
            reg_addr_d          <= addr_d_i;
            reg_funct3          <= funct3_i;   
        end
        else begin                                                                                                                                   
            reg_mmio_addr       <= reg_mmio_addr;	 
            reg_dataw           <= reg_dataw; 
            reg_reg_we          <= reg_reg_we;
            reg_addr_d          <= reg_addr_d;  
            reg_funct3          <= reg_funct3;
        end                                                    
    end
	// User logic ends
endmodule

//`timescale 1ns / 1ps
//module RV32I_CPU_v1_0_M_AXI_LITE#
//	(
//		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
//		parameter integer C_M_AXI_DATA_WIDTH	= 32
//	)
//	(
//		// Users to add ports here
//		input wire  [31:0]  addr_per_i,  //periperal address
//        input wire  [2:0]   funct3_i,
//        input wire  [31:0]  data_w_i,
//        input wire          mem_we_i,
//        input wire          reg_we_i,
//        input wire  [4:0]   addr_d_i, //register address  
//        output wire [31:0]  data_r_o,
//        output wire         reg_we_o,
//        output wire [4:0]   addr_d_o,
//        output reg          stall_o,
//		// User ports ends
//		// Do not modify the ports beyond this line
//        input         TXN_AXI_INIT,
//		// Asserts when ERROR is detected
////		output reg    ERROR,
//		// Asserts when AXI transactions is complete
//		output wire   TXN_DONE,
//		// AXI clock signal
//		input wire    M_AXI_ACLK,
//		// AXI active low reset signal
//		input wire    M_AXI_ARESETN,
//		// Master Interface Write Address Channel ports. Write address (issued by master)
//		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
//		// Write channel Protection type.
//    // This signal indicates the privilege and security level of the transaction,
//    // and whether the transaction is a data access or an instruction access.
//		output wire [2 : 0] M_AXI_AWPROT,
//		// Write address valid. 
//    // This signal indicates that the master signaling valid write address and control information.
//		output wire   M_AXI_AWVALID,
//		// Write address ready. 
//    // This signal indicates that the slave is ready to accept an address and associated control signals.
//		input wire  M_AXI_AWREADY,
//		// Master Interface Write Data Channel ports. Write data (issued by master)
//		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
//		// Write strobes. 
//    // This signal indicates which byte lanes hold valid data.
//    // There is one write strobe bit for each eight bits of the write data bus.
//		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
//		// Write valid. This signal indicates that valid write data and strobes are available.
//		output wire  M_AXI_WVALID,
//		// Write ready. This signal indicates that the slave can accept the write data.
//		input wire  M_AXI_WREADY,
//		// Master Interface Write Response Channel ports. 
//    // This signal indicates the status of the write transaction.
//		input wire [1 : 0] M_AXI_BRESP,
//		// Write response valid. 
//    // This signal indicates that the channel is signaling a valid write response
//		input wire  M_AXI_BVALID,
//		// Response ready. This signal indicates that the master can accept a write response.
//		output wire  M_AXI_BREADY,
//		// Master Interface Read Address Channel ports. Read address (issued by master)
//		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
//		// Protection type. 
//    // This signal indicates the privilege and security level of the transaction, 
//    // and whether the transaction is a data access or an instruction access.
//		output wire [2 : 0] M_AXI_ARPROT,
//		// Read address valid. 
//    // This signal indicates that the channel is signaling valid read address and control information.
//		output wire  M_AXI_ARVALID,
//		// Read address ready. 
//    // This signal indicates that the slave is ready to accept an address and associated control signals.
//		input wire  M_AXI_ARREADY,
//		// Master Interface Read Data Channel ports. Read data (issued by slave)
//		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
//		// Read response. This signal indicates the status of the read transfer.
//		input wire [1 : 0] M_AXI_RRESP,
//		// Read valid. This signal indicates that the channel is signaling the required read data.
//		input wire  M_AXI_RVALID,
//		// Read ready. This signal indicates that the master can accept the read data and response information.
//		output wire  M_AXI_RREADY
//	);

//    localparam [1:0]    IDLE        = 2'b00,
//                        INIT_WRITE  = 2'b01,
//                        INIT_READ   = 2'b10,
//                        WADDR       = 2'b01, 
//                        WDATA       = 2'b10, 
//                        BRESP       = 2'b11,
//                        RADDR       = 2'b10, 
//                        RDATA       = 2'b11;

//	reg [1:0] mst_exec_state;
//	reg [1:0] state_write;
//	reg [1:0] state_read;
//    reg [31:0] axi_rdata; //taidao channged reg to wire
//	// AXI4LITE signals
//	reg  	axi_awvalid;
//	reg  	axi_wvalid;
//	reg  	axi_arvalid;
//	reg  	axi_rready;
//	reg  	axi_bready;
//	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
//	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
//	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	
//	//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
//	reg  	writes_done;
//	//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
//	reg  	reads_done;
	
//	reg  	init_txn_ff2;
//	reg  	init_txn_edge;
//	wire  	init_txn_pulse;
//    wire    [31:0]  write_data;
//    wire    [31:0]  read_data;
//    wire  	init_txn_ff;
//    reg     [2:0]   reg_funct3;
//    reg     [31:0]  reg_dataw;
//    reg     [31:0]  reg_addr_per; //periperal address
//    reg             reg_reg_we;
//    reg     [4:0]   reg_addr_d;
//    wire [1:0] addr_offset; //30/5
//	reg  [3:0] axi_wstrb; //30/5
//	// I/O Connections assignments
    
//	//Adding the offset address to the base addr of the slave
//	assign M_AXI_AWADDR	= axi_awaddr;
//	assign M_AXI_WDATA	= axi_wdata;
//	assign M_AXI_AWPROT	= 3'b000;
//	assign M_AXI_AWVALID= axi_awvalid;
//	assign M_AXI_WVALID	= axi_wvalid;
//	//taidao config strb 30/5
//	assign addr_offset = M_AXI_AWADDR[1:0];
//	always @(*) begin
//        case (reg_funct3)
//            3'b000:  // SB - store byte
//                case (addr_offset)
//                    2'b00: axi_wstrb = 4'b0001;
//                    2'b01: axi_wstrb = 4'b0010;
//                    2'b10: axi_wstrb = 4'b0100;
//                    2'b11: axi_wstrb = 4'b1000;
//                endcase
//            3'b001:  // SH - store halfword
//                case (addr_offset)
//                    2'b00: axi_wstrb = 4'b0011;
//                    2'b10: axi_wstrb = 4'b1100;
//                    default: axi_wstrb = 4'b0000; // unaligned ? optionally raise error
//                endcase
//            3'b010:  // SW - store word
//                axi_wstrb = 4'b1111;
//            default:
//                axi_wstrb = 4'b0000;  // unknown access
//        endcase
//    end
//	//taidao end
//	assign M_AXI_WSTRB	= axi_wstrb; //4'b1111;
//	assign M_AXI_BREADY	= axi_bready;
//	assign M_AXI_ARADDR	= axi_araddr;
//	assign M_AXI_ARVALID= axi_arvalid;
//	assign M_AXI_ARPROT	= 3'b001;
//	assign M_AXI_RREADY	= axi_rready;
	
//	assign init_txn_ff = TXN_AXI_INIT;
//	assign init_txn_pulse	= (!init_txn_ff2) && init_txn_ff;
//    assign write_data   =   (funct3_i==3'b000) ? {24'b0,{data_w_i[7:0]}}    :
//                            (funct3_i==3'b001) ? {16'b0,{data_w_i[15:0]}}   :
//                            (funct3_i==3'b010) ? data_w_i                   : 32'b0;
//    assign data_r_o     =   (reg_funct3==3'b000) ? {{25{axi_rdata[7]}}, axi_rdata[6:0]}   :           //lb                          
//                            (reg_funct3==3'b001) ? {{17{axi_rdata[15]}}, axi_rdata[14:0]} :           //lh
//                            (reg_funct3==3'b010) ? axi_rdata                               :           //lw                                 
//                            (reg_funct3==3'b100) ? {24'b0, axi_rdata[7:0]}                 :           //lbu                                            
//                            (reg_funct3==3'b101) ? {16'b0, axi_rdata[15:0]}                : 32'b0;    //lhu
////    assign read_data   = (axi_rready && M_AXI_RVALID) ? M_AXI_RDATA    : 32'b0;
//    assign reg_we_o     = (axi_rready && M_AXI_RVALID) ? reg_reg_we     : 1'b0;  
//    assign addr_d_o     = (axi_rready && M_AXI_RVALID) ? reg_addr_d     : 5'b0;                   
//	assign TXN_DONE     = reads_done || writes_done;
	
//	always @(posedge M_AXI_ACLK) begin                                                                        
//        if (M_AXI_ARESETN == 0 )                                                   
//            axi_rdata       <= 1'b0;                                                     
//        else if(axi_rready && M_AXI_RVALID)                                                                       
//            axi_rdata       <= M_AXI_RDATA;                                                                 
//    end 
    
//    always @(posedge M_AXI_ACLK) begin                                                                        
//        if (M_AXI_ARESETN == 0 )                                                   
//            init_txn_ff2       <= 1'b0;                                                     
//        else                                                                       
//            init_txn_ff2       <= init_txn_ff;                                                                 
//    end     

//    always @(posedge M_AXI_ACLK) begin                                                                        
//        if (M_AXI_ARESETN == 0 || init_txn_pulse) begin                                                                    
//            axi_awvalid    <= 1'b0;                                                   
//            axi_awaddr     <= 1'b0;                                                   
//            axi_wvalid     <= 1'b0;                                                                                                  
//            axi_wdata      <= 32'h0;                                                   
//            axi_bready     <= 1'b0;                                                   
//            if (init_txn_pulse)
//                state_write <= IDLE;                                                    
//        end                                                                      
//        else begin                                                                    
//            case(state_write)                                                
//                IDLE: begin                                               
//                    if (init_txn_pulse == 0 && mst_exec_state == INIT_WRITE && writes_done == 0) begin                                                          
//                        axi_awvalid  <= 1;                                            
//                        axi_wvalid   <= 0; 
//                        axi_awaddr   <= reg_addr_per;         	                                                    
//                        state_write  <= WADDR;                                           
//                    end                                             
//                    else                                             
//                        state_write  <= state_write;                                                                                          
//                end                                             
//                WADDR: begin										      
//                    if (M_AXI_AWREADY && axi_awvalid) begin										      										      
//                        axi_wvalid    <= 1;										      									      									      
//                        axi_awvalid   <= 0;										      
//                        axi_bready    <= 0;										      
//                        axi_wdata     <= reg_dataw;										      
//                        state_write   <= WDATA;										      										      
//                    end										      									      
//                end										      
//                WDATA: begin										      
//                    if (axi_wvalid && M_AXI_WREADY) begin										      										      										      
//                        axi_wvalid    <= 0;										      								      								      
//                        axi_bready    <= 1;										      
//                        state_write   <= BRESP;
//                    end
//                    else
//                        state_write  <= state_write;										      								      
//                end	 
//                BRESP: begin
//                    if (axi_bready  && M_AXI_BVALID) begin
//                        axi_bready    <= 0;
//                        state_write   <= IDLE;
//                    end	
//                    else
//                        state_write  <= state_write;	
//                end								      
//            endcase										      
//        end										      
//    end										      
                                                   
//    always @(posedge M_AXI_ACLK) begin                                                     
//        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1) begin                                                                                                               
//            axi_arvalid  <= 1'b0;                                                     
//            axi_rready   <= 1'b0;                                                        
//            axi_araddr   <= 0;                                                                                                  
//	        if (init_txn_pulse)
//	           state_read <=  IDLE;                                                                                     
//        end                                                                                                                          
//        else begin                                                     
//            case(state_read)                                                     
//	            IDLE: begin                                                     
//                    if (init_txn_pulse ==  0 && mst_exec_state == INIT_READ && reads_done == 0) begin                                                     
//                        axi_arvalid    <= 1;                                                     
//                        state_read     <= RADDR;                                                    
//                        axi_araddr     <= reg_addr_per;                                                      
//                    end                                                     
//                    else
//                        state_read    <= state_read;                                                     
//                end                                                     
//	            RADDR: begin                                                       
//                    if(axi_arvalid && M_AXI_ARREADY) begin    
//                        axi_araddr     <= addr_per_i;                                                      
//                        axi_arvalid    <= 0;                                                       
//                        axi_rready     <= 1;                                                                                                              
//                        state_read     <= RDATA;                                                       
//                    end                                                       
//                    else
//                        state_read    <= state_read;                                                       
//                end                                                       
//	            RDATA: begin                                                     
//                    if (axi_rready && M_AXI_RVALID) begin                                                                                                                                                         
//                        axi_rready <= 0;                                                                                                    
//                        state_read <= IDLE;
//                    end                                                                                              
//                end                                                     
//            endcase                                                     
//        end                                                                                   
//    end                                                     
	                                                                        
//	//User Logic
//	//--------------------------------                      
//    always @ ( posedge M_AXI_ACLK) begin                                                                             
//        if (M_AXI_ARESETN == 1'b0)                                                     
//            mst_exec_state  <= IDLE;                                            
//	    else begin                                                                         
//            case (mst_exec_state)                                                       
//                IDLE: begin                                                             
//                    if (init_txn_pulse == 1'b1 &&  mem_we_i == 1'b1) begin                                                                
//                        mst_exec_state     <= INIT_WRITE;
////                        writes_done        <= 0;                                      
//                    end       
//                    else if (init_txn_pulse == 1'b1 && mem_we_i == 1'b0) begin
//                        mst_exec_state  <= INIT_READ;
////                        reads_done      <= 0;
//                    end                                                             
//                    else                                                                    
//                        mst_exec_state  <= IDLE;                                    
//                end                                                                         
//                INIT_WRITE: begin                                                             
//                    if (writes_done)                                                        
//                        mst_exec_state <= IDLE;                                    
//                    else                                                                    
//                        mst_exec_state  <= INIT_WRITE;                                      
//                end                                                       
//                INIT_READ: begin                                                             
//                    if (reads_done)                                                        
//                        mst_exec_state <= IDLE;                                    
//                    else                                                                   
//                        mst_exec_state  <= INIT_READ;                                      
//                end
//	           default :                                                                
//	               mst_exec_state  <= IDLE;                                     
//	        endcase                                                                     
//        end                                                                             
//    end                                                     
                                                                                                                                          
//    always @(posedge M_AXI_ACLK) begin                                                                             
//        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
//            writes_done <= 1'b0;                                                                                                                                                             
//        else if (M_AXI_BVALID && axi_bready)                              
//            writes_done <= 1'b1;                                                          
//        else                                                                            
//            writes_done <= writes_done;                                                   
//    end                                                                               
                                                                                                                                                                                                                             
//    always @(posedge M_AXI_ACLK) begin                                                                             
//        if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
//            reads_done <= 1'b0;                                                           
//        else if (M_AXI_RVALID && axi_rready)                               
//            reads_done <= 1'b1;                                                           
//        else                                                                            
//            reads_done <= reads_done;                                                     
//    end                                                                             
	                                                                                                                                         
//	// Add user logic here
//    always @(*) begin                                                                             
//        if (M_AXI_ARESETN == 0 )                                                         
//            stall_o <= 1'b0;                                                          	                                                                                    
//        else if (TXN_AXI_INIT)                               
//            stall_o <= 1'b1;                                                           
//        else if (TXN_DONE)                                                                           
//            stall_o <= 1'b0;
//        else
//            stall_o <= stall_o;                                                    
//    end
   
//    always @(posedge M_AXI_ACLK) begin                                                                             
//        if (M_AXI_ARESETN == 0 ) begin                                                                                                    	                                                                                    
//            reg_addr_per        <= 32'h0;	 
//            reg_dataw           <= 32'h0;
//            reg_reg_we          <= 1'b0;
//            reg_addr_d          <= 4'b0;
//            reg_funct3          <= 3'b0; 
//        end                
//        else if (init_txn_pulse) begin                        
//            reg_addr_per        <= addr_per_i;	 
//            reg_dataw           <= write_data;
//            reg_reg_we          <= reg_we_i;
//            reg_addr_d          <= addr_d_i;
//            reg_funct3          <= funct3_i;   
//        end
//        else begin                                                                                                                                   
//            reg_addr_per        <= reg_addr_per;	 
//            reg_dataw           <= reg_dataw; 
//            reg_reg_we          <= reg_reg_we;
//            reg_addr_d          <= reg_addr_d;  
//            reg_funct3          <= reg_funct3;
//        end                                                    
//    end
//	// User logic ends
//endmodule
