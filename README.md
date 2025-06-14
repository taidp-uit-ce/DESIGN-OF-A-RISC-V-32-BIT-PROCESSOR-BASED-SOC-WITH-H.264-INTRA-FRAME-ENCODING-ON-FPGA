# DESIGN-OF-A-RISC-V-32-BIT-PROCESSOR-BASED-SOC-WITH-H.264-INTRA-FRAME-ENCODING-ON-FPGA

## Project summary
This thesis presents the design and implementation of a System-on-Chip (SoC) that integrates a custom 32-bit RISC-V RV32I processor and an H.264/AVC Intra-frame video encoder on the Xilinx Virtex-7 VC707 FPGA platform.

The goal is to build a fully RISC-V-controlled system capable of real-time video compression, demonstrating the feasibility of applying open RISC-V architectures in embedded applications with high data processing demands.

## System overview
Custom 5-stage pipelined RISC-V RV32I processor
  - Support all 37 instructions
  - AXI-Lite Interface to access peripheral via MMIO Interface.
  - Stable operation at 100Mhz.
  - Implemented on Xilinx Virtex7-VC707 FPGA.
H.264 Intra Frame Encoder IP (open-source based)
  - Integrated H.264 Core to the system.
  - Create AXI-Lite (slave) interface with internal registers to receive command from RV32I CPU.
  - Create AXI-Stream (slave) & AXI-Stream (master) with asynchronous FIFOs to transfer/receive video data from DMA IP.
  - Resolve CDC problem using 2FF synchronizer, asynchronous FIFO and other synchronous method.
  - Stable operation at 62.5Mhz.
  - Complete functional simulation on Vivado.
  - Capabilty of encoding video FHD @ 30 fps, compress ratio archieve 10.19% at QP=28.
Memory_1GB (just for simulation)
  - Create a memory block emulator (DDR SDRAM).
  - Create AXI-Full (slave) for intergration.
  - Initialize raw video (.yuv file) for simulation.
Xilinx AXI DMA:
  - Config DMA to directed register mode for simulation.
  - Config S2MM, MM2s control/status/length registers.

![System Block Diagram](images/system_arch.png)

## Result && Performance

## Project structure
- /rtl/        - risc-v rv32i cpu, h.264 encoder IP, ...
- /sim/        - testbenches & simulation files
- /scripts/    - python scripts for extract video .yuv file & ethernet transfer.
- /media/      - images for demonstration.

## Author & Supervisor
- Authors: Dao Phuoc Tai, Nguyen Anh Khoi
- Supervisor: Mr. Ngo Hieu Truong - Faculty of Computer Engineering, UIT-VNU.

Academic Year: 2025
