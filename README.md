# DESIGN-OF-A-RISC-V-32-BIT-PROCESSOR-BASED-SOC-WITH-H.264-INTRA-FRAME-ENCODING-ON-FPGA
Thesis Summary

## Overview
Custom 5-stage pipelined RISC-V RV32I processor
  - Support all 37 instructions
  - AXI-Lite Interface to access peripheral via MMIO Interface.
H.264 Intra Frame Encoder IP (open-source based)
  - Integrated H.264 Core to the system.
  - Create AXI-Lite (slave) interface to receive command from RV32I CPU.
  - Create AXI-Stream (slave) & AXI-Stream (master) to transfer/receive video data from DMA IP.
  - Resolve CDC problem when the IP work at different clock domain.


For more details, refer to the full thesis and associated simulation/test files.

Authors: Dao Phuoc Tai, Nguyen Anh Khoi
Advisor: Mr. Ngo Hieu Truong
University of Information Technology – VNU HCM
Academic Year: 2025
