create_clock -period 6.000 -name common_clk -waveform {0.000 3.000} -add [get_ports {m_axi_lite_aclk s_axi_lite_aclk}]

