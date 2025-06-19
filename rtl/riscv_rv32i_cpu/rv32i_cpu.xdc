create_clock -period 10.000 -name common -waveform {0.000 5.000} -add [get_ports {m_axi_lite_aclk s_axi_lite_aclk}]
