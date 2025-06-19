`include "enc_defines.v"

module h264_core     (
				clk				,
				rst_n			,		
				sys_start		,      
				sys_done		,		
				sys_qp			, 
				sys_height      ,
				sys_width       ,
				rdata_i			,
				rvalid_i		,
				rready_o		,
				wdata_o			,
				wvalid_o						
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input 		  					clk, rst_n;
// SYS IF
input							sys_start;     
output							sys_done;		                			
input [ 5:0]					sys_qp;
input [10:0] 		            sys_height;    
input [10:0]  		            sys_width;
// RAW INPUT IF
input [8*`BIT_DEPTH - 1:0]   	rdata_i;
input          					rvalid_i;
output         					rready_o;
// STREAM OUTPUT IF
output [7:0]   					wdata_o;
output         					wvalid_o;
// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
//------------------ system ------------------//
wire [`PIC_W_MB_LEN-1:0] 		sys_x_total;    
wire [`PIC_H_MB_LEN-1:0]  		sys_y_total;

//------------------ u_top_ctrl ------------------//
wire                       	load_start, intra_start, ec_start, frame_start;
wire                       	load_done , intra_done , ec_done , frame_done ; 
wire [`PIC_W_MB_LEN-1:0]   	mb_x_total, mb_x_load, mb_x_intra, mb_x_ec;   
wire [`PIC_H_MB_LEN-1:0]   	mb_y_total, mb_y_load, mb_y_intra, mb_y_ec;                            
wire [5:0]    				intra_qp, ec_qp;  
reg  [5:0]					tq_qp, qp_r, qp_r3;  

wire               			bs_empty;

//------------------ u_cur_mb -----------------//
wire                 		mb_switch;
wire   [256*8-1:0]   		cur_y;              
wire   [64*8-1 :0]   		cur_u, cur_v;

//-------------------- mem_arb --------------------//
//luma/chroma ref MB req channel 
wire           				load_luma_en   , load_chroma_en   ;
wire           				load_luma_done , load_chroma_done ;
wire [`PIC_W_MB_LEN-1:0]  	load_luma_mb_x , load_chroma_mb_x ;
wire [`PIC_H_MB_LEN-1:0]  	load_luma_mb_y , load_chroma_mb_y ;
wire						load_luma_valid, load_chroma_valid;
wire [63:0]  				load_luma_data , load_chroma_data ;

//-------------------- u_intra --------------------//
wire          				intra_mb_type_info;
wire [1:0]    				intra_16x16_mode; 
wire [1:0]    				intra_chroma_mode;              				
wire [63:0]   				intra_4x4_bm;   // intra 4x4 used mode 
wire [63:0]   				intra_4x4_pm;   // intra 4x4 predicted mode (base on surrounding blocks)
      
//-------------------- u_tq --------------------//
// TQ i4x4 IF
wire 						tq_i4x4_en;  
wire [3:0]					tq_i4x4_mod; 
wire [3:0]					tq_i4x4_blk; 
wire 						tq_i4x4_min; 
wire 						tq_i4x4_end; 
wire 						tq_i4x4_val; 
wire [3:0]					tq_i4x4_num;   
// TQ i16x16 IF         	
wire 						tq_i16x16_en; 
wire [3:0] 					tq_i16x16_blk;
wire 						tq_i16x16_val;
wire [3:0]					tq_i16x16_num; 
// TQ p16x16 IF         	   
wire 						tq_p16x16_en; 
wire [3:0] 					tq_p16x16_blk;
wire 						tq_p16x16_val;
wire [3:0]					tq_p16x16_num; 
// TQ Chroma IF, two source: intra/inter frame            
wire 						i_tq_chroma_en  , tq_chroma_en	;		
wire [2:0]					i_tq_chroma_num , tq_chroma_num	;
wire 						tq_cb_val		;	    
wire [3:0]					tq_cb_num		;	    
wire 						tq_cr_val		;	    
wire [3:0]					tq_cr_num		;	  
// intra and mux predicted pixels    
wire  [`BIT_DEPTH-1:0]		i_pre00, i_pre01, i_pre02, i_pre03, 
							i_pre10, i_pre11, i_pre12, i_pre13, 
							i_pre20, i_pre21, i_pre22, i_pre23, 
							i_pre30, i_pre31, i_pre32, i_pre33;
reg  [`BIT_DEPTH-1:0]		tq_pre00, tq_pre01, tq_pre02, tq_pre03,
							tq_pre10, tq_pre11, tq_pre12, tq_pre13,
							tq_pre20, tq_pre21, tq_pre22, tq_pre23,
							tq_pre30, tq_pre31, tq_pre32, tq_pre33;		
