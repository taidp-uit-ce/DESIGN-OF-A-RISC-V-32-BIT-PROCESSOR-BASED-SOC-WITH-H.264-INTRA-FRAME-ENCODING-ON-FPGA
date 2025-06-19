
`timescale 1 ns / 1 ps

	module H264_Intra_Encoder_v2_0 #
	(
		// Users to add parameters here
        parameter integer   MM2S_FIFO_DEPTH = 1024,
        parameter integer   S2MM_FIFO_DEPTH = 1024,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI_LITE
		parameter integer C_S_AXI_LITE_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_LITE_ADDR_WIDTH	= 4,

		// Parameters of Axi Slave Bus Interface S_AXIS_MM2S
		parameter integer C_S_AXIS_MM2S_TDATA_WIDTH	= 64,

		// Parameters of Axi Master Bus Interface M_AXIS_S2MM
		parameter integer C_M_AXIS_S2MM_TDATA_WIDTH	= 64
	)
	(
		// Users to add ports here
        input wire  h264_aclk,
        input wire  h264_aresetn,
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

		// Ports of Axi Slave Bus Interface S_AXIS_MM2S
		input wire  s_axis_mm2s_aclk,
		input wire  s_axis_mm2s_aresetn,
		output wire  s_axis_mm2s_tready,
		input wire [C_S_AXIS_MM2S_TDATA_WIDTH-1 : 0] s_axis_mm2s_tdata,
		input wire [(C_S_AXIS_MM2S_TDATA_WIDTH/8)-1 : 0] s_axis_mm2s_tkeep,
		input wire  s_axis_mm2s_tlast,
		input wire  s_axis_mm2s_tvalid,

		// Ports of Axi Master Bus Interface M_AXIS_S2MM
		input wire  m_axis_s2mm_aclk,
		input wire  m_axis_s2mm_aresetn,
		output wire  m_axis_s2mm_tvalid,
		output wire [C_M_AXIS_S2MM_TDATA_WIDTH-1 : 0] m_axis_s2mm_tdata,
		output wire [(C_M_AXIS_S2MM_TDATA_WIDTH/8)-1 : 0] m_axis_s2mm_tkeep,
		output wire  m_axis_s2mm_tlast,
		input wire  m_axis_s2mm_tready
	);
	//User wire
	wire [7:0]      h264_wdata;
	wire            h264_wvalid;
	wire            h264_wready;
	
	wire            h264_start;      
    wire            h264_done;		
    wire [5:0]      h264_qp;
    wire [10:0]     h264_width;
    wire [10:0]     h264_height;
             
    wire          	h264_rvalid;
    wire         	h264_rready;
    wire  [63:0]  	h264_rdata;
  
	//End user wire
	
// Instantiation of Axi Bus Interface S_AXI_LITE
	H264_Intra_Encoder_slave_lite_v5_0_S_AXI_LITE # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_LITE_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_LITE_ADDR_WIDTH)
	) H264_Intra_Encoder_slave_lite_v5_0_S_AXI_LITE_inst (
		.S_AXI_ACLK(s_axi_lite_aclk),
		.S_AXI_ARESETN(s_axi_lite_aresetn),
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
		//taidao begin
		.H264_ACLK(h264_aclk),
		.H264_ARESETN(h264_aresetn),
		.H264_START_O(h264_start),
		.H264_QP_O(h264_qp),
		.H264_HEIGHT_O(h264_height),
		.H264_WIDTH_O(h264_width),
        .H264_DONE_I(h264_done)
        //taidao end
	);

// Instantiation of Axi Bus Interface S_AXIS_MM2S
	H264_Intra_Encoder_slave_stream_v5_0_S_AXIS_MM2S # ( 
		.C_S_AXIS_TDATA_WIDTH (C_S_AXIS_MM2S_TDATA_WIDTH),
		.MM2S_FIFO_DEPTH      (MM2S_FIFO_DEPTH)
	) H264_Intra_Encoder_slave_stream_v5_0_S_AXIS_MM2S_inst (
		.S_AXIS_ACLK      (s_axis_mm2s_aclk),
		.S_AXIS_ARESETN   (s_axis_mm2s_aresetn),
		.S_AXIS_TREADY    (s_axis_mm2s_tready),
		.S_AXIS_TDATA     (s_axis_mm2s_tdata),
		.S_AXIS_TKEEP     (s_axis_mm2s_tkeep),
		.S_AXIS_TLAST     (s_axis_mm2s_tlast),
		.S_AXIS_TVALID    (s_axis_mm2s_tvalid),
		//taidao
		.H264_ACLK        (h264_aclk),
		.H264_ARESETN     (h264_aresetn),
		.H264_RREADY_I    (h264_rready),
        .H264_RVALID_O    (h264_rvalid),
        .H264_RDATA_O     (h264_rdata)
		//taidao
	);

// Instantiation of Axi Bus Interface M_AXIS_S2MM
	H264_Intra_Encoder_master_stream_v5_0_M_AXIS_S2MM # ( 
		.C_M_AXIS_TDATA_WIDTH (C_M_AXIS_S2MM_TDATA_WIDTH),
		.S2MM_FIFO_DEPTH      (S2MM_FIFO_DEPTH)
	) H264_Intra_Encoder_master_stream_v5_0_M_AXIS_S2MM_inst (
		.M_AXIS_ACLK      (m_axis_s2mm_aclk),
		.M_AXIS_ARESETN   (m_axis_s2mm_aresetn),
		.M_AXIS_TVALID    (m_axis_s2mm_tvalid),
		.M_AXIS_TDATA     (m_axis_s2mm_tdata),
		.M_AXIS_TKEEP     (m_axis_s2mm_tkeep),
		.M_AXIS_TLAST     (m_axis_s2mm_tlast),
		.M_AXIS_TREADY    (m_axis_s2mm_tready),
		
		//taidao
		.H264_ACLK        (h264_aclk),
		.H264_ARESETN     (h264_aresetn),
		.H264_WDATA_I     (h264_wdata),
		.H264_WVALID_I    (h264_wvalid),
		.H264_WREADY_O    (h264_wready),
		.H264_START_I     (h264_start),
		.H264_DONE_I      (h264_done)
		//
	);

    h264_core u_h264_core     (
                    .clk      			( h264_aclk    ),
                    .rst_n    			( h264_aresetn ),
                    
                    .sys_start			( h264_start   ),      
                    .sys_done			( h264_done    ),		
                    .sys_qp				( h264_qp	   ),         
                    .sys_height         ( h264_height  ),
                    .sys_width          ( h264_width   ),
                    
                    .rdata_i  			( h264_rdata   ),
                    .rvalid_i 			( h264_rvalid  ),
                    .rready_o   	    ( h264_rready  ),
                    
                    .wdata_o  			( h264_wdata   ),
                    .wvalid_o	  	    ( h264_wvalid  )
//                    .wready_i           (h264_wready)      <= need to add
                    );

endmodule
