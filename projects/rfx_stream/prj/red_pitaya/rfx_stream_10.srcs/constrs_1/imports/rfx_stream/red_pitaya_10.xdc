



### LED PINS
set_property PACKAGE_PIN F16 [get_ports led_o]

# set_property PACKAGE_PIN F17 [get_ports {pwm_out_1[0]}]
# set_property PACKAGE_PIN G15 [get_ports {pwm_n_out_1[0]}]
# set_property PACKAGE_PIN H15     [get_ports {led_o[3]}]
# set_property PACKAGE_PIN K14     [get_ports {led_o[4]}]
# set_property PACKAGE_PIN G14     [get_ports {led_o[5]}]
# set_property PACKAGE_PIN J15     [get_ports {led_o[6]}]
# set_property PACKAGE_PIN J14     [get_ports {led_o[7]}]



### ADC

set_property IOSTANDARD LVCMOS18 [get_ports {adc_dat_a[*]}]
set_property IOB        TRUE     [get_ports {adc_dat_a[*]}]


set_property PACKAGE_PIN W14 [get_ports {adc_dat_a[4]}]
set_property PACKAGE_PIN Y14 [get_ports {adc_dat_a[5]}]
set_property PACKAGE_PIN W13 [get_ports {adc_dat_a[6]}]
set_property PACKAGE_PIN V12 [get_ports {adc_dat_a[7]}]
set_property PACKAGE_PIN V13 [get_ports {adc_dat_a[8]}]
set_property PACKAGE_PIN T14 [get_ports {adc_dat_a[9]}]
set_property PACKAGE_PIN T15 [get_ports {adc_dat_a[10]}]
set_property PACKAGE_PIN V15 [get_ports {adc_dat_a[11]}]
set_property PACKAGE_PIN T16 [get_ports {adc_dat_a[12]}]
set_property PACKAGE_PIN V16 [get_ports {adc_dat_a[13]}]
# set_property PACKAGE_PIN T15 [get_ports {adc_dat_a[10]}]
# set_property PACKAGE_PIN V15 [get_ports {adc_dat_a[11]}]
# set_property PACKAGE_PIN T16 [get_ports {adc_dat_a[12]}]
# set_property PACKAGE_PIN V16 [get_ports {adc_dat_a[13]}]


set_property IOSTANDARD LVCMOS18 [get_ports {adc_dat_b[*]}]
set_property IOB        TRUE     [get_ports {adc_dat_b[*]}]

set_property PACKAGE_PIN R19 [get_ports {adc_dat_b[4]}]
set_property PACKAGE_PIN T20 [get_ports {adc_dat_b[5]}]
set_property PACKAGE_PIN T19 [get_ports {adc_dat_b[6]}]
set_property PACKAGE_PIN U20 [get_ports {adc_dat_b[7]}]
set_property PACKAGE_PIN V20 [get_ports {adc_dat_b[8]}]
set_property PACKAGE_PIN W20 [get_ports {adc_dat_b[9]}]
set_property PACKAGE_PIN W19 [get_ports {adc_dat_b[10]}]
set_property PACKAGE_PIN Y19 [get_ports {adc_dat_b[11]}]
set_property PACKAGE_PIN W18 [get_ports {adc_dat_b[12]}]
set_property PACKAGE_PIN Y18 [get_ports {adc_dat_b[13]}]
# set_property PACKAGE_PIN W19 [get_ports {adc_dat_b[10]}]
# set_property PACKAGE_PIN Y19 [get_ports {adc_dat_b[11]}]
# set_property PACKAGE_PIN W18 [get_ports {adc_dat_b[12]}]
# set_property PACKAGE_PIN Y18 [get_ports {adc_dat_b[13]}]

#set_input_delay -clock [get_clocks clk_fpga_0] -min -add_delay 4.000 [get_ports {adc_dat_a[*]}]
#set_input_delay -clock [get_clocks clk_fpga_0] -max -add_delay 4.000 [get_ports {adc_dat_a[*]}]
#set_input_delay -clock [get_clocks clk_fpga_0] -min -add_delay 4.000 [get_ports {adc_dat_b[*]}]
#set_input_delay -clock [get_clocks clk_fpga_0] -max -add_delay 4.000 [get_ports {adc_dat_b[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports led_o]
set_property PULLDOWN true [get_ports led_o]

set_property IOSTANDARD LVCMOS33 [get_ports trigger_in_0]
set_property PACKAGE_PIN H16 [get_ports trigger_in_0]

set_property PULLDOWN true [get_ports trigger_in_0]

set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property PACKAGE_PIN G18 [get_ports clock]

# ADC CLOCK IN
# set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports adc_clk_i[*]]
# set_property PACKAGE_PIN U18           [get_ports adc_clk_i[1]]
# set_property PACKAGE_PIN U19           [get_ports adc_clk_i[0]]

set_property IOSTANDARD LVCMOS18 [get_ports adc_clk_i]
set_property PACKAGE_PIN U18     [get_ports adc_clk_i]


# ADC clock stabilizer
set_property IOSTANDARD LVCMOS18 [get_ports {adc_cdcs_o[0]}]
set_property PACKAGE_PIN V18 [get_ports {adc_cdcs_o[0]}]
set_property SLEW FAST [get_ports {adc_cdcs_o[0]}]
set_property DRIVE 8 [get_ports {adc_cdcs_o[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports ext_clk]
set_property PACKAGE_PIN K17 [get_ports ext_clk]

set_property IOSTANDARD LVCMOS33 [get_ports Led]
set_property PULLDOWN true [get_ports Led]
set_property PACKAGE_PIN F17 [get_ports Led]

# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {adc_clk_i_clk_n[0]}]
# set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {adc_clk_i_clk_p[0]}]
# set_property PACKAGE_PIN U18 [get_ports {adc_clk_i_clk_p[0]}]
