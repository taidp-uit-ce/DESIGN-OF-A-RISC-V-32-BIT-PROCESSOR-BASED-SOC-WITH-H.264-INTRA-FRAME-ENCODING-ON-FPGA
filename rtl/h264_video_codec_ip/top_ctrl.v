`include "enc_defines.v"
module top_ctrl(
				clk,
				rst_n,
				sys_x_total,
				sys_y_total,
				sys_start,
				sys_done,						
				frame_start_o,	
				frame_done_o,
				load_done_i,		
				intra_done_i,	
				ec_done_i,
				bs_empty_i, 		
				load_start_o,	
				intra_start_o,					
				ec_start_o,
				mb_x_load,
				mb_y_load,
				mb_x_intra,
				mb_y_intra,
				mb_x_ec,
				mb_y_ec			
);

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ******************************************** 
parameter	IDLE  = 3'b000,
			INIT  = 3'b001,
			LOAD  = 3'b010,
			I_S0  = 3'b011,
			I_S1  = 3'b100,
			I_S2  = 3'b101,
			I_S3  = 3'b110,
			STORE = 3'b111;							
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input          				clk , rst_n ;
// sys config IF
input						sys_start;     
output						sys_done;		                			
input [`PIC_W_MB_LEN-1:0] 	sys_x_total;    
input [`PIC_H_MB_LEN-1:0]  	sys_y_total;	
// module control IF
input        				load_done_i;     		// load cur_mb done
input        				intra_done_i;    		// intra done
input        				ec_done_i;       		// entropy coding done
input						bs_empty_i;				// bs buf empty
output       				load_start_o;      		// start load cur_mb 
output       				intra_start_o;     		// start intra
output       				ec_start_o;        		// start entropy coding
output       				frame_start_o;	  		// start fetch reference frame
output       				frame_done_o;			// frame coding done
output [`PIC_W_MB_LEN-1:0] 	mb_x_load;				// current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_load;              // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_intra;             // current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_intra;             // current coding MB index
output [`PIC_W_MB_LEN-1:0] 	mb_x_ec;             	// current coding MB index
output [`PIC_H_MB_LEN-1:0] 	mb_y_ec;             	// current coding MB index

// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
// fsm reg
reg    [2:0]  curr_state, curr_state_r; 
reg			  sys_done;

// module done register
reg           load_done_r   ,   intra_done_r   , ec_done_r   , 
              load_done_flag,   intra_done_flag, ec_done_flag,             
              load_start    ,   intra_start    , ec_start    , frame_start, frame_done;             
reg  [7:0]    mb_x_load     ,   mb_x_intra     , mb_x_ec     ,           
              mb_y_load     ,   mb_y_intra     , mb_y_ec     ;
reg           mb_done_flag_r;
              
// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
reg    [2:0] next_state;
reg		     load_working, intra_working  , ec_working;
reg          mb_done_flag;

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************           
//always @(posedge clk or negedge rst_n)begin //taidao commented 07/5
//	if (!rst_n) 
//		sys_done <= 1'b1;
//	else if (sys_start)
//		sys_done <= 1'b0;
//	else if (curr_state==IDLE && curr_state_r!=IDLE)
//		sys_done <= 1'b1;
//end

//taidao begin 07/5
always @(posedge clk or negedge rst_n)begin
	if (!rst_n) 
		sys_done <= 1'b0;
	else if (curr_state==IDLE && curr_state_r!=IDLE)
		sys_done <= 1'b1;
    else if(sys_start)
        sys_done <= 1'b0;
end
//taidao end
assign load_start_o  = load_start   ; 
assign intra_start_o = intra_start  ;
assign ec_start_o    = ec_start     ;
assign frame_start_o = frame_start  ;
assign frame_done_o  = frame_done   ;

//--------------------------------------------------------------
//               module status update
//--------------------------------------------------------------
// module_done_flag
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		load_done_r            <= 1'b0;
		intra_done_r           <= 1'b0; 		
		ec_done_r              <= 1'b0;		
	end	else begin
	    load_done_r            <= load_done_i          ; 
	    intra_done_r           <= intra_done_i         ; 
	    ec_done_r              <= ec_done_i            ;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_done_flag <= 1'b0;
	else if (load_done_i && ~load_done_r)
	    load_done_flag <= 1'b1;
	else if (mb_done_flag)
		load_done_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		intra_done_flag <= 1'b0;
	else if (intra_done_i && ~intra_done_r)
	    intra_done_flag <= 1'b1;
	else if (mb_done_flag)
		intra_done_flag <= 1'b0;
end	

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ec_done_flag <= 1'b0;
	else if (ec_done_i && ~ec_done_r)
	    ec_done_flag <= 1'b1;
	else if (mb_done_flag)
		ec_done_flag <= 1'b0;
end	

//--------------------------------------------------------------
//               finite state machine                           
//--------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		curr_state   <= IDLE ;
		curr_state_r <= IDLE;
    end
	else begin 
		curr_state   <= next_state ;
		curr_state_r <= curr_state;
    end
end