// intra and mux residual pixels 																	                      
wire  [`BIT_DEPTH:0]		i_res00, i_res01, i_res02, i_res03, 
							i_res10, i_res11, i_res12, i_res13, 
							i_res20, i_res21, i_res22, i_res23, 
							i_res30, i_res31, i_res32, i_res33;
reg  [`BIT_DEPTH:0]			tq_res00, tq_res01, tq_res02, tq_res03,
							tq_res10, tq_res11, tq_res12, tq_res13,
							tq_res20, tq_res21, tq_res22, tq_res23,
							tq_res30, tq_res31, tq_res32, tq_res33;	
// rec pixels from tq												
wire [`BIT_DEPTH-1:0]		tq_rec00, tq_rec01, tq_rec02, tq_rec03,
							tq_rec10, tq_rec11, tq_rec12, tq_rec13,
							tq_rec20, tq_rec21, tq_rec22, tq_rec23,
							tq_rec30, tq_rec31, tq_rec32, tq_rec33;	
// EC Output IF
wire [8:0]    				tq_cbp ;
wire [3:0]					tq_cbp_luma;
wire [1:0]					tq_cbp_chroma;
wire [2:0]					tq_cbp_dc;
wire [15:0]   				tq_non_zero_luma;
wire [3:0]    				tq_non_zero_cr;
wire [3:0]    				tq_non_zero_cb;

//---------------------- u_ec ---------------------//
// from intra
reg          				ec_intra_type;
reg [1:0]    				ec_16x16_mode;
reg [1:0]    				ec_chroma_mode;
reg [63:0]   				ec_4x4_bm;   
reg [63:0]   				ec_4x4_pm;   
// from tq
reg  [8:0]    				ec_cbp ;			
wire [4:0]					ec_level_raddr;
wire [255:0]				ec_level_rdata;
// cavlc & bs_buf
wire          				cavlc_we ;
wire [3:0]    				cavlc_inc;
wire [83:0]   				cavlc_codebit;
wire [7:0]    				cavlc_rbsp_trailing;

//-------------------------------------------------------------------
//               
//                global signals assignment 
// 
//------------------------------------------------------------------- 
assign sys_x_total = ((sys_width + 15) / 16) - 1'b1;
assign sys_y_total = ((sys_height + 15) / 16) - 1'b1;

assign mb_x_total = sys_x_total;
assign mb_y_total = sys_y_total; 

// qp pipeline
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		qp_r <= 'b0;
    else if (intra_start)
		qp_r <= sys_qp;
    else
        qp_r <= qp_r; //taidao 22/4
end

always @(posedge clk or negedge rst_n)begin
	if (!rst_n)
		qp_r3 <= 'b0;
    else if (ec_start)
		qp_r3 <= qp_r;
end

assign intra_qp = qp_r;
assign ec_qp    = qp_r3;

//-------------------------------------------------------------------
//               
//                top module controller 
// 
//-------------------------------------------------------------------
top_ctrl      u_top_ctrl(
				.clk                 ( clk              ),
				.rst_n               ( rst_n            ),
				
				.sys_start		     ( sys_start		),
				.sys_done		     ( sys_done		    ),			
				.sys_x_total         ( sys_x_total      ),
				.sys_y_total	     ( sys_y_total	    ),
				
				.frame_start_o       ( frame_start      ),  //wire
				.frame_done_o        ( frame_done       ),  //wire
				.load_start_o        ( load_start       ),  // => enc_ld_start (output)
				.intra_start_o       ( intra_start      ),
				.ec_start_o          ( ec_start         ),
				
				.load_done_i       	 ( load_done        ),
				.intra_done_i        ( intra_done       ),
				.ec_done_i           ( ec_done          ),
				.bs_empty_i          ( bs_empty         ),
				
				.mb_x_load           ( mb_x_load        ),
				.mb_y_load           ( mb_y_load        ),
				.mb_x_intra          ( mb_x_intra       ),
				.mb_y_intra          ( mb_y_intra       ),
				.mb_x_ec             ( mb_x_ec          ),
				.mb_y_ec             ( mb_y_ec          )		
);  
            
//current macroblock loading 
assign mb_switch = load_start||intra_start;

load_mb  u_load_mb(  
				.clk              ( clk             ),  
				.rst_n            ( rst_n           ),  
				.load_start	      ( load_start      ),
				.load_done        ( load_done       ),
				.pvalid_i		  ( rvalid_i        ),
				.pready_o         ( rready_o        ),
				.pdata_i	      ( rdata_i         ),
				.mb_switch		  ( mb_switch       ),
				.cur_y_o          ( cur_y           ),  
				.cur_u_o          ( cur_u           ),  
				.cur_v_o          ( cur_v           )  
);
          
//Intra Block
intra_top u_intra_top(
				.clk             ( clk                 	),
				.rst_n           ( rst_n               	),
				.mb_x_total      ( mb_x_total 		 	), 
				.mb_x            ( mb_x_intra 		 	),
				.mb_y            ( mb_y_intra 		 	),
				.mb_luma         ( cur_y         	    ),
				.mb_cb           ( cur_u   		 	    ),  
				.mb_cr			 ( cur_v   		 	    ),  
				.qp		         ( intra_qp             ),
							
				.start_i         ( intra_start         	),
				.done_o	         ( intra_done          	),
								
				.intra_mode_o    ( intra_mb_type_info  	),
				.i4x4_bm_o   	 ( intra_4x4_bm        	),
				.i4x4_pm_o       ( intra_4x4_pm        	),
				.i16x16_mode_o   ( intra_16x16_mode     ),
				.chroma_mode_o	 ( intra_chroma_mode   	),	
				
				.tq_i4x4_en_o    ( tq_i4x4_en	        ), 
				.tq_i4x4_mod_o   ( tq_i4x4_mod          ), 
				.tq_i4x4_num_o   ( tq_i4x4_blk          ), 
				.tq_i4x4_min_o   ( tq_i4x4_min          ), 
				.tq_i4x4_end_o   ( tq_i4x4_end          ), 
				.tq_i4x4_val_i   ( tq_i4x4_val          ), 
				.tq_i4x4_num_i   ( tq_i4x4_num          ), 
				 				                                        
				.tq_i16x16_en_o  ( tq_i16x16_en         ), 
				.tq_i16x16_num_o ( tq_i16x16_blk        ), 
				.tq_i16x16_val_i ( tq_i16x16_val        ), 
				.tq_i16x16_num_i ( tq_i16x16_num		), 
				
				.tq_chroma_en_o  ( i_tq_chroma_en		), 
				.tq_chroma_num_o ( i_tq_chroma_num     	),    
				.tq_cb_val_i     ( tq_cb_val         	),    
				.tq_cb_num_i     ( tq_cb_num         	),    
				.tq_cr_val_i     ( tq_cr_val         	),    
				.tq_cr_num_i     ( tq_cr_num         	),    		
				
				.pre00 ( i_pre00 ), .pre01 ( i_pre01 ), .pre02 ( i_pre02 ), .pre03 ( i_pre03 ),
                .pre10 ( i_pre10 ), .pre11 ( i_pre11 ), .pre12 ( i_pre12 ), .pre13 ( i_pre13 ),
                .pre20 ( i_pre20 ), .pre21 ( i_pre21 ), .pre22 ( i_pre22 ), .pre23 ( i_pre23 ),
                .pre30 ( i_pre30 ), .pre31 ( i_pre31 ), .pre32 ( i_pre32 ), .pre33 ( i_pre33 ),
          
                .res00 ( i_res00 ), .res01 ( i_res01 ), .res02 ( i_res02 ), .res03 ( i_res03 ),
                .res10 ( i_res10 ), .res11 ( i_res11 ), .res12 ( i_res12 ), .res13 ( i_res13 ),
                .res20 ( i_res20 ), .res21 ( i_res21 ), .res22 ( i_res22 ), .res23 ( i_res23 ),
                .res30 ( i_res30 ), .res31 ( i_res31 ), .res32 ( i_res32 ), .res33 ( i_res33 ),
       
                .rec00 ( tq_rec00 ), .rec01 ( tq_rec01 ), .rec02 ( tq_rec02 ), .rec03 ( tq_rec03 ),
                .rec10 ( tq_rec10 ), .rec11 ( tq_rec11 ), .rec12 ( tq_rec12 ), .rec13 ( tq_rec13 ),
                .rec20 ( tq_rec20 ), .rec21 ( tq_rec21 ), .rec22 ( tq_rec22 ), .rec23 ( tq_rec23 ),
                .rec30 ( tq_rec30 ), .rec31 ( tq_rec31 ), .rec32 ( tq_rec32 ), .rec33 ( tq_rec33 )
);

//-------------------------------------------------------------------
//                                                                   
//          TQ Block                                              
//                                                                   
//-------------------------------------------------------------------
assign tq_chroma_en	 = i_tq_chroma_en ;	
assign tq_chroma_num = i_tq_chroma_num;

always @(*) begin
    tq_pre00 = i_pre00; tq_pre01 = i_pre01; tq_pre02 = i_pre02; tq_pre03 = i_pre03;
    tq_pre10 = i_pre10; tq_pre11 = i_pre11; tq_pre12 = i_pre12; tq_pre13 = i_pre13;
    tq_pre20 = i_pre20; tq_pre21 = i_pre21; tq_pre22 = i_pre22; tq_pre23 = i_pre23;
    tq_pre30 = i_pre30; tq_pre31 = i_pre31; tq_pre32 = i_pre32; tq_pre33 = i_pre33;
        
    tq_res00 = i_res00; tq_res01 = i_res01; tq_res02 = i_res02; tq_res03 = i_res03;
    tq_res10 = i_res10; tq_res11 = i_res11; tq_res12 = i_res12; tq_res13 = i_res13;
    tq_res20 = i_res20; tq_res21 = i_res21; tq_res22 = i_res22; tq_res23 = i_res23;
    tq_res30 = i_res30; tq_res31 = i_res31; tq_res32 = i_res32; tq_res33 = i_res33;	
    
    tq_qp    = intra_qp;
end

tq_top u_tq_top(
				.clk             ( clk                 	),
				.rst_n           ( rst_n               	),		
				.qp		         ( tq_qp                ),

				.i4x4_en_i 		 ( tq_i4x4_en	        ),      	
				.i4x4_mod_i		 ( tq_i4x4_mod          ),
				.i4x4_num_i		 ( tq_i4x4_blk          ),
				.i4x4_min_i		 ( tq_i4x4_min          ),
				.i4x4_end_i		 ( tq_i4x4_end          ),
				.i4x4_val_o		 ( tq_i4x4_val          ),
				.i4x4_num_o		 ( tq_i4x4_num          ),
				
				.i16x16_en_i     ( tq_i16x16_en         ),
				.i16x16_num_i    ( tq_i16x16_blk        ),
				.i16x16_val_o    ( tq_i16x16_val        ),
				.i16x16_num_o    ( tq_i16x16_num		),	
				
				.chroma_en_i     ( tq_chroma_en			),
				.chroma_num_i    ( tq_chroma_num        ),
				.cb_val_o        ( tq_cb_val            ),
				.cb_num_o        ( tq_cb_num            ),
				.cr_val_o        ( tq_cr_val            ),
				.cr_num_o        ( tq_cr_num            ),
				
				.pre00 ( tq_pre00 ), .pre01 ( tq_pre01 ), .pre02 ( tq_pre02 ), .pre03 ( tq_pre03 ),
                .pre10 ( tq_pre10 ), .pre11 ( tq_pre11 ), .pre12 ( tq_pre12 ), .pre13 ( tq_pre13 ),
                .pre20 ( tq_pre20 ), .pre21 ( tq_pre21 ), .pre22 ( tq_pre22 ), .pre23 ( tq_pre23 ),
                .pre30 ( tq_pre30 ), .pre31 ( tq_pre31 ), .pre32 ( tq_pre32 ), .pre33 ( tq_pre33 ),
                    
                .res00 ( tq_res00 ), .res01 ( tq_res01 ), .res02 ( tq_res02 ), .res03 ( tq_res03 ),
                .res10 ( tq_res10 ), .res11 ( tq_res11 ), .res12 ( tq_res12 ), .res13 ( tq_res13 ),
                .res20 ( tq_res20 ), .res21 ( tq_res21 ), .res22 ( tq_res22 ), .res23 ( tq_res23 ),
                .res30 ( tq_res30 ), .res31 ( tq_res31 ), .res32 ( tq_res32 ), .res33 ( tq_res33 ),
       
                .rec00 ( tq_rec00 ), .rec01 ( tq_rec01 ), .rec02 ( tq_rec02 ), .rec03 ( tq_rec03 ),
                .rec10 ( tq_rec10 ), .rec11 ( tq_rec11 ), .rec12 ( tq_rec12 ), .rec13 ( tq_rec13 ),
                .rec20 ( tq_rec20 ), .rec21 ( tq_rec21 ), .rec22 ( tq_rec22 ), .rec23 ( tq_rec23 ),
                .rec30 ( tq_rec30 ), .rec31 ( tq_rec31 ), .rec32 ( tq_rec32 ), .rec33 ( tq_rec33 ),
                
                .mem_sw	  			( ec_start			),     
                			
                .ec_mem_rd			( 1'b1    			),   
                .ec_mem_raddr		( ec_level_raddr	),     
                .ec_mem_rdata		( ec_level_rdata	),     //output    
                                                                          	
                .non_zero_flag4x4	( tq_non_zero_luma 	),
				.non_zero_flag_cr	( tq_non_zero_cr   	),
				.non_zero_flag_cb	( tq_non_zero_cb   	),				                                          	
				.cbp_luma           ( tq_cbp_luma       ),
				.cbp_chroma			( tq_cbp_chroma		),
				.cbp_dc				( tq_cbp_dc			)	          
);

// for Intra_16x16, cbp_luma=4'b1111 or 4'b0000 (has one non_zero equals to 4'b1111)
// for Intra_4x4 and P Frame, cbp_luma = {non_zero_8x8}x4
assign tq_cbp = {tq_cbp_dc, tq_cbp_chroma, (intra_mb_type_info)?{4{|tq_cbp_luma}}:tq_cbp_luma};

//-------------------------------------------------------------------
//               
//  entropy coding (CAVLC) module 
// 
//------------------------------------------------------------------- 
// save mc/intra outputs for ec coding
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin		
		ec_intra_type  	 <= 'b0;
		ec_chroma_mode   <= 'b0;
		ec_16x16_mode    <= 'b0;
		ec_4x4_bm        <= 'b0;
		ec_4x4_pm        <= 'b0;
		
		ec_cbp			 <= 'b0;		
	end
	else if(ec_start)begin
		ec_intra_type  	 <= intra_mb_type_info ; 
		ec_chroma_mode   <= intra_chroma_mode  ; 
		ec_16x16_mode    <= intra_16x16_mode   ; 
		ec_4x4_bm        <= intra_4x4_bm       ; 
		ec_4x4_pm        <= intra_4x4_pm       ;
		
		ec_cbp			 <= tq_cbp             ;		
	end
end

cavlc_top u_cavlc_top (
				.clk              ( clk                 ),
				.rst_n            ( rst_n               ),
				.mb_x             ( mb_x_ec		        ),
				.mb_y             ( mb_y_ec		        ),
				.qp				  ( ec_qp				),
				.ref_idx          (                     ),
				// start done
				.start            ( ec_start            ),
				.cavlc_done       ( ec_done          	),
				// slice header state
				.sh_enc_done      ( frame_start         ),
				.remain_bit_sh    ( 8'b0                ),
				.remain_len_sh    ( 3'b0                ),
				// tq
				.cbp_i            ( ec_cbp           	),
				.addr_o		 	  ( ec_level_raddr		),
				.data_i		  	  ( ec_level_rdata		),
				// intra
				.mb_type_intra_i  ( ec_intra_type  		),
				.chroma_mode_i    ( ec_chroma_mode   	),
				.intra16x16_mode_i( ec_16x16_mode    	),
				.intra4x4_bm_i    ( ec_4x4_bm        	),
				.intra4x4_pm_i    ( ec_4x4_pm        	),
				// output
				.we               ( cavlc_we            ),
				.tmpAddr          ( cavlc_inc           ),
				.codebit          ( cavlc_codebit       ),
				.rbsp_trailing    ( cavlc_rbsp_trailing )
);


// bitstream output module
bs_buf  u_bs_buf(
				.clk              ( clk                 ),
				.rst_n            ( rst_n               ),
				.frame_done       ( frame_done          ),
				.sh_we 			  ( 1'b0				),
				.sh_inc           ( 2'b0				),
				.sh_bit           ( 24'b0				),
				.cavlc_we         ( cavlc_we            ),
				.cavlc_inc        ( cavlc_inc           ),
				.cavlc_bit        ( cavlc_codebit       ),
				.rbsp_trailing    ( cavlc_rbsp_trailing ),
				.bs_valid         ( wvalid_o            ),
				.bs_o             ( wdata_o             ),
				.bs_empty_o       ( bs_empty            )
);	

endmodule
