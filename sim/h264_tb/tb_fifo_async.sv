`timescale 1ns / 1ps
module tb_fifo_async;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;
    wire [DATA_WIDTH-1:0] data_out;
    wire wr_full;
    wire rd_empty;
    reg [DATA_WIDTH-1:0] data_in;
    reg wr_valid_i, wclk, wrst_n;
    reg rd_ready_i, rclk, rrst_n;
    
    // Queue to push data_in
    reg [DATA_WIDTH-1:0] wdata_q[$], wdata;

    fifo_async #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH)) u_fifo_async (
                                                .wr_clk     (wclk),
                                                .wr_rst_n   (wrst_n),
                                                .wr_data_i  (data_in),
                                                .wr_valid_i (wr_valid_i), 
                                                .wr_full_o (wr_full),
                                                .rd_clk     (rclk),
                                                .rd_rst_n   (rrst_n),
                                                .rd_empty_o (rd_empty),  
                                                .rd_ready_i (rd_ready_i),
                                                .rd_valid_o (),
                                                .rd_data_o  (data_out)
                                            );
  always #3ns wclk = ~wclk;
  always #8ns rclk = ~rclk;
  
  initial begin
    wclk = 1'b0; wrst_n = 1'b0;
    wr_valid_i = 1'b0;
    data_in = 0;
    
    repeat(10) @(negedge wclk);
    wrst_n = 1'b1;

    repeat(2) begin
      for (int i=0; i<30; i++) begin
        @(negedge wclk iff !wr_full);
        wr_valid_i = (i%2 == 0)? 1'b1 : 1'b0;
        if (wr_valid_i) begin
          data_in = $urandom;
          wdata_q.push_back(data_in);
        end
      end
      #50;
    end
  end

  initial begin
    rclk = 1'b0; rrst_n = 1'b0;
    rd_ready_i = 1'b0;

    repeat(20) @(negedge rclk);
    rrst_n = 1'b1;

    repeat(2) begin
      for (int i=0; i<30; i++) begin
        @(posedge rclk iff !rd_empty);
        rd_ready_i = (i%2 == 0)? 1'b1 : 1'b0;
        if (rd_ready_i) begin
          wdata = wdata_q.pop_front();
          if(data_out !== wdata) $error("Time = %0t: Comparison Failed: expected wr_data = %h, rd_data = %h", $time, wdata, data_out);
          else $display("Time = %0t: Comparison Passed: wr_data = %h and rd_data = %h",$time, wdata, data_out);
        end
      end
      #50;
    end

    $finish;
  end
  
//  initial begin 
//    $dumpfile("dump.vcd"); $dumpvars;
//  end
endmodule
