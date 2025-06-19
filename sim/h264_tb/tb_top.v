`include "enc_defines.v"
`define FRAMEWIDTH 1920
`define FRAMEHEIGHT 1080
`define FRAME_TOTAL 50
`define INIT_QP 18
`define MB_X_TOTAL ((`FRAMEWIDTH + 15) / 16)
`define MB_Y_TOTAL ((`FRAMEHEIGHT + 15) / 16)

`define AUTO_CHECK
`define DUMP_BS
//`define DUMP_S2MM //taidao 23/4


module tb_top;
parameter real CLK_PERIOD = 16;
parameter   YUV_FILE    = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\crowd_run_1080p_50f\\cur_mb_p4.dat";
parameter   CHECK_FILE  = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\crowd_run_1080p_50f\\crowd_run_1080p_50f_qp18\\bs_check.dat";
parameter   BS_PATH     = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\crowd_run_1080p_50f\\crowd_run_1080p_50f_qp18\\rtl_dumpbs_1920x1080_50f_qp18.dat";
parameter   FPS_RESULT  = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\crowd_run_1080p_50f\\crowd_run_1080p_50f_qp18\\fps_dumpbs_1920x1080_50f_qp18.dat";
parameter   S2MM_PATH   = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\crowd_run_1080p_50f\\crowd_run_1080p_50f_qp18\\s2mm_dumpbs_1920x1080_50f_qp18.dat";
// ********************************************
//
//    IO DECLARATION
//
// ********************************************
reg 		 					clk, rst_n;
// CMD IN IF
reg								sys_start;      
wire							sys_done;		
reg [ 5:0]						sys_qp;
reg [10:0]                      sys_width;
reg [10:0]                      sys_height;
reg [ 8:0]                      sys_frame_total;
// FIFO IN IF
reg          					rvalid_i;
wire         					rready_o;
reg  [63:0]  					rdata_i;
// FIFO OUT IF
wire [7:0]   					wdata_o;
wire                            wvalid_o;

reg  [7:0]   					frame_num;
//taidao
wire [63:0] tdata_o         ;
wire        tvalid_o        ;
wire        tlast_o         ;
wire [ 7:0] tkeep_o         ;
wire        wready_o        ;
reg         tready_i        ;
//taidao 
//-------------------------------------------------------
// 				DUT                          
//-------------------------------------------------------
h264_core u_top     (
				.clk      			( clk      			),
				.rst_n    			( rst_n    			),
				
				.sys_start			( sys_start		    ),      
				.sys_done			( sys_done		    ),		
				.sys_qp				( sys_qp			),         
                .sys_height         ( sys_height        ),
                .sys_width          ( sys_width         ),
				
				.rdata_i  			( rdata_i  			),
				.rvalid_i 			( rvalid_i 			),
				.rready_o   		( rready_o   		),
				.wdata_o  			( wdata_o  			),
				.wvalid_o	  		( wvalid_o	 		)
			
				//taidao
//				.tdata_o            ( tdata_o           ),
//				.tvalid_o           ( tvalid_o          ),
//				.tlast_o            ( tlast_o           ),
//				.tkeep_o            ( tkeep_o           ),
//				.wready_o           ( wready_o          ),
//				.tready_i           ( tready_i          )
				//taidao
);

//-------------------------------------------------------
// 				pixel ram input
//-------------------------------------------------------
reg [31:0]	 					addr_r, cnt;
reg [31:0]   					pixel_ram[1<<30:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_i  <= 'b0;
        rvalid_i <= 1'b0;
        addr_r   <= 'b0;
        tready_i <= 1'b1;
    end 
    else begin
        if(rvalid_i && !rready_o) begin
            rdata_i  <= rdata_i;
            rvalid_i <= rvalid_i;
            addr_r   <= addr_r;
        end
        else begin
            rdata_i  <= {pixel_ram[2*addr_r+0], pixel_ram[2*addr_r+1]};
            rvalid_i <= 1'b1;
            addr_r   <= addr_r+1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	   cnt  <= 'b0;
    end 
    else if (rready_o) begin
	   cnt  <= cnt+1;
    end
    else begin
	   cnt  <= cnt; //taidao 23/4 changed 'b0 => cnt
    end
end

// clk                                          
initial begin                                   
	clk = 1'b0;                                 
	forever #(CLK_PERIOD/2) clk = ~clk;                     
end 

//rst_n
initial begin
    rst_n 	 = 'b0;
    #CLK_PERIOD	rst_n	= 1'b1;
end 
//more
initial begin
    rvalid_i = 'b0;
	rdata_i  = 'b0;
	
	sys_start		= 1'b0;     
	sys_qp			= `INIT_QP;     
	sys_height      = `FRAMEHEIGHT;
	sys_width       = `FRAMEWIDTH;
	sys_frame_total = `FRAME_TOTAL;
end

reg  [31:0] clk_count       ;
reg         all_passed      ;	
reg [31:0]  clk_count_start , 
            clk_count_end   ,
            clk_per_frame   ,
            clk_total       ;
real        fps, time_total ;	

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clk_count       <= 0;
        clk_count_start <= 0;
        clk_count_end   <= 0; 
        clk_per_frame   <= 0;
    end
    else
        clk_count       <= clk_count + 1'b1;
end   
                                        
integer file_status;
integer fps_file;

initial begin 
    file_status = $fopen(YUV_FILE, "r");
    if (file_status == 0) begin
        $display("Error: Could not open file %s", YUV_FILE);
        $finish;
    end else begin
        $display("File %s opened successfully", YUV_FILE);
        $fclose(file_status);
    end   
	$readmemh(YUV_FILE, pixel_ram);
	
	// Mở file FPS_RESULT ở chế độ append để không ghi đè
    fps_file = $fopen(FPS_RESULT, "w"); 
    if (fps_file == 0) begin
        $display("Error: Could not open FPS result file: %s", FPS_RESULT);
        $finish;
    end
    
	frame_num 		= 0;
	clk_total       = 0;
	for (frame_num=0; frame_num<`FRAME_TOTAL; frame_num=frame_num+1'b1) begin
		#(5*CLK_PERIOD); 
        $display("%0d, Frame Number = %d :INTRA MODE \n",$time, frame_num);
            sys_start = 1'b1;
            clk_count_start = clk_count;     
		#CLK_PERIOD sys_start = 1'b0;
		
	    #CLK_PERIOD wait(sys_done == 1'b1);
	        clk_count_end = clk_count;
	        
	    clk_per_frame = clk_count_end - clk_count_start;
	    clk_total = clk_total + clk_per_frame; 
	    fps = 1/((CLK_PERIOD / 1000000000.0) * clk_per_frame);
	    $fwrite(fps_file, "Frame %d: %f FPS   -- Number of clk pulses: %d\n", frame_num, fps, clk_per_frame);
        $display("Frame %d: %f FPS   -- Number of clk pulses: %d\n", frame_num, fps, clk_per_frame);
	end	
	// Ghi FPS trung bình vào cuối file	

    fps         = 1000000000.0 / ((clk_total * CLK_PERIOD) / `FRAME_TOTAL);
    time_total  = (clk_total * CLK_PERIOD) / 1000000000.0;
    $fwrite(fps_file, "AVERAGE FPS: %f\n", fps);
    $fwrite(fps_file, "ENCODING TIME: %f\n", time_total);
    
    // �?óng file sau khi hoàn tất ghi dữ liệu
    $fclose(fps_file);
    
	if(all_passed) begin
	   $display("===============RESULT SUMMARY===============");
	   $display("TEST RESULT           : PASSED");
	   $display("AVARAGE FPS           : %0f", fps);
	end
	else begin
	   $display("===============RESULT SUMMARY===============");
	   $display("TEST RESULT           : FAILED");
	   $display("AVARAGE FPS           : %0f", fps);
	end
	#5000;
    	$finish;
end
// -------------------------------------------------------
//                  DUMP bit stream
// -------------------------------------------------------
`ifdef DUMP_BS
integer f_bs;
integer bs_num;

initial begin
	bs_num = 0;
	f_bs = $fopen(BS_PATH,"wb");
end

always @(frame_num)
	$fdisplay(f_bs, "@%0d", frame_num);
	
always @(posedge clk) begin
	if (u_top.wvalid_o) begin
		$fdisplay(f_bs, "%h ", u_top.wdata_o);
		if (u_top.frame_done) begin	
			$fwrite(f_bs, "\n"); 
		end
	end
end	

`endif

// -------------------------------------------------------
//                  DUMP S2MM STREAM
// -------------------------------------------------------
`ifdef DUMP_S2MM
integer out_file;
integer i;

initial begin
    out_file = $fopen(S2MM_PATH, "w");
    if (out_file == 0) begin
        $display("ERROR: Failed to open output file!");
        $finish;
    end
end

always @(posedge clk) begin
    if (tvalid_o && tready_i) begin
        for (i = 0; i < 8; i = i + 1) begin
            if (tkeep_o[i]) begin
                $fwrite(out_file, "%02x\n", tdata_o[8*i +: 8]);
            end
        end
        if (tlast_o) begin
            $display("End of packet/frame (TLAST received)");
        end
    end
end
`endif

// -------------------------------------------------------
//                  AUTO CHECK
// -------------------------------------------------------
`ifdef AUTO_CHECK
integer     fp_check;
reg [7:0]   check_data;

initial begin
    all_passed = 1'b1;
	fp_check = $fopen(CHECK_FILE, "r");
end

always @(posedge clk) begin
    if(!rst_n) begin
        check_data  <= 'b0;
    end
	else if (u_top.wvalid_o) begin
		$fscanf(fp_check, "%h", check_data);
		if (check_data !== u_top.wdata_o) begin
		    all_passed = 1'b0;
			$display("ERROR(MB x:%3d y:%3d): check_data(%h) != bs_data(%h)", u_top.mb_x_ec, u_top.mb_y_ec, check_data, u_top.wdata_o);
//			#5000 $finish;
		end
		else begin
              $display("MATCHED(MB x:%3d y:%3d): check_data(%h) == bs_data(%h)", u_top.mb_x_ec, u_top.mb_y_ec, check_data, u_top.wdata_o);
		end
	end	
end

`endif

// -------------------------------------------------------
//                     DUMP FSDB
// -------------------------------------------------------
`ifdef DUMP_FSDB
initial begin 
	$fsdbDumpfile(DUMP_FILE);
	$fsdbDumpvars;
	$fsdbDumpoff;
	wait(frame_num==0);
	$fsdbDumpon;
end
`endif

// -------------------------------------------------------
//                  DUMP current MB
// -------------------------------------------------------
`ifdef DUMP_CUR_MB
integer f_cmb;
integer cmb_i, cmb_j;
initial begin
	f_cmb = $fopen("./dump/cur_mb.dat ","wb");
end

always @(frame_num)
	$fdisplay(f_cmb, "Frame Number =%3d", frame_num);

always @(posedge clk) begin	
	if (u_top.load_done) begin
		$fwrite(f_cmb, "\nMB_X =%d, MB_Y =%d\n", u_top.mb_x_load, u_top.mb_y_load);
		$fwrite(f_cmb, "==Y==\n");
		for (cmb_i=0; cmb_i<16; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<16; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_y[16*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end
		$fwrite(f_cmb, "==U==\n");
		for (cmb_i=0; cmb_i<8; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<8; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_u[8*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end		
		$fwrite(f_cmb, "==V==\n");
		for (cmb_i=0; cmb_i<8; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<8; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_v[8*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end		
	end
end
`endif

// -------------------------------------------------------
//                 Include Dump Bench
// -------------------------------------------------------
//`include "./bench/ime_dump.v"
//`include "./bench/fme_dump.v"
//`include "./bench/mc_dump.v"
//`include "./bench/intra_dump.v"
//`include "./bench/tq_dump.v"
//`include "./bench/db_dump.v"
//`include "./bench/cavlc_dump.v"

endmodule
