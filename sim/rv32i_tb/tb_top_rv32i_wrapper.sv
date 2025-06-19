`timescale 1ns / 1ps
import axi_vip_pkg::*;
import rv32i_test_axi_vip_0_0_pkg::*;
import rv32i_test_axi_vip_1_0_pkg::*;
/*
XilinxAXIVIP: Found at Path: tb_m_axi4lite_vip.DUT.rv32i_test_i.axi_vip_0.inst
XilinxAXIVIP: Found at Path: tb_m_axi4lite_vip.DUT.rv32i_test_i.axi_vip_1.inst
*/
module tb_top_rv32i_wrapper();
    //<component_name>: rv32i_test_axi_vip_0_0
    //XilinxAXIVIP: Found at Path: tb_m_axi4lite_vip.DUT.top_rv32i_i.axi_vip_0.inst
    bit clk, rst_n;

    always #5 clk = ~clk;
    
    initial begin
        rst_n = 1'b0;
        repeat (10) @(negedge clk);
        rst_n = 1'b1;
    end
    //dut
    rv32i_test_wrapper DUT(.clk_100MHz(clk), .reset(!rst_n));
  /*************************************************************************************************
  * Declare <component_name>_slv_mem_t for slave mem agent
  * <component_name> can be easily found in vivado bd design: click on the instance, 
  * then click CONFIG under Properties window and Component_Name will be shown
  * more details please refer PG267 for more details
  *************************************************************************************************/  
    rv32i_test_axi_vip_0_0_slv_mem_t    slv_agent;
    rv32i_test_axi_vip_1_0_mst_t        mst_agent;
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
            slv_start_stimulus();
        join;
    end

    task mst_start_stimulus();
        mst_agent = new("master vip agent", DUT.rv32i_test_i.axi_vip_1.inst.IF);
        mst_agent.start_master();               // mst_agent start to run
        RV32I_RESET();
//        RV32I_37INST_TEST();
        RV32I_MMIO_ACCESS_TEST();
        RV32I_START();
        #10000
        RV32I_STOP();
        RV32I_INIT_CHECK();
        RV32I_START();
        #10000
        RV32I_STOP();
        read_dmem(31'd100, 31'd224);                             
        RV32I_CHECK_DONE(); 
        #10000;
        $finish;
    endtask
    task RV32I_RESET();
        write_trans(.addr(32'b0), .data(32'b1));
        mst_agent.wait_drivers_idle();
        write_trans(.addr(32'b0), .data(32'b0));
        mst_agent.wait_drivers_idle();
    endtask
    task RV32I_CHECK_DONE();
//        read_pc();
    endtask
    task RV32I_MMIO_ACCESS_TEST();
        // Load immediate values
        write_imem(0,  32'h00300093);  // addi x1, x0, 3
        write_imem(4,  32'haaaab137);  // lui x2, 0xaaaab
        write_imem(8,  32'haaa10113);  // addi x2, x2, -1366
        write_imem(12, 32'hbbbbc1b7);  // lui x3, 0xbbbbc
        write_imem(16, 32'hbbb18193);  // addi x3, x3, -1109
        write_imem(20, 32'hccccd237);  // lui x4, 0xccccd
        write_imem(24, 32'hccc20213);  // addi x4, x4, -852
        write_imem(28, 32'h400002b7);  // lui x5, 0x40000
        
        // Store operations to MMIO
        write_imem(32, 32'h0022a023);  // sw x2, 0(x5)
        write_imem(36, 32'h00329123);  // sh x3, 2(x5)
        write_imem(40, 32'h004280a3);  // sb x4, 1(x5)
        
        // Load operations from MMIO
        write_imem(44, 32'h0002a303);  // lw x6, 0(x5)
        write_imem(48, 32'h00029383);  // lh x7, 0(x5)
        write_imem(52, 32'h0022d403);  // lhu x8, 2(x5)
        write_imem(56, 32'h00328483);  // lb x9, 3(x5)
        write_imem(60, 32'h0012c503);  // lbu x10, 1(x5)
    endtask
    
    task RV32I_37INST_TEST();
        write_imem(0, 32'h00300013);    //addi x0, x0, 3
        write_imem(4, 32'h00300093);    //addi x1, x0, 3
        write_imem(8, 32'h00108113);    //addi x2, x1, 1
        write_imem(12, 32'h002081b3);   //add x3, x1, x2
        write_imem(16, 32'h402081b3);   //sub x3, x1, x2
        write_imem(20, 32'h0020c233);   //xor x4, x1, x2
        write_imem(24, 32'h0020e2b3);   //or x5, x1, x2
        write_imem(28, 32'h0020f333);   //and x6, x1, x2
        write_imem(32, 32'h00100393);   //addi x7, x0, 1
        write_imem(36, 32'h007393b3);   //sll x7, x7, x7
        write_imem(40, 32'h0072d433);   //srl x8, x5, x7
        write_imem(44, 32'hffa48493);   //addi x9, x9, -6
        write_imem(48, 32'h4074d533);   //sra x10, x9, x7
        write_imem(52, 32'h4072d533);   //sra x10, x5, x7
        write_imem(56, 32'h00a4a5b3);   //slt x11, x9, x10
        write_imem(60, 32'h00a4b5b3);   //sltu x11, x9, x10
        write_imem(64, 32'h0055c613);   //xori x12, x11, 5
        write_imem(68, 32'h00766693);   //ori x13, x12, 7
        write_imem(72, 32'h0086f713);   //andi x14, x13, 8
        write_imem(76, 32'h00161793);   //slli x15, x12, 1
        write_imem(80, 32'h0017d813);   //srli x16, x15, 1
        write_imem(84, 32'h4014d893);   //srai x17, x9, 1
        write_imem(88, 32'h40185893);   //srai x17, x16, 1
        write_imem(92, 32'h0028a913);   //slti x18, x17, 2
        write_imem(96, 32'h00f8b993);   //sltiu x19, x17, 15
        write_imem(100, 32'h0fa00713);  //addi x14, x0, 0xfa
        write_imem(104, 32'h00002423);  //sw x0, 8(x0)
        write_imem(108, 32'h00002223);  //sw x0, 4(x0)
        write_imem(112, 32'h00002023);  //sw x0, 0(x0)
        write_imem(116, 32'h00900423);  //sb x9, 8(x0)
        write_imem(120, 32'h00901223);  //sh x9, 4(x0)
        write_imem(124, 32'h00902023);  //sw x9, 0(x0)
        write_imem(128, 32'h00002a03);  //lw x20, 0(x0)
        write_imem(132, 32'h003a0c93);  //addi x25, x20, 3
        write_imem(136, 32'h00402a03);  //lw x20, 4(x0)
        write_imem(140, 32'h00802a03);  //lw x20, 8(x0)
        write_imem(144, 32'h00401a83);  //lh x21, 4(x0)
        write_imem(148, 32'h00405a83);  //lhu x21, 4(x0)
        write_imem(152, 32'h00000b03);  //lb x22, 0(x0)
        write_imem(156, 32'h00004b03);  //lbu x22, 0(x0)
        write_imem(160, 32'h00eb0663);  //beq x22, x14, 12
        write_imem(164, 32'h00000013);  //nop
        write_imem(168, 32'h00000013);  //nop
        write_imem(172, 32'haaaaabb7);  //lui x23, 0xaaaaa
        write_imem(176, 32'haaaaac17);  //auipc x24, 0xaaaaa
        write_imem(180, 32'h01400d6f);  //jal x26, 20
        write_imem(184, 32'h00000013);  //nop
        write_imem(188, 32'h00000013);  //nop
        write_imem(192, 32'h00000013);  //nop
        write_imem(196, 32'h00000013);  //nop
        write_imem(200, 32'h01cd0de7);  //jalr x27, 28(x26)
        write_imem(204, 32'h00000013);  //nop
        write_imem(208, 32'h00000013);  //nop
        write_imem(212, 32'h00b00e13);  //addi x28, x0, 0xb
        write_imem(216, 32'h00804e83);  //lbu x29, 8(x0)
        write_imem(220, 32'h00fefe93);  //andi x29, x29, 0x0f
        write_imem(224, 32'h01de0463);  //beq x28, x29, 8
        write_imem(228, 32'h001e8e93);  //addi x29, x29, 1
        write_imem(232, 32'h01be1663);  //bne x28, x27, 12
        write_imem(236, 32'h01efdc63);  //bge x31, x30, 24
        write_imem(240, 32'hffff4ee3);  //blt x30, x31, -4
        write_imem(244, 32'hfec00f13);  //addi x30, x0, -20
        write_imem(248, 32'hff100f93);  //addi x31, x0, -15
        write_imem(252, 32'hffefe8e3);  //bltu x31, x30, -16
        write_imem(256, 32'hffeff8e3);  //bgeu x31, x30, -16
        write_imem(260, 32'h400002b7);  //lui x5, 0x40000
        write_imem(264, 32'h003b8313);  //addi x6, x23, 3
        write_imem(268, 32'h0172a023);  //sw x23, 0(x5)
        write_imem(272, 32'h0002a383);  //lw x7, 0(x5)
        write_imem(276, 32'h00730663);  //beq x6, x7, 12
        write_imem(280, 32'h00138393);  //addi x7, x7, 1
        write_imem(284, 32'hff9ff46f);  //jal x8, -12
        write_imem(288, 32'h800004b7);  //lui x9, 0x80000
        write_imem(292, 32'hbbbbb537);  //lui x10, 0xbbbbb
        write_imem(296, 32'h00a4a023);  //sw x10, 0(x9)
        write_imem(300, 32'h0004d583);  //lhu x11, 0(x9)
        write_imem(304, 32'h00b5a223);  //sw x11, 4(x11)
        write_imem(308, 32'h00458593);  //addi x11, x11, 4
        write_imem(312, 32'h0005a603);  //lw x12, 0(x11)
        write_imem(316, 32'h0000006f);  //jal x0, 0
    endtask
    
    task RV32I_START();
        write_trans(.addr(32'b100), .data(32'b1));
        mst_agent.wait_drivers_idle();
    endtask
    task RV32I_STOP();
        write_trans(.addr(32'b100), .data(32'b0));
        mst_agent.wait_drivers_idle();
    endtask
    task RV32I_INIT_CHECK();
        begin
            // Store all 32 registers to memory for checking
            write_imem(320, 32'h06002223); // sw x0, 100(x0)
            write_imem(324, 32'h06102423); // sw x1, 104(x0)
            write_imem(328, 32'h06202623); // sw x2, 108(x0)
            write_imem(332, 32'h06302823); // sw x3, 112(x0)
            write_imem(336, 32'h06402a23); // sw x4, 116(x0)
            write_imem(340, 32'h06502c23); // sw x5, 120(x0)
            write_imem(344, 32'h06602e23); // sw x6, 124(x0)
            write_imem(348, 32'h08702023); // sw x7, 128(x0)
            write_imem(352, 32'h08802223); // sw x8, 132(x0)
            write_imem(356, 32'h08902423); // sw x9, 136(x0)
            write_imem(360, 32'h08a02623); // sw x10, 140(x0)
            write_imem(364, 32'h08b02823); // sw x11, 144(x0)
            write_imem(368, 32'h08c02a23); // sw x12, 148(x0)
            write_imem(372, 32'h08d02c23); // sw x13, 152(x0)
            write_imem(376, 32'h08e02e23); // sw x14, 156(x0)
            write_imem(380, 32'h0af02023); // sw x15, 160(x0)
            write_imem(384, 32'h0b002223); // sw x16, 164(x0)
            write_imem(388, 32'h0b102423); // sw x17, 168(x0)
            write_imem(392, 32'h0b202623); // sw x18, 172(x0)
            write_imem(396, 32'h0b302823); // sw x19, 176(x0)
            write_imem(400, 32'h0b402a23); // sw x20, 180(x0)
            write_imem(404, 32'h0b502c23); // sw x21, 184(x0)
            write_imem(408, 32'h0b602e23); // sw x22, 188(x0)
            write_imem(412, 32'h0d702023); // sw x23, 192(x0)
            write_imem(416, 32'h0d802223); // sw x24, 196(x0)
            write_imem(420, 32'h0d902423); // sw x25, 200(x0)
            write_imem(424, 32'h0da02623); // sw x26, 204(x0)
            write_imem(428, 32'h0db02823); // sw x27, 208(x0)
            write_imem(432, 32'h0dc02a23); // sw x28, 212(x0)
            write_imem(436, 32'h0dd02c23); // sw x29, 216(x0)
            write_imem(440, 32'h0de02e23); // sw x30, 220(x0)
            write_imem(444, 32'h0ff02023); // sw x31, 224(x0)
            
            $display("RV32I_INIT_CHECK: Loaded 32 register dump instructions");
            $display("Instructions loaded from address 308 to 432 (32 instructions)");
        end
        
    endtask
    task read_dmem(input bit [31:0] dmem_addr_from, input bit [31:0] dmem_addr_to);
        integer addr;
        for (addr = dmem_addr_from; addr <= dmem_addr_to; addr = addr + 4) begin
            $display("Reading DMEM[0x%08h] (%0d)", addr, addr);
            write_dmem(addr);
        end
    endtask
    task write_imem(input bit [31:0] addr, input bit [31:0] data);
        write_trans(.addr(32'b01100), .data(addr)); //address
        mst_agent.wait_drivers_idle();
        write_trans(.addr(32'b10000), .data(data)); //data
        mst_agent.wait_drivers_idle();
        write_trans(.addr(32'b01000), .data(32'h1)); //imem_we
        mst_agent.wait_drivers_idle();
        write_trans(.addr(32'b01000), .data(32'h0)); //imem_we
        mst_agent.wait_drivers_idle();
    endtask
    task write_dmem(input bit [31:0] addr);
        write_trans(.addr(32'b11000), .data(addr)); //dmem_address
        mst_agent.wait_drivers_idle();
        write_trans(.addr(32'b10100), .data(32'h1)); //dmem_re
        mst_agent.wait_drivers_idle();
        read_trans(.addr(32'b11100)); //dmem_data_address
        mst_agent.wait_drivers_idle();
    endtask

    task read_trans(input bit [31:0] addr = 0);
        mtestRID = $urandom_range(0,(1<<(0)-1));
        mtestRADDR = addr;
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
    task slv_start_stimulus();
        slv_agent = new("slave vip mem agent", DUT.rv32i_test_i.axi_vip_0.inst.IF);
        slv_agent.set_agent_tag("My Slave VIP");
        slv_agent.set_verbosity(400);  
        slv_agent.start_slave();    // agent starts to run
    endtask
    
    task write_trans(input bit [31:0] addr =0, input bit [31:0] data =0);
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
endmodule
