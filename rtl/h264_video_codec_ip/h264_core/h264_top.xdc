create_clock -period 16.000 -name h264_aclk -waveform {0.000 8.000} -add [get_ports h264_aclk]
create_clock -period 10.000 -name axi_aclk -waveform {0.000 5.000} -add [get_ports {m_axis_s2mm_aclk s_axi_lite_aclk s_axis_mm2s_aclk}]

set_false_path -reset_path -from [get_clocks axi_aclk] -to [get_clocks h264_aclk]
set_false_path -reset_path -from [get_clocks h264_aclk] -to [get_clocks axi_aclk]
