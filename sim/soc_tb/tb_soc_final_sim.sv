`timescale 1ns / 1ps
//component name: soc_final_sim_axi_vip_0_0
import axi_vip_pkg::*;
import soc_final_sim_axi_vip_0_0_pkg::*;
`define DUMP_CHECK;
`define M_AXI_VIP_ENABLE
`define FRAME_TOTAL 3;
//XilinxAXIVIP: Found at Path: tb_soc_final_sim.U_SOC.soc_final_sim_i.axi_vip_0.inst
module tb_soc_final_sim();
    parameter real  CLK_PERIOD = 10;
    parameter       S2MM_PATH     = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\rtl\\test_temp\\axis_bsdump.txt";
    parameter       CHECK_FILE    = "D:\\Workspaces\\RTL\\KLTN_sourcecode\\sw\\testcases\\old\\test_416x240_100f_qp28\\3frames\\bs_check.dat";

    reg clk, rst_n;
    wire [63:0] tdata_o         ;
    wire        tvalid_o        ;
    wire        tlast_o         ;
    wire [ 7:0] tkeep_o         ;
//    wire        wready_o        ;
    reg         tready_i        ;
    
    initial begin    
        clk      = 0;
        tready_i = 1;
        forever #(CLK_PERIOD) clk = !clk;
    end
    initial begin
        rst_n = 0;
        repeat (5) @(negedge clk);
        rst_n = 1;
    end
    soc_final_sim_wrapper U_SOC(   .clk_100MHz        (clk),
                            .reset              (!rst_n),
                            .M01_AXIS_0_tdata   (tdata_o),
                            .M01_AXIS_0_tlast   (tlast_o),
                            .M01_AXIS_0_tready  (tready_i),
                            .M01_AXIS_0_tkeep   (tkeep_o),
                            .M01_AXIS_0_tvalid  (tvalid_o)
                         );