always @(*)begin
	case(curr_state)
		 IDLE: begin
		 			 if(sys_start) begin
		 				 next_state = INIT  ;
		 				 mb_done_flag = 1'b0;
		 			 end	 
		 			 else begin
		 				 next_state = IDLE ;
		 				 mb_done_flag = 1'b0;
		 		     end
		 	   end
		 INIT: begin
		 			 next_state = LOAD;
		 			 mb_done_flag = 1'b0;
		 	   end
		 LOAD : begin
		 			 if(load_done_flag) begin
		 			     next_state =  I_S0;
		 			     mb_done_flag = 1'b1;
		 			 end
		 			 else begin
		 			 	 next_state = LOAD ;
		 			 	 mb_done_flag = 1'b0;
		 			 end
		       end
		 I_S0: begin
		 			 if(load_done_flag && intra_done_flag) begin
		 			     next_state = I_S1 ;
		 			     mb_done_flag = 1'b1;
		 			 end
		 			 else begin
		 			 	 next_state = I_S0 ;
		 			 	 mb_done_flag = 1'b0;
		 			 end
		 	   end 
		 I_S1: begin
		             if (load_done_flag && intra_done_flag && ec_done_flag) begin
		                  mb_done_flag = 1'b1;
		                  if ((mb_x_load == sys_x_total) && (mb_y_load == sys_y_total)) 
		                      next_state = I_S2;
		                  else 
		                      next_state = I_S1;
		             end
		             else begin
		                  next_state = I_S1;
		                  mb_done_flag = 1'b0;
		             end
		       end
		 I_S2: begin
		 	         if(intra_done_flag && ec_done_flag) begin
		 	             next_state = I_S3  ;
		 	             mb_done_flag = 1'b1;
		 	         end
		 	         else begin
		 	             next_state = I_S2 ;
		 	             mb_done_flag = 1'b0;
		 	         end
		       end 
		 I_S3: begin
		 	         if(ec_done_flag) begin
		 	             next_state = STORE ;
		 	             mb_done_flag = 1'b1;
		 	         end
		 	         else begin
		 	             next_state = I_S3 ;
		 	             mb_done_flag = 1'b0;
		 	         end
		       end
		 STORE: begin //wait for store complete (not needed any more, since fetch_db_done_flag is done in DB)
		 	      if (bs_empty_i) begin			 	       
		 	       	next_state = IDLE;
		 	       	mb_done_flag = 1'b0;
		 	      end
		 	      else begin
		 	      	next_state = STORE  ;
		 	      	mb_done_flag = 1'b0;
		 	      end
		       end
		 default:begin
		 	       next_state = IDLE ;
		 	       mb_done_flag = 1'b0;
		       end 
	endcase
end

//--------------------------------------------------------------
//               output control signals                           
//--------------------------------------------------------------
// module start 
always @(*)begin
	case(curr_state)
			 IDLE: { load_working, intra_working, ec_working} <= 3'b000;
			 INIT: { load_working, intra_working, ec_working} <= 3'b000;
			 LOAD: { load_working, intra_working, ec_working} <= 3'b100;
			 I_S0: { load_working, intra_working, ec_working} <= 3'b110;
			 I_S1: { load_working, intra_working, ec_working} <= 3'b111;
			 I_S2: { load_working, intra_working, ec_working} <= 3'b011;		       
			 I_S3: { load_working, intra_working, ec_working} <= 3'b001;
			 STORE:{ load_working, intra_working, ec_working} <= 3'b000; 
		  default: { load_working, intra_working, ec_working} <= 3'b000;
   endcase
end 

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
        mb_done_flag_r <= 'b0;
    else 
        mb_done_flag_r <= mb_done_flag;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_start <= 1'b0;
	else if(mb_done_flag_r || frame_start)
		load_start <= load_working;
	else
		load_start <= 1'b0;	
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		intra_start <= 1'b0;
	else if(mb_done_flag_r)
		intra_start <= intra_working;
	else
		intra_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ec_start <= 1'b0;
	else if(mb_done_flag_r)
		ec_start <= ec_working;
	else
		ec_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_start <= 1'b0;
	else if(curr_state_r==INIT)
		frame_start <= 1'b1;
	else
		frame_start <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_done <= 1'b0;
	else if((next_state==STORE) &&(curr_state!=STORE))
		frame_done <= 1'b1;
	else
		frame_done <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_load <= 'b0;
		mb_y_load <= 'b0;
	end
	else if(curr_state == INIT)begin
		mb_x_load <= 'b0;
		mb_y_load <= 'b0;
	end
	else if(load_done_flag && mb_done_flag)begin
		if(mb_x_load == sys_x_total)begin
			mb_x_load <= 'b0;
			if (mb_y_load == sys_y_total)
			      mb_y_load <= 'b0;
			else 
			      mb_y_load <= mb_y_load + 1'b1;
		end
		else begin
			mb_x_load <= mb_x_load + 1'b1;
			mb_y_load <= mb_y_load;
		end
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_intra <= 'b0;
		mb_y_intra <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_intra <= 'b0;
		mb_y_intra <= 'b0;
	end
	else if(intra_done_flag && mb_done_flag)begin
		mb_x_intra <= mb_x_load;
		mb_y_intra <= mb_y_load;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mb_x_ec <= 'b0;
		mb_y_ec <= 'b0;
	end
	else if(curr_state==INIT)begin
		mb_x_ec <= 'b0;
		mb_y_ec <= 'b0;
	end
	else if(ec_done_flag && mb_done_flag)begin
        mb_x_ec <= mb_x_intra;
		mb_y_ec <= mb_y_intra;
	end
end

endmodule
