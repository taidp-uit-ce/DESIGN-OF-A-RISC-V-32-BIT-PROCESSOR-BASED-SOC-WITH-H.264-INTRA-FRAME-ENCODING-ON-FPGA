
`timescale 1 ns / 1 ps
	module RV32I_CPU_v1_0_S_AXI_LITE #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		input [31:0]  RV32I_DMEM_DATA_R_I,
		input [31:0]  RV32I_ID_PC_I,
		input [31:0]  RV32I_ID_INST_I,
		
		output        RV32I_RST_N,
		output        RV32I_START,
		output        RV32I_IMEM_WE_O,
		output [31:0] RV32I_IMEM_ADDR_O,
		output [31:0] RV32I_IMEM_INST_O,
		output        RV32I_DMEM_RE_O,
		output [31:0] RV32I_DMEM_ADDR_O,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	 axi_awaddr;
	reg  	                         axi_awready;
	reg  	                         axi_wready;
	reg [1 : 0] 	                 axi_bresp;
	reg  	                         axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	 axi_araddr;
	reg  	                         axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	 axi_rdata;
	reg [1 : 0] 	                 axi_rresp;
	reg  	                         axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers <n> !!!remember to config OPT_MEM_ADDR_BITS var
	reg [C_S_AXI_DATA_WIDTH-1:0]	rst_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0]	status_reg; //bit[0] = start | bit[1] done
	reg [C_S_AXI_DATA_WIDTH-1:0]	imem_we_reg; //write enable
	reg [C_S_AXI_DATA_WIDTH-1:0]	imem_addr_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0]	imem_data_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0]	dmem_re_reg; //read enable
	reg [C_S_AXI_DATA_WIDTH-1:0]	dmem_addr_reg;
	
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY   = axi_awready;
	assign S_AXI_WREADY	   = axi_wready;
	assign S_AXI_BRESP	   = axi_bresp;
	assign S_AXI_BVALID	   = axi_bvalid;
	assign S_AXI_ARREADY   = axi_arready;
	assign S_AXI_RDATA	   = axi_rdata;
	assign S_AXI_RRESP	   = axi_rresp;
	assign S_AXI_RVALID	   = axi_rvalid;
	 //state machine varibles 
	 reg [1:0] state_write;
	 reg [1:0] state_read;
	 //State machine local parameters
	 localparam    Idle = 2'b00,
	               Raddr = 2'b10,
	               Rdata = 2'b11,
	               Waddr = 2'b10,
	               Wdata = 2'b11;
	               
	// Implement Write state machine
	// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
    always @(posedge S_AXI_ACLK) begin                                 
        if (S_AXI_ARESETN == 1'b0) begin                                 
            axi_awready <= 0;                                 
            axi_wready <= 0;                                 
            axi_bvalid <= 0;                                 
            axi_bresp <= 0;                                 
            axi_awaddr <= 0;                                 
            state_write <= Idle;                                 
        end                                 
	    else begin                                 
            case(state_write)                                 
                Idle: begin                                 
                    if(S_AXI_ARESETN == 1'b1) begin                                 
                        axi_awready <= 1'b1;                                 
                        axi_wready <= 1'b1;                                 
                        state_write <= Waddr;                                 
                    end                                 
                    else
                        state_write <= state_write;                                 
                end                                 
                Waddr: begin                                 
                    if (S_AXI_AWVALID && S_AXI_AWREADY) begin                                 
                        axi_awaddr <= S_AXI_AWADDR;                                 
                        if(S_AXI_WVALID) begin                                   
                            axi_awready <= 1'b1;                                 
                            state_write <= Waddr;                                 
                            axi_bvalid <= 1'b1;                                 
                        end                                 
                        else begin                                 
                            axi_awready <= 1'b0;                                 
                            state_write <= Wdata;                                 
                            if (S_AXI_BREADY && axi_bvalid) 
                                axi_bvalid <= 1'b0;                                 
                        end                                 
                    end                                 
                    else begin                                 
                        state_write <= state_write;                                 
                        if (S_AXI_BREADY && axi_bvalid)
                            axi_bvalid <= 1'b0;                                 
                    end                                 
                end                                 
                Wdata: begin                                 
                    if (S_AXI_WVALID) begin                                 
                        state_write <= Waddr;                                 
                        axi_bvalid <= 1'b1;                                 
                        axi_awready <= 1'b1;                                 
                    end                                 
                    else begin                                 
                        state_write <= state_write;                                 
                        if (S_AXI_BREADY && axi_bvalid) 
                            axi_bvalid <= 1'b0;                                 
                    end                                              
                end                                 
            endcase                                 
        end                                 
    end                                 

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            rst_reg         <= 0;
            status_reg      <= 0;
            imem_we_reg     <= 0;
            imem_addr_reg   <= 0;
            imem_data_reg   <= 0;
            dmem_re_reg     <= 0;
            dmem_addr_reg   <= 0;
        end 
        else begin
            if (S_AXI_WVALID) begin
                case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                    4'd0:
                        if(S_AXI_WSTRB[0])
                            rst_reg[0]          <= S_AXI_WDATA[0];
                    4'd1:
                        if(S_AXI_WSTRB[0])
                            status_reg[1:0] <= {1'b0, S_AXI_WDATA[0]}; //start enable, turn-off done
                    4'd2:
                        if(S_AXI_WSTRB[0])
                            imem_we_reg[0]         <= S_AXI_WDATA[0];
                    4'd3:
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 )
                                imem_addr_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    4'd4:
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 )
                                imem_data_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end  
                    4'd5:
                        if(S_AXI_WSTRB[0])
                            dmem_re_reg[0]         <=S_AXI_WDATA[0];
                    4'd6:
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 )
                                dmem_addr_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    default : begin
                        rst_reg         <= rst_reg;
                        status_reg      <= status_reg;
                        imem_we_reg     <= imem_we_reg;
                        imem_addr_reg   <= imem_addr_reg;
                        imem_data_reg   <= imem_data_reg;
                        dmem_re_reg     <= dmem_re_reg;
                        dmem_addr_reg   <= dmem_addr_reg;
                    end
                endcase
            end 
      end
    end    

	// Implement read state machine
    always @(posedge S_AXI_ACLK) begin                                       
        if (S_AXI_ARESETN == 1'b0) begin                                       
	         //asserting initial values to all 0's during reset                                       
	         axi_arready <= 1'b0;                                       
	         axi_rvalid <= 1'b0;                                       
	         axi_rresp <= 1'b0;   
	         axi_araddr <= 'b0;  //taidao added 24/5                                   
	         state_read <= Idle;                                       
        end                                       
        else begin                                       
            case(state_read)                                       
                Idle: begin    //Initial state inidicating reset is done and ready to receive read/write transactions                                                                                    
                    if (S_AXI_ARESETN == 1'b1) begin                                       
                        state_read <= Raddr;                                       
                        axi_arready <= 1'b1;                                       
                    end                                       
                    else 
                        state_read <= state_read;                                       
                end                                       
                Raddr: begin        //At this state, slave is ready to receive address along with corresponding control signals                                                                         
                    if (S_AXI_ARVALID && S_AXI_ARREADY) begin                                       
                        state_read <= Rdata;                                       
                        axi_araddr <= S_AXI_ARADDR;                                       
                        axi_rvalid <= 1'b1;                                       
                        axi_arready <= 1'b0;                                       
                    end                                       
                    else
                        state_read <= state_read;                                       
                end                                       
                Rdata: begin        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                                                              
                    if (S_AXI_RVALID && S_AXI_RREADY) begin                                       
                        axi_rvalid <= 1'b0;                                       
                        axi_arready <= 1'b1;                                       
                        state_read <= Raddr;                                       
                    end                                       
                    else
                        state_read <= state_read;                                       
                end                                       
            endcase                                       
        end                                       
    end                                         
	// Implement memory mapped register select and read logic generation
	always @(*) begin
	   if(S_AXI_ARESETN == 1'b0)
	       axi_rdata <= 'b0;
	   else begin
	       case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
	           4'd0: axi_rdata <= rst_reg;
	           4'd1: axi_rdata <= status_reg;
	           4'd2: axi_rdata <= imem_we_reg;
	           4'd3: axi_rdata <= imem_addr_reg;
	           4'd4: axi_rdata <= imem_data_reg;
	           4'd5: axi_rdata <= dmem_re_reg;
	           4'd6: axi_rdata <= dmem_addr_reg;
	           4'd7: axi_rdata <= RV32I_DMEM_DATA_R_I;
	           4'd8: axi_rdata <= RV32I_ID_PC_I;
	           4'd9: axi_rdata <= RV32I_ID_INST_I;
	           default:
	                 axi_rdata <= 'b0;
	       endcase
	   end
	end
	// Add user logic here
    assign RV32I_RST_N          = !rst_reg[0];
    assign RV32I_START          = status_reg[0];
    assign RV32I_IMEM_WE_O      = imem_we_reg[0];
    assign RV32I_IMEM_ADDR_O    = imem_addr_reg;
    assign RV32I_IMEM_INST_O    = imem_data_reg;
    assign RV32I_DMEM_RE_O      = dmem_re_reg[0];
    assign RV32I_DMEM_ADDR_O    = dmem_addr_reg;
	// User logic ends

endmodule