`ifdef M_AXI_VIP_ENABLE
    /*************************************************************************************************
  * Declare <component_name>_slv_mem_t for slave mem agent
  * <component_name> can be easily found in vivado bd design: click on the instance, 
  * then click CONFIG under Properties window and Component_Name will be shown
  * more details please refer PG267 for more details
  *************************************************************************************************/  
    soc_final_sim_axi_vip_0_0_mst_t        mst_agent;
    /*************************************************************************************************
    * Declare variables which will be used in API and parital randomization for transaction generation
    * and data read back from driver.
    *************************************************************************************************/
    axi_transaction                                          wr_trans;            // Write transaction
    axi_transaction                                          rd_trans;            // Read transaction
    xil_axi_uint                                             mtestWID;            // Write ID  
    xil_axi_ulong                                            mtestWADDR;          // Write ADDR  
    xil_axi_len_t                                            mtestWBurstLength;   // Write Burst Length   
    xil_axi_size_t                                           mtestWDataSize;      // Write SIZE  
    xil_axi_burst_t                                          mtestWBurstType;     // Write Burst Type  
    xil_axi_uint                                             mtestRID;            // Read ID  
    xil_axi_ulong                                            mtestRADDR;          // Read ADDR  
    xil_axi_len_t                                            mtestRBurstLength;   // Read Burst Length   
    xil_axi_size_t                                           mtestRDataSize;      // Read SIZE  
    xil_axi_burst_t                                          mtestRBurstType;     // Read Burst Type  
    
    xil_axi_data_beat [255:0]                                mtestWUSER;         // Write user  
    xil_axi_data_beat                                        mtestAWUSER;        // Write Awuser 
    xil_axi_data_beat                                        mtestARUSER;        // Read Aruser
    
    // Error count to check how many comparison failed
    xil_axi_uint                                            error_cnt = 0;
    
    /************************************************************************************************
    * No burst for AXI4LITE and maximum data bits is 64
    * Write Data Value for WRITE_BURST transaction
    * Read Data Value for READ_BURST transaction
    ************************************************************************************************/
    bit [63:0]                                               mtestWData;         // Write Data
    bit[8*4096-1:0]                                          Rdatablock;        // Read data block
    xil_axi_data_beat                                        Rdatabeat[];       // Read data beats
    bit[8*4096-1:0]                                          Wdatablock;        // Write data block
    xil_axi_data_beat                                        Wdatabeat[];       // Write data beats
    initial begin
        wait (rst_n);
        fork
            mst_start_stimulus();
//            slv_start_stimulus();
        join;
    end

    task mst_start_stimulus();
        mst_agent = new("master vip agent", U_SOC.soc_final_sim_i.axi_vip_0.inst.IF);
        mst_agent.start_master();               // mst_agent start to run
        RV32I_RESET();
        RV32I_INIT_PROGRAM();
        RV32I_INIT_CHECK();
        RV32I_START();                             
        RV32I_CHECK_DONE(); 
//        #10000;
//        $finish;
    endtask
    task RV32I_RESET();
        write_imem(.addr(32'b0), .data(32'b1));
        mst_agent.wait_drivers_idle();
        write_imem(.addr(32'b0), .data(32'b0));
        mst_agent.wait_drivers_idle();
    endtask
    task RV32I_CHECK_DONE();
//        read_pc();
    endtask
    
    task RV32I_INIT_PROGRAM();
        write_inst(0, 32'h00100093);    // addi x1, x0, 0x1
        write_inst(4, 32'h00300113);    // addi x2, x0, 0x3
        write_inst(8, 32'h01c00193);    // addi x3, x0, 0x1c
        write_inst(12, 32'h1a000213);   // addi x4, x0, 0x1a0
        write_inst(16, 32'h0f000293);   // addi x5, x0, 0xf0
        
        write_inst(20, 32'h40000337);   // lui x6, 0x40000
        write_inst(24, 32'h600003b7);   // lui x7, 0x60000
        write_inst(28, 32'h80000437);   // lui x8, 0x80000
        write_inst(32, 32'h800014b7);   // lui x9, 0x80001
        write_inst(36, 32'h00025537);   // lui x10, 0x25
        write_inst(40, 32'h90050513);   // addi x10, x10, -0x700
        
        write_inst(44, 32'h00342223);   // sw x3, 0x4(x8)
        write_inst(48, 32'h00442423);   // sw x4, 0x8(x8)
        write_inst(52, 32'h00542623);   // sw x5, 0xc(x8)
        
        write_inst(56, 32'h000006b3);   // add x13, x0, x0
        
        write_inst(60, 32'h0014a023);   // sw x1, 0x0(x9)
        write_inst(64, 32'h0214a823);   // sw x1, 0x30(x9)
        
        write_inst(68, 32'h0064ac23);   // sw x6, 0x18(x9)
        write_inst(72, 32'h02a4a423);   // sw x10, 0x28(x9)
        write_inst(76, 32'h0474a423);   // sw x7, 0x48(x9)
        write_inst(80, 32'h04a4ac23);   // sw x10, 0x58(x9)
        
        write_inst(84, 32'h00142023);   // sw x1, 0x0(x8)
        
        write_inst(88, 32'h00042703);   // lw x14, 0x0(x8)
        write_inst(92, 32'h00277713);   // andi x14, x14, 0x2
        write_inst(96, 32'hfe070ce3);   // beq x14, x0, -0x8
        
        write_inst(100, 32'h0044a783);  // lw x15, 0x4(x9)
        write_inst(104, 32'h0027f793);  // andi x15, x15, 0x2
        write_inst(108, 32'hfe078ce3);  // beq x15, x0, -0x8
        
        write_inst(112, 32'h0344a803);  // lw x16, 0x34(x9)
        write_inst(116, 32'h00287813);  // andi x16, x16, 0x2
        write_inst(120, 32'hfe080ce3);  // beq x16, x0, -0x8
        
        write_inst(124, 32'h0584a883);  // lw x17, 0x58(x9)
        
        write_inst(128, 32'h00a30333);  // add x6, x6, x10
        write_inst(132, 32'h011383b3);  // add x7, x7, x17
        
        write_inst(136, 32'h00000713);  // addi x14, x0, 0x0
        write_inst(140, 32'h00000793);  // addi x15, x0, 0x0
        write_inst(144, 32'h00000813);  // addi x16, x0, 0x0
        write_inst(148, 32'h00000893);  // addi x17, x0, 0x0
        
        write_inst(152, 32'h00168693);  // addi x13, x13, 0x1
        write_inst(156, 32'hfa26c4e3);  // blt x13, x2, -88
        write_inst(160, 32'h0000006f);  // jal x0, 0x0
    endtask
    
    task write_inst(input bit [31:0] addr, input bit [31:0] data);
        write_imem(.addr(32'b01100), .data(addr)); //address
        mst_agent.wait_drivers_idle();
        write_imem(.addr(32'b10000), .data(data)); //data
        mst_agent.wait_drivers_idle();
        write_imem(.addr(32'b01000), .data(32'h1)); //imem_we
        mst_agent.wait_drivers_idle();
        write_imem(.addr(32'b01000), .data(32'h0)); //imem_we
        mst_agent.wait_drivers_idle();
    endtask
    
    task RV32I_START();
        write_imem(.addr(32'b100), .data(32'b1));
        mst_agent.wait_drivers_idle();
    endtask
    task RV32I_INIT_CHECK();
        
    endtask
//    task slv_start_stimulus();
//        slv_agent = new("slave vip mem agent", DUT.rv32i_test_i.axi_vip_0.inst.IF);
//        slv_agent.set_agent_tag("My Slave VIP");
//        slv_agent.set_verbosity(400);  
//        slv_agent.start_slave();    // agent starts to run
//    endtask
    
    task write_imem(input bit [31:0] addr =0, input bit [31:0] data =0);
        mtestWID = $urandom_range(0,(1<<(0)-1)); 
        mtestWADDR = addr;
        mtestWBurstLength = 0;
        mtestWDataSize = xil_axi_size_t'(xil_clog2((32)/8));
        mtestWBurstType = XIL_AXI_BURST_TYPE_INCR;
        mtestWData = data;
        //single write transaction filled in user inputs through API 
        single_write_transaction_api("single write with api",
                                     .id(mtestWID),
                                     .addr(mtestWADDR),
                                     .len(mtestWBurstLength), 
                                     .size(mtestWDataSize),
                                     .burst(mtestWBurstType),
                                     .wuser(mtestWUSER),
                                     .awuser(mtestAWUSER), 
                                     .data(mtestWData)
                                     );
    endtask
    task automatic single_write_transaction_api ( 
                                input string                     name ="single_write",
                                input xil_axi_uint               id =0, 
                                input xil_axi_ulong              addr =0,
                                input xil_axi_len_t              len =0, 
                                input xil_axi_size_t             size =xil_axi_size_t'(xil_clog2((32)/8)),
                                input xil_axi_burst_t            burst =XIL_AXI_BURST_TYPE_INCR,
                                input xil_axi_lock_t             lock = XIL_AXI_ALOCK_NOLOCK,
                                input xil_axi_cache_t            cache =0,
                                input xil_axi_prot_t             prot =0,
                                input xil_axi_region_t           region =0,
                                input xil_axi_qos_t              qos =0,
                                input xil_axi_data_beat [255:0]  wuser =0, 
                                input xil_axi_data_beat          awuser =0,
                                input bit [63:0]                 data =0
                                                );
        axi_transaction wr_trans;
        wr_trans = mst_agent.wr_driver.create_transaction(name);
        wr_trans.set_write_cmd(addr,burst,id,len,size);
        wr_trans.set_prot(prot);
        wr_trans.set_lock(lock);
        wr_trans.set_cache(cache);
        wr_trans.set_region(region);
        wr_trans.set_qos(qos);
        wr_trans.set_data_block(data);
        wr_trans.set_strb_array(); //Sets all strobe bits of the transaction to 1
        mst_agent.wr_driver.send(wr_trans);   
    endtask  : single_write_transaction_api
    task read_pc(output bit [31:0] pc_value);
        mtestRID = $urandom_range(0,(1<<(0)-1));
        mtestRADDR = $urandom_range(0,(1<<(32)-1));
        mtestRBurstLength = 0;
        mtestRDataSize = xil_axi_size_t'(xil_clog2((32)/8)); 
        mtestRBurstType = XIL_AXI_BURST_TYPE_INCR;
        //single read transaction filled in user inputs through API 
        single_read_transaction_api("single read with api",
                                     .id(mtestRID),
                                     .addr(mtestRADDR),
                                     .len(mtestRBurstLength), 
                                     .size(mtestRDataSize),
                                     .burst(mtestRBurstType)
                                     );
    endtask
    task automatic single_read_transaction_api ( 
                                    input string                     name ="single_read",
                                    input xil_axi_uint               id =0, 
                                    input xil_axi_ulong              addr =0,
                                    input xil_axi_len_t              len =0, 
                                    input xil_axi_size_t             size =xil_axi_size_t'(xil_clog2((32)/8)),
                                    input xil_axi_burst_t            burst =XIL_AXI_BURST_TYPE_INCR,
                                    input xil_axi_lock_t             lock =XIL_AXI_ALOCK_NOLOCK ,
                                    input xil_axi_cache_t            cache =0,
                                    input xil_axi_prot_t             prot =0,
                                    input xil_axi_region_t           region =0,
                                    input xil_axi_qos_t              qos =0,
                                    input xil_axi_data_beat          aruser =0
                                                );
        axi_transaction                               rd_trans;
        rd_trans = mst_agent.rd_driver.create_transaction(name);
        rd_trans.set_read_cmd(addr,burst,id,len,size);
        rd_trans.set_prot(prot);
        rd_trans.set_lock(lock);
        rd_trans.set_cache(cache);
        rd_trans.set_region(region);
        rd_trans.set_qos(qos);
        mst_agent.rd_driver.send(rd_trans);   
    endtask  : single_read_transaction_api
`endif
    
    // -------------------------------------------------------
    //                  DUMP S2MM STREAM
    // -------------------------------------------------------
