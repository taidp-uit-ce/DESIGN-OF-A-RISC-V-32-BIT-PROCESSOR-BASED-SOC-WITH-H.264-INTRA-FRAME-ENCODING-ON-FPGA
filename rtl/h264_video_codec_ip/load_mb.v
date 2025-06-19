`include "enc_defines.v"
module load_mb   (
				clk,
				rst_n,
				load_start,	
				load_done,
				pvalid_i,			
				pready_o,
				pdata_i,	
				mb_switch,		
				cur_y_o,
				cur_u_o,
				cur_v_o
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input	        clk ;
input	        rst_n  ;
// raw pixel input                
input           load_start;	       // start load new mb from outside
output          load_done;         // load done
input           pvalid_i;		   // pixel valid for input
output          pready_o;            // read next pixel
input [8*`BIT_DEPTH - 1:0]   pdata_i; // pixel data : 4 pixel input parallel
// from top control        
input           mb_switch;		   // start current_mb pipeline	
output [256*8-1 : 0] cur_y_o;  // outout luma 16x16 for mc
output [64*8-1 : 0] cur_u_o;      // output chroma 8x8 for mc and intra 
output [64*8-1 : 0] cur_v_o;      // output chroma 8x8 for mc and intra

// ********************************************
//                                             
//    Parameter DECLARATION                     
//                                             
// ********************************************


// ********************************************
//                                             
//    Register DECLARATION                         
//                                             
// ********************************************
reg [7:0] cur_y[0:255];
reg [7:0] cur_y_buffer[0:255];

reg [7:0] cur_u[0:63];
reg [7:0] cur_u_buffer[0:63];

reg [7:0] cur_v[0:63];
reg [7:0] cur_v_buffer[0:63];

reg         pready_o ;
reg         load_done;
reg [5:0]   addr_p, addr_p_r; //taidao add addr_p_r to process load_done signal

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
reg [256*8-1 : 0] cur_y_o;
reg [64*8-1 : 0]  cur_u_o;
reg [64*8-1 : 0]  cur_v_o;
wire [4:0] 		  addr_y;
wire [3:0] 		  addr_uv;
wire              p_en;

genvar j; 
generate
  for(j=0;j<256; j=j+1) begin:j_n 
  	always @( * ) begin
			cur_y_o [(j+1)*8-1:j*8] = cur_y_buffer[j];   
    end
	end
endgenerate

genvar k; 
generate 
  for(k=0;k<64; k=k+1) begin:k_n
  	always @( * ) begin
    	cur_u_o [(k+1)*8-1:k*8] = cur_u_buffer[k];
        cur_v_o [(k+1)*8-1:k*8] = cur_v_buffer[k];   
    end
  end
endgenerate

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
assign p_en = pvalid_i && pready_o;

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		load_done <= 1'b0;
	else if((addr_p == 6'd47) && (addr_p_r != 6'd47) && p_en) //taidao 08/5: byte_count check deleted & add p_en
		load_done <= 1'b1;
	else
		load_done <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pready_o <= 1'b0;
	else if(addr_p == 6'd47 && p_en) //taidao 08/5 add p_en
		pready_o <= 1'b0;	
	else if(load_start)
		pready_o <= 1'b1;
    else
        pready_o <= pready_o;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		addr_p        <= 'b0;
	else if((addr_p == 6'd47) && p_en) //taidao 08/5 add p_en
		addr_p        <= 'b0;
	else if(p_en)
		addr_p        <= addr_p + 1'b1;
    else
        addr_p        <= addr_p;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
		addr_p_r  <= 'b0;
    else if ((addr_p == 6'd47) && !p_en)
        addr_p_r  <= addr_p_r;
    else
        addr_p_r  <= addr_p;
end

assign addr_y = addr_p[4:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:cur_luma
	 integer i;
        for(i=0; i<256; i=i+1) begin
             cur_y[i] <= 0;
        end
    end              
	else if(p_en && ~addr_p[5])
		{cur_y[{addr_y,3'b000}],cur_y[{addr_y, 3'b001}],cur_y[{addr_y, 3'b010}],cur_y[{addr_y, 3'b011}],
		 cur_y[{addr_y,3'b100}],cur_y[{addr_y, 3'b101}],cur_y[{addr_y, 3'b110}],cur_y[{addr_y, 3'b111}]}<= pdata_i;
end

assign addr_uv = addr_y[3:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:cur_uv
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_u[i] <= 0;
             cur_v[i] <= 0;
        end
    end 
	else if(p_en && addr_p[5])begin
		{cur_u[{addr_uv, 2'b00}],cur_v[{addr_uv, 2'b00}],cur_u[{addr_uv, 2'b01}],cur_v[{addr_uv, 2'b01}],
		 cur_u[{addr_uv, 2'b10}],cur_v[{addr_uv, 2'b10}],cur_u[{addr_uv, 2'b11}],cur_v[{addr_uv, 2'b11}]} <= pdata_i;
	end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:y_s2
	 integer i;
        for(i=0; i<256; i=i+1) begin
             cur_y_buffer[i] <= 0;
        end
    end
	else if(mb_switch)begin:y_s2_2
	integer i;
		for(i=0; i<256; i=i+1)begin
			cur_y_buffer[i] <= cur_y[i];
		end
	end
end
		
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:u_s2
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_u_buffer[i] <= 0;
        end
    end
	else if(mb_switch)begin:u_s2_2
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_u_buffer[i] <= cur_u[i];
		end
	end   
end
 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin:v_s2
	 integer i;
        for(i=0; i<64; i=i+1) begin
             cur_v_buffer[i] <= 0;
        end
    end
	else  if(mb_switch)begin:v_s2_2
	integer i;
		for(i=0; i<64; i=i+1)begin
			cur_v_buffer[i] <= cur_v[i];
		end
	end
end

endmodule
