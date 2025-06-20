# H.264 Video Encoder IP Overview
<p align="center">
  <img src="images/h264/H264_IP.drawio.png" alt="description" width="600"/>
</p>

# Function Description

## AXI-Lite (slave):
Memory-mapped control registers used by the CPU to configure and trigger the encoder:
- `start`: Start signal for H.264 encoding
- `done`: Asserted when one frame has been encoded
- `qp`: Quantization parameter
- `width`: Frame width (in pixels)
- `height`: Frame height (in pixels)
- 
## AXI-Stream (slave):
- Receives raw video input from AXI DMA (MM2S) via a slave-stream port
- Data is buffered into an asynchronous FIFO

## AXI-Stream (master):
- Sends compressed bitstream data to AXI DMA (S2MM) via a master-stream port
- FSM packs data into 64-bit transfers
- Handles `tlast` and `tkeep` signals properly at frame boundaries
  
## Config Synchronizer:
- Synchronizes control signals across clock domains
- Uses 2FF (two flip-flop) synchronizers for single-bit signals  
- For multi-bit synchronizers, see: [Multi-clock design techniques](https://nguyenquanicd.blogspot.com/2020/02/multi-clock-design-bai-3-ky-thuat-ong.html)

## Asynchronous FIFOs:
- Used for clock domain crossing (CDC)
- Buffers data between CPU and encoder working at different clock frequencies
  
## H.264 Intra Encoder Core (based on open-source)
- Open-source H.264 intra-frame encoder used in this project
- Reference: [https://github.com/openasic-org/xk264/](https://github.com/openasic-org/xk264/)
