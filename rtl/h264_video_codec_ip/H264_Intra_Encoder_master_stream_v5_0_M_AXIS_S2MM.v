`timescale 1 ns / 1 ps
module H264_Intra_Encoder_master_stream_v5_0_M_AXIS_S2MM #
	(
		parameter integer C_M_AXIS_TDATA_WIDTH	= 64,
		parameter integer S2MM_FIFO_DEPTH = 1024
	)
	(
		// Users to add ports here
        input wire          H264_ACLK,
		input wire          H264_ARESETN,
        input wire [(C_M_AXIS_TDATA_WIDTH/8)-1:0]    H264_WDATA_I,
        input wire          H264_WVALID_I,
        output              H264_WREADY_O,
        input wire          H264_START_I,
        input wire          H264_DONE_I,  
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TKEEP,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
    localparam  IDLE    = 3'b000,
                START   = 3'b001,
                COLLECT = 3'b010,
                SEND    = 3'b011,
                LAST    = 3'b100;
                
	wire       wr_full, wr_full_sync, rd_empty, rd_ready;//, rd_valid;
	wire [7:0] rd_data;
	reg [3:0]  byte_count;
    reg        rd_ready_reg;
	reg [2:0]  mst_exec_state;
	reg                                 tvalid_reg, tlast_reg;
    reg [(C_M_AXIS_TDATA_WIDTH/8)-1:0]  tkeep_reg;
    reg [C_M_AXIS_TDATA_WIDTH-1:0]      tdata_reg;
    wire                                h264_done_sync, h264_start_sync;     
    
    fifo_async #(.DEPTH(S2MM_FIFO_DEPTH*8), .DATA_WIDTH(C_M_AXIS_TDATA_WIDTH/8)) u_async_fifo (
                                                .wr_clk     (H264_ACLK),
                                                .wr_rst_n   (H264_ARESETN),
                                                .wr_data_i  (H264_WDATA_I),
                                                .wr_en_i    (H264_WVALID_I), 
                                                .wr_full_o  (wr_full),
                                                .rd_clk     (M_AXIS_ACLK),
                                                .rd_rst_n   (M_AXIS_ARESETN),
                                                .rd_empty_o (rd_empty),  
                                                .rd_en_i (rd_ready),
//                                                .rd_valid_o (rd_valid),
                                                .rd_data_o  (rd_data)
                                            );
    synchronizer #(.WIDTH(0)) u_done_sync       (.clk( M_AXIS_ACLK  ), .rst_n( M_AXIS_ARESETN   ), .data_i( H264_DONE_I ), .data_o( h264_done_sync  ));
    synchronizer #(.WIDTH(0)) u_start_sync      (.clk( M_AXIS_ACLK  ), .rst_n( M_AXIS_ARESETN   ), .data_i( H264_START_I), .data_o( h264_start_sync ));
    synchronizer #(.WIDTH(0)) u_h264_ready_sync (.clk( H264_ACLK    ), .rst_n( H264_ARESETN     ), .data_i( wr_full     ), .data_o( wr_full_sync    ));

    assign rd_ready        = rd_ready_reg;
	assign H264_WREADY_O   = !wr_full_sync;
	assign M_AXIS_TVALID   = tvalid_reg;
	assign M_AXIS_TDATA    = tdata_reg;
	assign M_AXIS_TKEEP    = tkeep_reg;
	assign M_AXIS_TLAST    = tlast_reg;
	
    //fsm
    always @(posedge M_AXIS_ACLK) begin
        if(!M_AXIS_ARESETN) begin
            tvalid_reg      <= 'b0;
            tdata_reg       <= 'b0;
            tkeep_reg       <= 'b0;
            tlast_reg       <= 'b0;
            rd_ready_reg    <= 'b0;
            byte_count      <= 'b0;
            mst_exec_state  <= IDLE;
        end
        else begin
            case(mst_exec_state)
                IDLE: begin
                    if(h264_start_sync)
                        mst_exec_state  <= START;
                    else
                        mst_exec_state  <= IDLE;
                end
                START: begin
                    rd_ready_reg    <= 'b1;
                    if(!h264_done_sync)
                        mst_exec_state  <= COLLECT;
                    else
                        mst_exec_state  <= mst_exec_state;
                end
                COLLECT: begin
                    if(!rd_empty) begin
                        tkeep_reg[byte_count]           <= 1'b1;
                        tdata_reg[byte_count*8 +: 8]    <= rd_data;
                        byte_count                      <= byte_count + 1'b1;
                        
                        if(byte_count >= 7) begin
                            tvalid_reg          <= 1'b1;
                            rd_ready_reg        <= 1'b0;
                            tlast_reg           <= 1'b0;
                            mst_exec_state      <= SEND;
                        end
                        else if (byte_count < 7) begin
                            tvalid_reg          <= 1'b0;
                            rd_ready_reg        <= 1'b1;
                            mst_exec_state      <= mst_exec_state;
                        end
                    end
                    else begin //rd_empty
                        if(h264_done_sync) begin
                            if(byte_count > 7) begin
                                tvalid_reg      <= 1'b1;
                                rd_ready_reg    <= 1'b0;
                                tlast_reg       <= 1'b1;
                                mst_exec_state  <= SEND;
                            end
                            else begin
                                tvalid_reg      <= 1'b1;
                                rd_ready_reg    <= 1'b0;
                                tlast_reg       <= 1'b1;
                                mst_exec_state  <= LAST;
                            end
                        end
                        else begin
                            tvalid_reg      <= tvalid_reg;
                            rd_ready_reg    <= rd_ready_reg;
                            tlast_reg       <= tlast_reg;
                            mst_exec_state  <= mst_exec_state;
                        end
                    end
                end
                SEND: begin
                    if (M_AXIS_TREADY && tvalid_reg) begin
                        byte_count       <= byte_count - 4'd8;
                        tkeep_reg        <= 'b0;
                        tvalid_reg       <= 1'b0;
                        tlast_reg        <= 1'b0;
                        rd_ready_reg     <= 1'b1;
                        mst_exec_state   <= COLLECT;
                    end
                    else
                        mst_exec_state   <= mst_exec_state;
                end
                LAST: begin
                    if (M_AXIS_TREADY && tvalid_reg) begin
                        byte_count       <= 'b0;
                        tkeep_reg        <= 'b0;
                        tvalid_reg       <= 1'b0;
                        tlast_reg        <= 1'b0;
                        rd_ready_reg     <= 1'b0;
                        mst_exec_state   <= IDLE;
                    end
                    else
                        mst_exec_state   <= mst_exec_state;
                end
                default:
                    mst_exec_state   <= IDLE;
            endcase
        end
    end
    
	// User logic ends
endmodule
