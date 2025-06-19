`timescale 1 ns / 1 ps

	module H264_Intra_Encoder_slave_stream_v5_0_S_AXIS_MM2S #
	(
		parameter integer C_S_AXIS_TDATA_WIDTH	= 64,
		parameter integer MM2S_FIFO_DEPTH = 1024
	)
	(
		input wire      H264_ACLK,
		input wire      H264_ARESETN,
        input           H264_RREADY_I,
        output          H264_RVALID_O,
        output [63:0]   H264_RDATA_O,

		input wire    S_AXIS_ACLK,
		input wire    S_AXIS_ARESETN,
		output wire   S_AXIS_TREADY,
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]       S_AXIS_TDATA,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0]   S_AXIS_TKEEP,
		input wire    S_AXIS_TLAST,
		input wire    S_AXIS_TVALID
	);
	localparam [1:0]   IDLE = 1'b0,
	                   WRITE_FIFO  = 1'b1;
	                   
	wire   axis_tready;
    wire   wr_ready, wr_fifo_full, wr_en, rd_empty;
    wire [C_S_AXIS_TDATA_WIDTH-1:0] rd_data;
    reg    rd_valid_reg;
    reg    mst_exec_state;  
	reg    writes_done;
	
    assign S_AXIS_TREADY = ((mst_exec_state == WRITE_FIFO) && !wr_fifo_full);
    assign wr_en         = S_AXIS_TVALID & S_AXIS_TREADY;
	
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) begin  
        if (!S_AXIS_ARESETN) 
	       mst_exec_state <= IDLE;
        else
            case (mst_exec_state)
                IDLE: 
                    if (S_AXIS_TVALID)
                        mst_exec_state <= WRITE_FIFO;
                    else
                        mst_exec_state <= IDLE;
                WRITE_FIFO: 
                    if (writes_done)
                        mst_exec_state <= IDLE;
                    else
                        mst_exec_state <= WRITE_FIFO;
            endcase
	end
 
	always@(posedge S_AXIS_ACLK) begin
        if(!S_AXIS_ARESETN)
            writes_done <= 1'b0; 
        else if(S_AXIS_TLAST)
            writes_done <= 1'b1;
        else
            writes_done <= writes_done;
	end    
	assign H264_RVALID_O = !rd_empty;
	fifo_async #(.DEPTH(MM2S_FIFO_DEPTH), .DATA_WIDTH(C_S_AXIS_TDATA_WIDTH)) u_async_fifo (
                                                .wr_clk         (S_AXIS_ACLK),
                                                .wr_rst_n       (S_AXIS_ARESETN),
                                                .wr_data_i      (S_AXIS_TDATA),
                                                .wr_en_i        (wr_en), 
                                                .wr_full_o      (wr_fifo_full),
                                                .rd_clk         (H264_ACLK),
                                                .rd_rst_n       (H264_ARESETN),
                                                .rd_empty_o     (rd_empty),  
                                                .rd_en_i        (H264_RREADY_I),
//                                                .rd_valid_o     (H264_RVALID_O),
                                                .rd_data_o      (H264_RDATA_O));
	
endmodule