`ifdef DUMP_CHECK
    integer out_file, fp_check;
    integer i;
    reg [7:0]   check_data;
    reg [7:0]   frame_count;
    initial begin
        frame_count = 0;
        out_file = $fopen(S2MM_PATH, "w");
        fp_check = $fopen(CHECK_FILE, "r");
        if (out_file == 0) begin
            $display("ERROR: Failed to open %s", S2MM_PATH);
            $finish;
        end
        else
            $display("Open %s file successfully!", S2MM_PATH);
        if (fp_check == 0) begin
            $display("ERROR: Failed to open %s file!", CHECK_FILE);
            $finish;
        end
        else
            $display("Open %s file successfully!", CHECK_FILE);
    end
    
    initial begin
        wait(frame_count ==3)
         #1000 $finish;
    end
    
    always @(posedge clk) begin
        if (tvalid_o && tready_i) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (tkeep_o[i]) begin
                    $fwrite(out_file, "%02x\n", tdata_o[8*i +: 8]);
                    //byte check
                    $fscanf(fp_check, "%h", check_data);
                    if (check_data !== tdata_o[8*i +: 8]) begin
            			$display("ERROR: check_data(%h) != bs_data(%h)", check_data, tdata_o[8*i +: 8]);
            			#1000 $finish;
                    end
                    else begin
                        $display("MATCHED: check_data(%h) == bs_data(%h)", check_data, tdata_o[8*i +: 8]);
                    end
                    //
                end
            end
            if (tlast_o) begin
                $display("FRAME %d DONE!", frame_count);
                frame_count = frame_count + 1;
            end
        end
    end
`endif
endmodule
