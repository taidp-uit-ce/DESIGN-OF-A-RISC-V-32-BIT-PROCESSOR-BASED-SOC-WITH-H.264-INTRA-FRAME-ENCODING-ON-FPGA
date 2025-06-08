# DESIGN-OF-A-RISC-V-32-BIT-PROCESSOR-BASED-SOC-WITH-H.264-INTRA-FRAME-ENCODING-ON-FPGA
Thesis Summary

This thesis presents the design and implementation of a System-on-Chip (SoC) that integrates a custom 32-bit RISC-V RV32I processor and an H.264/AVC Intra-frame video encoder on the Xilinx Virtex-7 VC707 FPGA platform. The primary goal of the project is to construct a functional SoC capable of performing real-time video compression using the H.264 standard under the control of a lightweight, fully-customized RISC-V CPU.

The processor is designed with a 5-stage pipeline architecture, supporting 37 core instructions from the RV32I instruction set. It incorporates hazard resolution mechanisms and an AXI-Lite interface for communication with external peripherals. The AXI-Lite master interface enables the processor to configure and control the H.264 encoder and DMA controller using standard load/store instructions.

The H.264 encoder, based on an open-source intra-frame encoding core, was adapted and integrated with a full data loading pipeline, controller logic, and output bitstream handler. The encoder supports 4:2:0 YUV video input with resolutions up to Full HD (1920×1080), and is clocked at 62.5 MHz, while the rest of the SoC runs at 100 MHz. Asynchronous FIFOs and Gray-coded synchronizers are employed to resolve cross-domain clock issues (CDC).

The entire SoC is assembled using Xilinx IP blocks including AXI DMA, AXI SmartConnect, MIG DDR3, and UARTLite, connected via AXI interconnects in Vivado Block Design. The system is validated through simulation and deployed to hardware. Video data is pre-processed using a Python script, loaded into memory, passed through the DMA to the encoder, and the resulting bitstream is written back to memory. The encoded output is compared with reference software outputs and evaluated using PSNR.

Experimental results demonstrate that the RISC-V processor executes all supported instructions correctly on both simulation and FPGA. The H.264 encoder produces valid .264 bitstreams that can be decoded with acceptable visual quality. The system proves feasible for real-time embedded video processing, and opens possibilities for future improvements such as inter-frame prediction, CABAC, or extending the SoC to multi-core configurations.

For more details, refer to the full thesis and associated simulation/test files.

Authors: Dao Phuoc Tai, Nguyen Anh Khoi
Advisor: Mr. Ngo Hieu Truong
University of Information Technology – VNU HCM
Academic Year: 2025
