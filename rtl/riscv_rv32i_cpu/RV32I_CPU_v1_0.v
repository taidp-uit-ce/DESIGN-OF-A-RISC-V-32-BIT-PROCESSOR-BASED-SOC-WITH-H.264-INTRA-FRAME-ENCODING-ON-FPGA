`timescale 1 ns / 1 ps

	module RV32I_CPU_v1_0 #
	(
		// Users to add parameters here
        parameter integer RV32I_IMEM_DEPTH = 1,
        parameter integer RV32I_DMEM_DEPTH = 4,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI_LITE
		parameter integer C_S_AXI_LITE_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_LITE_ADDR_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M_AXI_LITE
		parameter integer C_M_AXI_LITE_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_LITE_DATA_WIDTH	= 32
	)
	(
		// Users to add ports here
//        input wire rv32i_aclk,
//        input wire rv32i_aresetn,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI_LITE
		input wire  s_axi_lite_aclk,
		input wire  s_axi_lite_aresetn,
		input wire [C_S_AXI_LITE_ADDR_WIDTH-1 : 0] s_axi_lite_awaddr,
		input wire [2 : 0] s_axi_lite_awprot,
		input wire  s_axi_lite_awvalid,
		output wire  s_axi_lite_awready,
		input wire [C_S_AXI_LITE_DATA_WIDTH-1 : 0] s_axi_lite_wdata,
		input wire [(C_S_AXI_LITE_DATA_WIDTH/8)-1 : 0] s_axi_lite_wstrb,
		input wire  s_axi_lite_wvalid,
		output wire  s_axi_lite_wready,
		output wire [1 : 0] s_axi_lite_bresp,
		output wire  s_axi_lite_bvalid,
		input wire  s_axi_lite_bready,
		input wire [C_S_AXI_LITE_ADDR_WIDTH-1 : 0] s_axi_lite_araddr,
		input wire [2 : 0] s_axi_lite_arprot,
		input wire  s_axi_lite_arvalid,
		output wire  s_axi_lite_arready,
		output wire [C_S_AXI_LITE_DATA_WIDTH-1 : 0] s_axi_lite_rdata,
		output wire [1 : 0] s_axi_lite_rresp,
		output wire  s_axi_lite_rvalid,
		input wire  s_axi_lite_rready,

		// Ports of Axi Master Bus Interface M_AXI_LITE
		input wire  m_axi_lite_aclk,
		input wire  m_axi_lite_aresetn,
		output wire [C_M_AXI_LITE_ADDR_WIDTH-1 : 0] m_axi_lite_awaddr,
		output wire [2 : 0] m_axi_lite_awprot,
		output wire  m_axi_lite_awvalid,
		input wire  m_axi_lite_awready,
		output wire [C_M_AXI_LITE_DATA_WIDTH-1 : 0] m_axi_lite_wdata,
		output wire [C_M_AXI_LITE_DATA_WIDTH/8-1 : 0] m_axi_lite_wstrb,
		output wire  m_axi_lite_wvalid,
		input wire  m_axi_lite_wready,
		input wire [1 : 0] m_axi_lite_bresp,
		input wire  m_axi_lite_bvalid,
		output wire  m_axi_lite_bready,
		output wire [C_M_AXI_LITE_ADDR_WIDTH-1 : 0] m_axi_lite_araddr,
		output wire [2 : 0] m_axi_lite_arprot,
		output wire  m_axi_lite_arvalid,
		input wire  m_axi_lite_arready,
		input wire [C_M_AXI_LITE_DATA_WIDTH-1 : 0] m_axi_lite_rdata,
		input wire [1 : 0] m_axi_lite_rresp,
		input wire  m_axi_lite_rvalid,
		output wire  m_axi_lite_rready
	);
	//User wire
	//for master if
	wire        rv32i_stall, rv32i_reg_we;
	wire [4:0]  rv32i_addr_d;
    wire [31:0] rv32i_data_r;
    wire        m_axi_init, m_axi_reg_we, m_axi_mem_we;
    wire [2:0]  m_axi_funct3;
    wire [4:0]  m_axi_addr_d;
    wire [31:0] m_axi_addr_per, m_axi_data_w;
    
    //for slave if
	wire [31:0] axi_dmem_data_r, axi_id_pc, axi_id_inst;
	wire        rv32i_rstn, rv32i_start, rv32i_imem_we, rv32i_dmem_re;
	wire [31:0] rv32i_imem_addr, rv32i_imem_data, rv32i_dmem_addr;
	//End user wire
// Instantiation of Axi Bus Interface S_AXI_LITE
	RV32I_CPU_v1_0_S_AXI_LITE # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_LITE_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_LITE_ADDR_WIDTH)
	) S_AXI_LITE_inst (
		.S_AXI_ACLK(s_axi_lite_aclk), //rv32i_aclk
		.S_AXI_ARESETN(s_axi_lite_aresetn), //rv32i_aresetn
		.S_AXI_AWADDR(s_axi_lite_awaddr),
		.S_AXI_AWPROT(s_axi_lite_awprot),
		.S_AXI_AWVALID(s_axi_lite_awvalid),
		.S_AXI_AWREADY(s_axi_lite_awready),
		.S_AXI_WDATA(s_axi_lite_wdata),
		.S_AXI_WSTRB(s_axi_lite_wstrb),
		.S_AXI_WVALID(s_axi_lite_wvalid),
		.S_AXI_WREADY(s_axi_lite_wready),
		.S_AXI_BRESP(s_axi_lite_bresp),
		.S_AXI_BVALID(s_axi_lite_bvalid),
		.S_AXI_BREADY(s_axi_lite_bready),
		.S_AXI_ARADDR(s_axi_lite_araddr),
		.S_AXI_ARPROT(s_axi_lite_arprot),
		.S_AXI_ARVALID(s_axi_lite_arvalid),
		.S_AXI_ARREADY(s_axi_lite_arready),
		.S_AXI_RDATA(s_axi_lite_rdata),
		.S_AXI_RRESP(s_axi_lite_rresp),
		.S_AXI_RVALID(s_axi_lite_rvalid),
		.S_AXI_RREADY(s_axi_lite_rready),

		.RV32I_ID_PC_I(axi_id_pc),
		.RV32I_ID_INST_I(axi_id_inst),
		.RV32I_RST_N(rv32i_rstn),
		.RV32I_START(rv32i_start),
		.RV32I_IMEM_WE_O(rv32i_imem_we),
		.RV32I_IMEM_ADDR_O(rv32i_imem_addr),
		.RV32I_IMEM_INST_O(rv32i_imem_data),
		.RV32I_DMEM_RE_O(rv32i_dmem_re),
		.RV32I_DMEM_ADDR_O(rv32i_dmem_addr),
		.RV32I_DMEM_DATA_R_I(axi_dmem_data_r)
	);

// Instantiation of Axi Bus Interface M_AXI_LITE
	RV32I_CPU_v1_0_M_AXI_LITE # ( 
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_LITE_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_LITE_DATA_WIDTH)
	) M_AXI_LITE_inst (
		.M_AXI_ACLK(m_axi_lite_aclk), // rv32i_aclk
		.M_AXI_ARESETN(m_axi_lite_aresetn), // rv32i_aresetn
		.M_AXI_AWADDR(m_axi_lite_awaddr),
		.M_AXI_AWPROT(m_axi_lite_awprot),
		.M_AXI_AWVALID(m_axi_lite_awvalid),
		.M_AXI_AWREADY(m_axi_lite_awready),
		.M_AXI_WDATA(m_axi_lite_wdata),
		.M_AXI_WSTRB(m_axi_lite_wstrb),
		.M_AXI_WVALID(m_axi_lite_wvalid),
		.M_AXI_WREADY(m_axi_lite_wready),
		.M_AXI_BRESP(m_axi_lite_bresp),
		.M_AXI_BVALID(m_axi_lite_bvalid),
		.M_AXI_BREADY(m_axi_lite_bready),
		.M_AXI_ARADDR(m_axi_lite_araddr),
		.M_AXI_ARPROT(m_axi_lite_arprot),
		.M_AXI_ARVALID(m_axi_lite_arvalid),
		.M_AXI_ARREADY(m_axi_lite_arready),
		.M_AXI_RDATA(m_axi_lite_rdata),
		.M_AXI_RRESP(m_axi_lite_rresp),
		.M_AXI_RVALID(m_axi_lite_rvalid),
		.M_AXI_RREADY(m_axi_lite_rready),
		.TXN_AXI_INIT (m_axi_init),
        .TXN_DONE   (),
        .addr_per_i (m_axi_addr_per), // Dia chi cho lw sw
        .funct3_i   (m_axi_funct3),
        .data_w_i   (m_axi_data_w),
        .mem_we_i   (m_axi_mem_we),
        .reg_we_i   (m_axi_reg_we),
        .addr_d_i   (m_axi_addr_d),  
        .data_r_o   (rv32i_data_r),
        .reg_we_o   (rv32i_reg_we),
        .addr_d_o   (rv32i_addr_d),
        .stall_o    (rv32i_stall)
	);

	// Add user logic here
    RV32I_CORE #(.RV32I_IMEM_DEPTH(RV32I_IMEM_DEPTH), .RV32I_DMEM_DEPTH(RV32I_DMEM_DEPTH)) 
        U_RV32I_CORE(
                    .clk              (m_axi_lite_aclk),
                    .rst_n            (m_axi_lite_aresetn & rv32i_rstn),
                    .m_axi_stall_i    (rv32i_stall),
                    .m_axi_reg_we_i   (rv32i_reg_we),
                    .m_axi_addr_d_i   (rv32i_addr_d),
                    .m_axi_data_d_i   (rv32i_data_r),
                    
                    .m_axi_funct3_o   (m_axi_funct3),
                    .m_axi_init_o     (m_axi_init),
                    .m_axi_reg_we_o   (m_axi_reg_we),
                    .m_axi_mem_we_o   (m_axi_mem_we),
                    .m_axi_addr_d_o   (m_axi_addr_d),
                    .m_axi_addr_o     (m_axi_addr_per),
                    .m_axi_data_w_o   (m_axi_data_w),
                    
                    .s_axi_id_pc_o      (axi_id_pc),
                    .s_axi_id_inst_o    (axi_id_inst),
                    .s_axi_start_i      (rv32i_start),
                    .s_axi_imem_we_i    (rv32i_imem_we),
                    .s_axi_imem_addr_i  (rv32i_imem_addr),
                    .s_axi_imem_data_i  (rv32i_imem_data),
                    .s_axi_dmem_re_i    (rv32i_dmem_re),
                    .s_axi_dmem_addr_i  (rv32i_dmem_addr),
                    .s_axi_dmem_data_r_o(axi_dmem_data_r)
                );
	// User logic ends

	endmodule