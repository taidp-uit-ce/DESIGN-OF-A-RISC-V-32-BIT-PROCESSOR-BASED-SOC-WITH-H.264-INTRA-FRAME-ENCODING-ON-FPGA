`include "enc_defines.v"

module MB_header_enc_v2(
				clk,
				rst_n,
				cavlc_en,
				start,
				mb_type_intra,
				cbp ,
				chroma_mode ,
				intra16x16_mode ,
				intra4x4_bm ,
				intra4x4_pm ,
				control_state ,
				scan_state ,
				cnt4x4 ,
				codebit0,
				codelength0,
				state,
				scan_en,
				valid,
				cnt,
				i_cbp_luma,
				i_cbp_chroma,
				i_cbp_dc,
				scan_done,
				skip,
				ref_idx,
				qp,
				mb_x,
				mb_y
);

parameter 	scan_init    = 4'b0000; //scan init
parameter	scan_cycle0  = 4'b0001; //scan clock 1
parameter	scan_cycle1  = 4'b0010; //scan clock 2
parameter	scan_cycle2  = 4'b0011; //scan clock 3
parameter	scan_cycle3  = 4'b0100; //scan clock 4
parameter	scan_cycle4  = 4'b0101; //scan clock 5
parameter	scan_cycle5  = 4'b0110; //scan clock 6
parameter	scan_cycle6  = 4'b0111; //scan clock 7
parameter   scan_cycle7  = 4'b1000; //scan clock 7
  
parameter   D_L0_4x4     = 2'd0;
parameter   D_L0_8x4     = 2'd1;    //same as software
parameter   D_L0_4x8     = 2'd2;    //same as software
parameter   D_L0_8x8     = 2'd3;

parameter   IDLE         = 3'b000;
parameter	E_INTRA4x4   = 3'b001;
parameter	E_INTRA16x16 = 3'b010;

parameter   I_4x4        = 1'b0;
parameter	I_16x16      = 1'b1;

parameter   D_8x8        = 2'd0;
parameter   D_8x4        = 2'd1;
parameter   D_4x8        = 2'd2;
parameter   D_4x4        = 2'd3;

	
	
	
input                     clk, rst_n;        // 
input                     cavlc_en;          // 
input  	                  start;             // 
input                     mb_type_intra;     // intra mb type
input	          [8:0]   cbp ;              // which 8*8 block is 0 
input	          [1:0]   chroma_mode ;      // 
input	          [1:0]   intra16x16_mode ;  // 
input	          [63:0]  intra4x4_bm ;      // intra used pred mode
input	          [63:0]  intra4x4_pm ;      // intra prev pred mode 
input             [4:0]   cnt4x4 ;           // 4*4 count (have header)
input             [3:0]   scan_state ;       // 
input             [2:0]   control_state ;    // block hua fen 
input             [15:0]  ref_idx ;          // can kao zhen xin xi
input		      [5:0]   qp;		     //input qp parameter.
input             [7:0]   mb_x;
input             [7:0]   mb_y;

output    reg     [8:0]   codebit0;          // code of bits
output    reg     [4:0]   codelength0;       // code bits long
output    reg     [2:0]   state;             // 
output    reg             scan_en;           // 
output    reg             valid;             // 
output            [5:0]   cnt;               // 
output            [3:0]   i_cbp_luma;        // 
output            [1:0]   i_cbp_chroma;      // 
output            [2:0]   i_cbp_dc;          // 
output                    scan_done;         // scan over
output                    skip;              // 

//-----------------------------


reg  [2:0] next_state;
reg  [3:0] mode_used0, mode_pred0;
reg  [5:0] cnt;
reg        done;
reg [5:0]  qp_catch;
reg  [2:0] state_delay;


wire [5:0]          intra16x16_type_length;
wire [3:0]          intra16x16_ue_length;
wire [2:0]          chroma_length;
wire [2:0]          chroma_ue_length;
wire [4:0]          mb_i_offset;
wire signed [5:0]   delta_qp;
wire [10:0]         delta_qp_codebit;
wire [3:0]          delta_qp_length;


always @(posedge clk or negedge rst_n) begin
	if (~rst_n)
		qp_catch <= 'd0;
	else if (mb_x=='d0 && mb_y=='d0) 
	    qp_catch <= qp;
    else if ((state_delay == E_INTRA4x4 && cnt == 'd19 && (i_cbp_luma!=0 ||i_cbp_chroma != 0)) || (state_delay == E_INTRA16x16 && cnt == 'd3))
		qp_catch <= qp;
end

assign delta_qp =(mb_x=='d0 && mb_y=='d0) ? 'd0 : (qp - qp_catch);

Delta_qp_enc u_Delta_qp_enc (
				.delta_qp (delta_qp),
				.codebit  (delta_qp_codebit),
				.length   (delta_qp_length)
);


// state change FSM
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
	   state_delay <= IDLE;
	else 
	   state_delay <= state;
end

// clock count at state working
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		cnt <= 0;
	end
	else if(state!=IDLE)begin
		cnt <= cnt + 1'b1;
	end
	else begin
		cnt <= 0;
	end
end

assign skip = i_cbp_luma == 0 && i_cbp_chroma == 0 && (( control_state == E_INTRA4x4   && ( cnt==5'd19 )));

// scan over				
assign scan_done = ( cavlc_en && scan_state == scan_cycle7 && (
		 ( control_state != E_INTRA16x16 && control_state != E_INTRA16x16 && 
		 ( cnt4x4 == 5'd25 || cnt4x4 == 5'd17&&i_cbp_chroma != 2'd2
		|| cnt4x4 == 5'd15 && i_cbp_chroma == 2'd0
		|| cnt4x4 == 5'd11 && i_cbp_chroma == 2'd0 && ~i_cbp_luma[3]
		|| cnt4x4 == 5'd7  && i_cbp_chroma == 2'd0 && ~i_cbp_luma[3]&& ~i_cbp_luma[2]
		|| cnt4x4 == 5'd3  && i_cbp_chroma == 2'd0 && ~i_cbp_luma[3]&& ~i_cbp_luma[2]&& ~i_cbp_luma[1]))
  		|| (control_state == E_INTRA16x16) && (cnt4x4 == 5'd26 
  		|| i_cbp_luma=='d0&&(i_cbp_chroma=='d1&&cnt4x4=='d18)
 		|| i_cbp_luma!=0&&( cnt4x4 == 5'd16&&i_cbp_chroma == 2'd0||cnt4x4 == 5'd18&&i_cbp_chroma != 2'd2)
 		|| i_cbp_luma=='d0&&i_cbp_chroma=='d0&&cnt4x4=='d0 ) ) )? 1'b1 : 1'b0;
		 

//  judge scan_en valid or not
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)  
		scan_en <= 1'b0;
	else if(scan_done)
		scan_en <= 1'b0;
	else if(cavlc_en&&~skip)
	    scan_en <= done;
	else 
		scan_en <= 1'b0;
end




// intra 4x4 pred mode --------
always @(*) begin
	if( cnt==5'd1 )begin
		mode_used0 = intra4x4_bm[63:60];  // used 
		mode_pred0 = intra4x4_pm[63:60];  // prev
	end
	else if( cnt==5'd2)begin
		mode_used0 = intra4x4_bm[59:56];
		mode_pred0 = intra4x4_pm[59:56];
	end
	else if( cnt==5'd3)begin
		mode_used0 = intra4x4_bm[55:52];
		mode_pred0 = intra4x4_pm[55:52];
	end
	else if( cnt==5'd4)begin
		mode_used0 = intra4x4_bm[51:48];
		mode_pred0 = intra4x4_pm[51:48];
	end
	else if( cnt==5'd5)begin
		mode_used0 = intra4x4_bm[47:44];
		mode_pred0 = intra4x4_pm[47:44];
	end
	else if( cnt==5'd6)begin
		mode_used0 = intra4x4_bm[43:40];
		mode_pred0 = intra4x4_pm[43:40];
	end
	else if( cnt==5'd7)begin
		mode_used0 = intra4x4_bm[39:36];
		mode_pred0 = intra4x4_pm[39:36];
	end
	else if( cnt==5'd8)begin
		mode_used0 = intra4x4_bm[35:32];
		mode_pred0 = intra4x4_pm[35:32];
	end
	else if( cnt==5'd9)begin
		mode_used0 = intra4x4_bm[31:28];
		mode_pred0 = intra4x4_pm[31:28];
	end
	else if( cnt==5'd10)begin
		mode_used0 = intra4x4_bm[27:24];
		mode_pred0 = intra4x4_pm[27:24];
	end
	else if( cnt==5'd11)begin
		mode_used0 = intra4x4_bm[23:20];
		mode_pred0 = intra4x4_pm[23:20];
	end
	else if( cnt==5'd12)begin
		mode_used0 = intra4x4_bm[19:16];
		mode_pred0 = intra4x4_pm[19:16];
	end
	else if( cnt==5'd13)begin
		mode_used0 = intra4x4_bm[15:12];
		mode_pred0 = intra4x4_pm[15:12];
	end
	else if( cnt==5'd14)begin
		mode_used0 = intra4x4_bm[11:8];
		mode_pred0 = intra4x4_pm[11:8];
	end
	else if( cnt==5'd15)begin
		mode_used0 = intra4x4_bm[7:4];
		mode_pred0 = intra4x4_pm[7:4];
	end
	else if( cnt==5'd16)begin
		mode_used0 = intra4x4_bm[3:0];
		mode_pred0 = intra4x4_pm[3:0];
	end
	else begin
		mode_used0 = 4'b0 ;
		mode_pred0 = 4'b0 ;
	end
end



//header state 
always @(*) begin
	case(state)
		IDLE : begin
			valid = 0;
			if(cavlc_en && start) begin
				if(mb_type_intra==I_4x4 )
					next_state = E_INTRA4x4;
				else if(mb_type_intra==I_16x16)
					next_state = E_INTRA16x16;   
			    else  
			        next_state = IDLE; 
			end
            else  
                next_state = IDLE; 	
		end
		E_INTRA4x4, E_INTRA16x16 : begin
			valid = 1'b1;
			if(cavlc_en && ~done)
				next_state = state;
			else 
				next_state = IDLE;
		end		
		default: begin
			valid = 1'b0;
			next_state = IDLE;
		end
	endcase
end

wire [5:0] cbp_i;
wire [1:0] i_cbp_chroma;
wire [2:0] i_cbp_dc;
wire [5:0] tmpVal;
wire [5:0] intra4x4_cbp;
wire [5:0] cbp_code;
wire [5:0] cbp_codebit;
wire [3:0] cbp_code_length;

//----------intra 16*16 header coding---------------
assign tmpVal = {i_cbp_chroma,2'b0};

assign intra16x16_type_length = 2'd2 + intra16x16_mode
								+ tmpVal + ((i_cbp_luma==0)?1'b0:4'd12);
	
assign intra16x16_ue_length = (intra16x16_type_length>6'd15 )? 4'd9
							: (intra16x16_type_length>6'd7  )? 4'd7
							: (intra16x16_type_length>6'd3  )? 4'd5
							: (intra16x16_type_length>6'd1  )? 4'd3
							: 4'd1;
//--------------------------------------------------


//------------chroma header coding -----------------
assign chroma_length = chroma_mode + 1'b1;
assign chroma_ue_length = (chroma_length==1'b1)? 3'd1 
                        : (chroma_length<3'b100)? 3'd3
						: 3'd5;
//--------------------------------------------------


assign i_cbp_dc     = cbp[8:6];
assign i_cbp_chroma = cbp[5:4];
assign i_cbp_luma   = cbp[3:0];

//--------------  cbp coning ---------------------
assign cbp_i = {i_cbp_chroma, i_cbp_luma};
cbp_enc_v2 u_cbp_enc_v2(
	.cbp          ( cbp_i        ),
	.intra4x4_cbp ( intra4x4_cbp )  // intra cbp coding
);

assign cbp_code = intra4x4_cbp;

assign cbp_codebit = cbp_code + 1'b1; //add in table.
assign cbp_code_length =(cbp_codebit>6'd31 )? 4'd11
					  : (cbp_codebit>6'd15 )? 4'd9
					  : (cbp_codebit>6'd7  )? 4'd7
					  : (cbp_codebit>6'd3  )? 4'd5
					  : (cbp_codebit>6'd1  )? 4'd3
					  : 4'd1;

//macroblock header encoding
always @(*) begin
	if(state == E_INTRA4x4) begin //begin of intra4x4    //offset
		if(cnt==0)begin 
			codebit0 = 9'b1;
			codelength0 = 1'b1;
		end
		else if(cnt<5'd17) begin  //8x8 ģʽ�о�	//mode
			if(mode_used0 == mode_pred0)begin
				codebit0 = 9'b1;
				codelength0 = 1'b1;
			end
			else begin
				if(mode_used0>mode_pred0)begin
					codebit0 = mode_used0-1'b1;
					codelength0 = 3'd4;
				end
				else begin
					codebit0 = mode_used0;
					codelength0 = 3'd4;
				end
			end
		end
		else if(cnt== 5'd17)begin  // chroma header coding
			codebit0 = chroma_length;
			codelength0 = chroma_ue_length;
		end
		//cbp
		else if(cnt == 5'd18) begin  // intra cbp coding
			codebit0 = cbp_codebit;
			codelength0 = cbp_code_length;
		end
		else if(cnt == 5'd19 && (i_cbp_luma!=0 ||i_cbp_chroma != 0))begin//delta qp
			codebit0 = delta_qp_codebit;
			codelength0 = delta_qp_length;
		end
		else begin // end
			codebit0 = 0;
			codelength0 = 0;
		end			
	end
	
	else if(state == E_INTRA16x16) begin // intra16x16
	 	if(cnt==0) begin  // intar 16*16 header 
			codebit0 = intra16x16_type_length;
			codelength0 = intra16x16_ue_length;
		end
		else if(cnt==1'b1)begin
			codebit0 = chroma_length; // intar 16*16 chroma header
			codelength0 = chroma_ue_length;
		end
		else begin // delte qp
			codebit0 = delta_qp_codebit;
			codelength0 = delta_qp_length;
		end
	end	
	else begin //default values
        codebit0 = 0;
		codelength0 = 0;
	end	
end

//every partition of macroblock header encoding  over flag
always @(*) begin
	if(state == E_INTRA4x4)
		if(cnt==5'd19)
			done = 1'b1;
		else
			done = 1'b0;	
	else if(state == E_INTRA16x16) 
		if(cnt==2'd2)		
			done = 1'b1;
		else
			done = 1'b0;
	else
		done = scan_en;	
end

endmodule
