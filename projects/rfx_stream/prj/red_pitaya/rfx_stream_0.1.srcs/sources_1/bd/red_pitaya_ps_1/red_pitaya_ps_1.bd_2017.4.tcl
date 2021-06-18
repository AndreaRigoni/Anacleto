
################################################################
# This is a generated script based on design: red_pitaya_ps_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2017.4
set current_vivado_version [version -short]
 
# if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
#    puts ""
#    catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}
# 
#    return 1
# }

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source red_pitaya_ps_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# highway, resampler, trarec

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name red_pitaya_ps_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axis_clock_converter:1.1\
pavel-demin:user:axis_decimator:1.0\
pavel-demin:user:axis_packetizer:1.0\
pavel-demin:user:axis_red_pitaya_adc:2.0\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:util_ds_buf:2.1\
pavel-demin:user:axi_cfg_register:1.0\
xilinx.com:ip:axi_fifo_mm_s:4.1\
pavel-demin:user:axi_sts_register:1.0\
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:proc_sys_reset:5.0\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
highway\
resampler\
trarec\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set adc_clk_i [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc_clk_i ]

  # Create ports
  set Led [ create_bd_port -dir O Led ]
  set adc_cdcs_o [ create_bd_port -dir O -from 0 -to 0 adc_cdcs_o ]
  set adc_dat_a [ create_bd_port -dir I -from 13 -to 0 adc_dat_a ]
  set adc_dat_b [ create_bd_port -dir I -from 13 -to 0 adc_dat_b ]
  set ext_clk [ create_bd_port -dir I -type clk ext_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
 ] $ext_clk
  set led_o [ create_bd_port -dir O led_o ]
  set trigger_in_0 [ create_bd_port -dir I trigger_in_0 ]

  # Create instance: adc_clk_stabilizer, and set properties
  set adc_clk_stabilizer [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 adc_clk_stabilizer ]

  # Create instance: axis_clock_converter_0, and set properties
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_0 ]
  set_property -dict [ list \
   CONFIG.IS_ACLK_ASYNC {1} \
 ] $axis_clock_converter_0

  # Create instance: axis_decimator_0, and set properties
  set axis_decimator_0 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_decimator:1.0 axis_decimator_0 ]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_decimator_0/M_AXIS]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_decimator_0/S_AXIS]

  # Create instance: axis_packetizer_0, and set properties
  set axis_packetizer_0 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_packetizer:1.0 axis_packetizer_0 ]
  set_property -dict [ list \
   CONFIG.CONTINUOUS {TRUE} \
 ] $axis_packetizer_0

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_packetizer_0/M_AXIS]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_packetizer_0/S_AXIS]

  # Create instance: axis_packetizer_1, and set properties
  set axis_packetizer_1 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_packetizer:1.0 axis_packetizer_1 ]
  set_property -dict [ list \
   CONFIG.CONTINUOUS {TRUE} \
 ] $axis_packetizer_1

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_packetizer_1/M_AXIS]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_packetizer_1/S_AXIS]

  # Create instance: axis_red_pitaya_adc_0, and set properties
  set axis_red_pitaya_adc_0 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_red_pitaya_adc:2.0 axis_red_pitaya_adc_0 ]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /axis_red_pitaya_adc_0/M_AXIS]

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Algorithm {Minimum_Area} \
   CONFIG.Assume_Synchronous_Clk {false} \
   CONFIG.Disable_Collision_Warnings {false} \
   CONFIG.Enable_32bit_Address {false} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Read_Width_A {32} \
   CONFIG.Read_Width_B {32} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
   CONFIG.Use_Byte_Write_Enable {false} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Use_RSTB_Pin {false} \
   CONFIG.Write_Depth_A {16384} \
   CONFIG.Write_Width_A {32} \
   CONFIG.Write_Width_B {32} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $blk_mem_gen_0

  # Create instance: clock_in, and set properties
  set clock_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 clock_in ]

  # Create instance: command_register, and set properties
  set command_register [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 command_register ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $command_register

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /command_register/S_AXI]

  # Create instance: data_fifo, and set properties
  set data_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.1 data_fifo ]
  set_property -dict [ list \
   CONFIG.C_AXIS_TUSER_WIDTH {4} \
   CONFIG.C_DATA_INTERFACE_TYPE {1} \
   CONFIG.C_RX_FIFO_DEPTH {32768} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {2} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {100} \
   CONFIG.C_S_AXI4_DATA_WIDTH {32} \
   CONFIG.C_USE_RX_DATA {1} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $data_fifo

  # Create instance: decimator_register, and set properties
  set decimator_register [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 decimator_register ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $decimator_register

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /decimator_register/S_AXI]

  # Create instance: event_code, and set properties
  set event_code [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_sts_register:1.0 event_code ]
  set_property -dict [ list \
   CONFIG.STS_DATA_WIDTH {32} \
 ] $event_code

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /event_code/S_AXI]

  # Create instance: highway_0, and set properties
  set block_name highway
  set block_cell_name highway_0
  if { [catch {set highway_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $highway_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: lev_trig_count, and set properties
  set lev_trig_count [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 lev_trig_count ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $lev_trig_count

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /lev_trig_count/S_AXI]

  # Create instance: mode_register, and set properties
  set mode_register [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 mode_register ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $mode_register

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /mode_register/S_AXI]

  # Create instance: packetizer, and set properties
  set packetizer [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 packetizer ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $packetizer

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /packetizer/S_AXI]

  # Create instance: post_register, and set properties
  set post_register [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 post_register ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $post_register

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /post_register/S_AXI]

  # Create instance: pre_register, and set properties
  set pre_register [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 pre_register ]
  set_property -dict [ list \
   CONFIG.CFG_DATA_WIDTH {32} \
 ] $pre_register

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /pre_register/S_AXI]

  # Create instance: red_pitaya_ps, and set properties
  set red_pitaya_ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 red_pitaya_ps ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {166.666672} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_CLK0_FREQ {125000000} \
   CONFIG.PCW_CLK1_FREQ {10000000} \
   CONFIG.PCW_CLK2_FREQ {10000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x1FFFFFFF} \
   CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_ENABLE {1} \
   CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_EN_EMIO_GPIO {0} \
   CONFIG.PCW_EN_EMIO_SPI1 {0} \
   CONFIG.PCW_EN_EMIO_UART0 {0} \
   CONFIG.PCW_EN_ENET0 {1} \
   CONFIG.PCW_EN_GPIO {1} \
   CONFIG.PCW_EN_I2C0 {1} \
   CONFIG.PCW_EN_QSPI {1} \
   CONFIG.PCW_EN_SDIO0 {1} \
   CONFIG.PCW_EN_SPI1 {1} \
   CONFIG.PCW_EN_UART0 {1} \
   CONFIG.PCW_EN_UART1 {0} \
   CONFIG.PCW_EN_USB0 {1} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {4} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} \
   CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {250} \
   CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
   CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C0_I2C0_IO {MIO 50 .. 51} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_ENABLE {0} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_I2C_RESET_ENABLE {1} \
   CONFIG.PCW_I2C_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_MIO_0_DIRECTION {inout} \
   CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_0_PULLUP {enabled} \
   CONFIG.PCW_MIO_0_SLEW {slow} \
   CONFIG.PCW_MIO_10_DIRECTION {inout} \
   CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_10_PULLUP {enabled} \
   CONFIG.PCW_MIO_10_SLEW {slow} \
   CONFIG.PCW_MIO_11_DIRECTION {inout} \
   CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_11_PULLUP {enabled} \
   CONFIG.PCW_MIO_11_SLEW {slow} \
   CONFIG.PCW_MIO_12_DIRECTION {inout} \
   CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_12_PULLUP {enabled} \
   CONFIG.PCW_MIO_12_SLEW {slow} \
   CONFIG.PCW_MIO_13_DIRECTION {inout} \
   CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_13_PULLUP {enabled} \
   CONFIG.PCW_MIO_13_SLEW {slow} \
   CONFIG.PCW_MIO_14_DIRECTION {in} \
   CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_14_PULLUP {enabled} \
   CONFIG.PCW_MIO_14_SLEW {slow} \
   CONFIG.PCW_MIO_15_DIRECTION {out} \
   CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_15_PULLUP {enabled} \
   CONFIG.PCW_MIO_15_SLEW {slow} \
   CONFIG.PCW_MIO_16_DIRECTION {out} \
   CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_16_PULLUP {disabled} \
   CONFIG.PCW_MIO_16_SLEW {fast} \
   CONFIG.PCW_MIO_17_DIRECTION {out} \
   CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_17_PULLUP {disabled} \
   CONFIG.PCW_MIO_17_SLEW {fast} \
   CONFIG.PCW_MIO_18_DIRECTION {out} \
   CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_18_PULLUP {disabled} \
   CONFIG.PCW_MIO_18_SLEW {fast} \
   CONFIG.PCW_MIO_19_DIRECTION {out} \
   CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_19_PULLUP {disabled} \
   CONFIG.PCW_MIO_19_SLEW {fast} \
   CONFIG.PCW_MIO_1_DIRECTION {out} \
   CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_1_PULLUP {enabled} \
   CONFIG.PCW_MIO_1_SLEW {slow} \
   CONFIG.PCW_MIO_20_DIRECTION {out} \
   CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_20_PULLUP {disabled} \
   CONFIG.PCW_MIO_20_SLEW {fast} \
   CONFIG.PCW_MIO_21_DIRECTION {out} \
   CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_21_PULLUP {disabled} \
   CONFIG.PCW_MIO_21_SLEW {fast} \
   CONFIG.PCW_MIO_22_DIRECTION {in} \
   CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_22_PULLUP {disabled} \
   CONFIG.PCW_MIO_22_SLEW {fast} \
   CONFIG.PCW_MIO_23_DIRECTION {in} \
   CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_23_PULLUP {disabled} \
   CONFIG.PCW_MIO_23_SLEW {fast} \
   CONFIG.PCW_MIO_24_DIRECTION {in} \
   CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_24_PULLUP {disabled} \
   CONFIG.PCW_MIO_24_SLEW {fast} \
   CONFIG.PCW_MIO_25_DIRECTION {in} \
   CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_25_PULLUP {disabled} \
   CONFIG.PCW_MIO_25_SLEW {fast} \
   CONFIG.PCW_MIO_26_DIRECTION {in} \
   CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_26_PULLUP {disabled} \
   CONFIG.PCW_MIO_26_SLEW {fast} \
   CONFIG.PCW_MIO_27_DIRECTION {in} \
   CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_27_PULLUP {disabled} \
   CONFIG.PCW_MIO_27_SLEW {fast} \
   CONFIG.PCW_MIO_28_DIRECTION {inout} \
   CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_28_PULLUP {disabled} \
   CONFIG.PCW_MIO_28_SLEW {fast} \
   CONFIG.PCW_MIO_29_DIRECTION {in} \
   CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_29_PULLUP {disabled} \
   CONFIG.PCW_MIO_29_SLEW {fast} \
   CONFIG.PCW_MIO_2_DIRECTION {inout} \
   CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_2_PULLUP {disabled} \
   CONFIG.PCW_MIO_2_SLEW {slow} \
   CONFIG.PCW_MIO_30_DIRECTION {out} \
   CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_30_PULLUP {disabled} \
   CONFIG.PCW_MIO_30_SLEW {fast} \
   CONFIG.PCW_MIO_31_DIRECTION {in} \
   CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_31_PULLUP {disabled} \
   CONFIG.PCW_MIO_31_SLEW {fast} \
   CONFIG.PCW_MIO_32_DIRECTION {inout} \
   CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_32_PULLUP {disabled} \
   CONFIG.PCW_MIO_32_SLEW {fast} \
   CONFIG.PCW_MIO_33_DIRECTION {inout} \
   CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_33_PULLUP {disabled} \
   CONFIG.PCW_MIO_33_SLEW {fast} \
   CONFIG.PCW_MIO_34_DIRECTION {inout} \
   CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_34_PULLUP {disabled} \
   CONFIG.PCW_MIO_34_SLEW {fast} \
   CONFIG.PCW_MIO_35_DIRECTION {inout} \
   CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_35_PULLUP {disabled} \
   CONFIG.PCW_MIO_35_SLEW {fast} \
   CONFIG.PCW_MIO_36_DIRECTION {in} \
   CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_36_PULLUP {disabled} \
   CONFIG.PCW_MIO_36_SLEW {fast} \
   CONFIG.PCW_MIO_37_DIRECTION {inout} \
   CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_37_PULLUP {disabled} \
   CONFIG.PCW_MIO_37_SLEW {fast} \
   CONFIG.PCW_MIO_38_DIRECTION {inout} \
   CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_38_PULLUP {disabled} \
   CONFIG.PCW_MIO_38_SLEW {fast} \
   CONFIG.PCW_MIO_39_DIRECTION {inout} \
   CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_39_PULLUP {disabled} \
   CONFIG.PCW_MIO_39_SLEW {fast} \
   CONFIG.PCW_MIO_3_DIRECTION {inout} \
   CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_3_PULLUP {disabled} \
   CONFIG.PCW_MIO_3_SLEW {slow} \
   CONFIG.PCW_MIO_40_DIRECTION {inout} \
   CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_40_PULLUP {enabled} \
   CONFIG.PCW_MIO_40_SLEW {slow} \
   CONFIG.PCW_MIO_41_DIRECTION {inout} \
   CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_41_PULLUP {enabled} \
   CONFIG.PCW_MIO_41_SLEW {slow} \
   CONFIG.PCW_MIO_42_DIRECTION {inout} \
   CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_42_PULLUP {enabled} \
   CONFIG.PCW_MIO_42_SLEW {slow} \
   CONFIG.PCW_MIO_43_DIRECTION {inout} \
   CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_43_PULLUP {enabled} \
   CONFIG.PCW_MIO_43_SLEW {slow} \
   CONFIG.PCW_MIO_44_DIRECTION {inout} \
   CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_44_PULLUP {enabled} \
   CONFIG.PCW_MIO_44_SLEW {slow} \
   CONFIG.PCW_MIO_45_DIRECTION {inout} \
   CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_45_PULLUP {enabled} \
   CONFIG.PCW_MIO_45_SLEW {slow} \
   CONFIG.PCW_MIO_46_DIRECTION {in} \
   CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_46_PULLUP {enabled} \
   CONFIG.PCW_MIO_46_SLEW {slow} \
   CONFIG.PCW_MIO_47_DIRECTION {in} \
   CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_47_PULLUP {enabled} \
   CONFIG.PCW_MIO_47_SLEW {slow} \
   CONFIG.PCW_MIO_48_DIRECTION {out} \
   CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_48_PULLUP {enabled} \
   CONFIG.PCW_MIO_48_SLEW {slow} \
   CONFIG.PCW_MIO_49_DIRECTION {inout} \
   CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_49_PULLUP {enabled} \
   CONFIG.PCW_MIO_49_SLEW {slow} \
   CONFIG.PCW_MIO_4_DIRECTION {inout} \
   CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_4_PULLUP {disabled} \
   CONFIG.PCW_MIO_4_SLEW {slow} \
   CONFIG.PCW_MIO_50_DIRECTION {inout} \
   CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_50_PULLUP {enabled} \
   CONFIG.PCW_MIO_50_SLEW {slow} \
   CONFIG.PCW_MIO_51_DIRECTION {inout} \
   CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_51_PULLUP {enabled} \
   CONFIG.PCW_MIO_51_SLEW {slow} \
   CONFIG.PCW_MIO_52_DIRECTION {out} \
   CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_52_PULLUP {enabled} \
   CONFIG.PCW_MIO_52_SLEW {slow} \
   CONFIG.PCW_MIO_53_DIRECTION {inout} \
   CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 2.5V} \
   CONFIG.PCW_MIO_53_PULLUP {enabled} \
   CONFIG.PCW_MIO_53_SLEW {slow} \
   CONFIG.PCW_MIO_5_DIRECTION {inout} \
   CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_5_PULLUP {disabled} \
   CONFIG.PCW_MIO_5_SLEW {slow} \
   CONFIG.PCW_MIO_6_DIRECTION {out} \
   CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_6_PULLUP {disabled} \
   CONFIG.PCW_MIO_6_SLEW {slow} \
   CONFIG.PCW_MIO_7_DIRECTION {out} \
   CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_7_PULLUP {disabled} \
   CONFIG.PCW_MIO_7_SLEW {slow} \
   CONFIG.PCW_MIO_8_DIRECTION {out} \
   CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_8_PULLUP {disabled} \
   CONFIG.PCW_MIO_8_SLEW {slow} \
   CONFIG.PCW_MIO_9_DIRECTION {inout} \
   CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_9_PULLUP {enabled} \
   CONFIG.PCW_MIO_9_SLEW {slow} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#Quad SPI Flash#GPIO#SPI 1#SPI 1#SPI 1#SPI 1#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#USB Reset#GPIO#I2C 0#I2C 0#Enet 0#Enet 0} \
   CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#gpio[7]#qspi_fbclk#gpio[9]#mosi#miso#sclk#ss[0]#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#cd#wp#reset#gpio[49]#scl#sda#mdc#mdio} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 2.5V} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {125} \
   CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
   CONFIG.PCW_SD0_GRP_CD_IO {MIO 46} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
   CONFIG.PCW_SD0_GRP_WP_IO {MIO 47} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
   CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SPI1_GRP_SS0_ENABLE {1} \
   CONFIG.PCW_SPI1_GRP_SS0_IO {MIO 13} \
   CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SPI1_SPI1_IO {MIO 10 .. 15} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {6} \
   CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
   CONFIG.PCW_SPI_PERIPHERAL_VALID {1} \
   CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
   CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {48.91} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {7} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {7} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {1} \
   CONFIG.PCW_USB0_RESET_IO {MIO 48} \
   CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_ENABLE {1} \
   CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
   CONFIG.PCW_USE_M_AXI_GP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP0 {1} \
 ] $red_pitaya_ps

  # Create instance: red_pitaya_ps_axi_periph, and set properties
  set red_pitaya_ps_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 red_pitaya_ps_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {19} \
 ] $red_pitaya_ps_axi_periph

  # Create instance: resampler_0, and set properties
  set block_name resampler
  set block_cell_name resampler_0
  if { [catch {set resampler_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $resampler_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /resampler_0/m_axis]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /resampler_0/s_axis]

  # Create instance: rst_red_pitaya_ps_125M, and set properties
  set rst_red_pitaya_ps_125M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_red_pitaya_ps_125M ]

  # Create instance: time_fifo, and set properties
  set time_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.1 time_fifo ]
  set_property -dict [ list \
   CONFIG.C_DATA_INTERFACE_TYPE {1} \
   CONFIG.C_USE_RX_DATA {1} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $time_fifo

  # Create instance: trarec_0, and set properties
  set block_name trarec
  set block_cell_name trarec_0
  if { [catch {set trarec_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $trarec_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /trarec_0/m_axis]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /trarec_0/s_axis]

  set_property -dict [ list \
   CONFIG.TDATA_NUM_BYTES {4} \
 ] [get_bd_intf_pins /trarec_0/t_axis]

  # Create instance: trig_event_code, and set properties
  set trig_event_code [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 trig_event_code ]

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /trig_event_code/S_AXI]

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports adc_clk_i] [get_bd_intf_pins clock_in/CLK_IN_D]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/M_AXIS] [get_bd_intf_pins resampler_0/s_axis]
  connect_bd_intf_net -intf_net axis_decimator_0_M_AXIS [get_bd_intf_pins axis_decimator_0/M_AXIS] [get_bd_intf_pins trarec_0/s_axis]
  connect_bd_intf_net -intf_net axis_packetizer_0_M_AXIS [get_bd_intf_pins axis_packetizer_0/M_AXIS] [get_bd_intf_pins time_fifo/AXI_STR_RXD]
  connect_bd_intf_net -intf_net axis_packetizer_1_M_AXIS [get_bd_intf_pins axis_packetizer_1/M_AXIS] [get_bd_intf_pins data_fifo/AXI_STR_RXD]
  connect_bd_intf_net -intf_net axis_red_pitaya_adc_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/S_AXIS] [get_bd_intf_pins axis_red_pitaya_adc_0/M_AXIS]
  connect_bd_intf_net -intf_net red_pitaya_ps_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins red_pitaya_ps/DDR]
  connect_bd_intf_net -intf_net red_pitaya_ps_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins red_pitaya_ps/FIXED_IO]
  connect_bd_intf_net -intf_net red_pitaya_ps_M_AXI_GP0 [get_bd_intf_pins red_pitaya_ps/M_AXI_GP0] [get_bd_intf_pins red_pitaya_ps_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M00_AXI [get_bd_intf_pins red_pitaya_ps_axi_periph/M00_AXI] [get_bd_intf_pins time_fifo/S_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M01_AXI [get_bd_intf_pins decimator_register/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M02_AXI [get_bd_intf_pins packetizer/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M03_AXI [get_bd_intf_pins pre_register/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M04_AXI [get_bd_intf_pins mode_register/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M05_AXI [get_bd_intf_pins command_register/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M06_AXI [get_bd_intf_pins data_fifo/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M07_AXI [get_bd_intf_pins red_pitaya_ps_axi_periph/M07_AXI] [get_bd_intf_pins time_fifo/S_AXI_FULL]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M08_AXI [get_bd_intf_pins post_register/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M09_AXI [get_bd_intf_pins data_fifo/S_AXI_FULL] [get_bd_intf_pins red_pitaya_ps_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M10_AXI [get_bd_intf_pins event_code/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M11_AXI [get_bd_intf_pins red_pitaya_ps_axi_periph/M11_AXI] [get_bd_intf_pins trig_event_code/S_AXI]
  connect_bd_intf_net -intf_net red_pitaya_ps_axi_periph_M12_AXI [get_bd_intf_pins lev_trig_count/S_AXI] [get_bd_intf_pins red_pitaya_ps_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net resampler_0_m_axis [get_bd_intf_pins axis_decimator_0/S_AXIS] [get_bd_intf_pins resampler_0/m_axis]
  connect_bd_intf_net -intf_net trarec_0_m_axis [get_bd_intf_pins axis_packetizer_1/S_AXIS] [get_bd_intf_pins trarec_0/m_axis]
  connect_bd_intf_net -intf_net trarec_0_t_axis [get_bd_intf_pins axis_packetizer_0/S_AXIS] [get_bd_intf_pins trarec_0/t_axis]

  # Create port connections
  connect_bd_net -net adc_clk_stabilizer_dout [get_bd_ports adc_cdcs_o] [get_bd_pins adc_clk_stabilizer/dout]
  connect_bd_net -net adc_dat_a_0_1 [get_bd_ports adc_dat_a] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_a]
  connect_bd_net -net adc_dat_b_0_1 [get_bd_ports adc_dat_b] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_b]
  connect_bd_net -net axi_cfg_register_0_cfg_data [get_bd_pins highway_0/mode_cfg] [get_bd_pins mode_register/cfg_data] [get_bd_pins resampler_0/mode_cfg] [get_bd_pins trarec_0/mode_cfg]
  connect_bd_net -net blk_mem_gen_0_douta [get_bd_pins blk_mem_gen_0/douta] [get_bd_pins trarec_0/cbuf_douta]
  connect_bd_net -net blk_mem_gen_0_doutb [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins trarec_0/cbuf_doutb]
  connect_bd_net -net command_register_cfg_data [get_bd_pins command_register/cfg_data] [get_bd_pins trarec_0/command_cfg]
  connect_bd_net -net data_fifo_interrupt [get_bd_pins data_fifo/interrupt] [get_bd_pins red_pitaya_ps/IRQ_F2P]
  connect_bd_net -net decimator_cfg_data [get_bd_pins axis_decimator_0/cfg_data] [get_bd_pins decimator_register/cfg_data]
  connect_bd_net -net ext_clk_1 [get_bd_ports ext_clk] [get_bd_pins highway_0/highway_clk]
  connect_bd_net -net highway_0_out_clk [get_bd_pins highway_0/out_clk] [get_bd_pins resampler_0/ext_clk]
  connect_bd_net -net highway_0_out_event_code [get_bd_pins event_code/sts_data] [get_bd_pins highway_0/out_event_code]
  connect_bd_net -net highway_0_out_trig [get_bd_pins highway_0/out_trig] [get_bd_pins trarec_0/async_trigger_in]
  connect_bd_net -net lev_trig_count_cfg_data [get_bd_pins lev_trig_count/cfg_data] [get_bd_pins trarec_0/lev_trig_count]
  connect_bd_net -net packetizer_cfg_data [get_bd_pins axis_packetizer_0/cfg_data] [get_bd_pins axis_packetizer_1/cfg_data] [get_bd_pins packetizer/cfg_data]
  connect_bd_net -net post_register_cfg_data [get_bd_pins post_register/cfg_data] [get_bd_pins trarec_0/post_cfg]
  connect_bd_net -net pre_post_register_cfg_data [get_bd_pins pre_register/cfg_data] [get_bd_pins trarec_0/pre_cfg]
  connect_bd_net -net red_pitaya_ps_FCLK_CLK0 [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins axis_decimator_0/aclk] [get_bd_pins axis_packetizer_0/aclk] [get_bd_pins axis_packetizer_1/aclk] [get_bd_pins command_register/aclk] [get_bd_pins data_fifo/s_axi_aclk] [get_bd_pins decimator_register/aclk] [get_bd_pins event_code/aclk] [get_bd_pins highway_0/aclk] [get_bd_pins lev_trig_count/aclk] [get_bd_pins mode_register/aclk] [get_bd_pins packetizer/aclk] [get_bd_pins post_register/aclk] [get_bd_pins pre_register/aclk] [get_bd_pins red_pitaya_ps/FCLK_CLK0] [get_bd_pins red_pitaya_ps/M_AXI_GP0_ACLK] [get_bd_pins red_pitaya_ps/S_AXI_HP0_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M00_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M01_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M02_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M03_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M04_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M05_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M06_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M07_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M08_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M09_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M10_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M11_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M12_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M13_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M14_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M15_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M16_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M17_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/M18_ACLK] [get_bd_pins red_pitaya_ps_axi_periph/S00_ACLK] [get_bd_pins resampler_0/aclk] [get_bd_pins rst_red_pitaya_ps_125M/slowest_sync_clk] [get_bd_pins time_fifo/s_axi_aclk] [get_bd_pins trarec_0/aclk] [get_bd_pins trig_event_code/aclk]
  connect_bd_net -net red_pitaya_ps_FCLK_RESET0_N [get_bd_pins red_pitaya_ps/FCLK_RESET0_N] [get_bd_pins rst_red_pitaya_ps_125M/ext_reset_in]
  connect_bd_net -net resampler_0_sync_ext_clk [get_bd_pins resampler_0/sync_ext_clk] [get_bd_pins trarec_0/ext_clock]
  connect_bd_net -net rst_red_pitaya_ps_125M_interconnect_aresetn [get_bd_pins red_pitaya_ps_axi_periph/ARESETN] [get_bd_pins rst_red_pitaya_ps_125M/interconnect_aresetn]
  connect_bd_net -net rst_red_pitaya_ps_125M_peripheral_aresetn [get_bd_pins axis_clock_converter_0/m_axis_aresetn] [get_bd_pins axis_clock_converter_0/s_axis_aresetn] [get_bd_pins axis_decimator_0/aresetn] [get_bd_pins axis_packetizer_0/aresetn] [get_bd_pins axis_packetizer_1/aresetn] [get_bd_pins command_register/aresetn] [get_bd_pins data_fifo/s_axi_aresetn] [get_bd_pins decimator_register/aresetn] [get_bd_pins event_code/aresetn] [get_bd_pins lev_trig_count/aresetn] [get_bd_pins mode_register/aresetn] [get_bd_pins packetizer/aresetn] [get_bd_pins post_register/aresetn] [get_bd_pins pre_register/aresetn] [get_bd_pins red_pitaya_ps_axi_periph/M00_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M01_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M02_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M03_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M04_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M05_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M06_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M07_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M08_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M09_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M10_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M11_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M12_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M13_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M14_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M15_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M16_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M17_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/M18_ARESETN] [get_bd_pins red_pitaya_ps_axi_periph/S00_ARESETN] [get_bd_pins rst_red_pitaya_ps_125M/peripheral_aresetn] [get_bd_pins time_fifo/s_axi_aresetn] [get_bd_pins trig_event_code/aresetn]
  connect_bd_net -net trarec_0_cbuf_addra [get_bd_pins blk_mem_gen_0/addra] [get_bd_pins trarec_0/cbuf_addra]
  connect_bd_net -net trarec_0_cbuf_addrb [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins trarec_0/cbuf_addrb]
  connect_bd_net -net trarec_0_cbuf_clka [get_bd_pins blk_mem_gen_0/clka] [get_bd_pins trarec_0/cbuf_clka]
  connect_bd_net -net trarec_0_cbuf_clkb [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins trarec_0/cbuf_clkb]
  connect_bd_net -net trarec_0_cbuf_dina [get_bd_pins blk_mem_gen_0/dina] [get_bd_pins trarec_0/cbuf_dina]
  connect_bd_net -net trarec_0_cbuf_dinb [get_bd_pins blk_mem_gen_0/dinb] [get_bd_pins trarec_0/cbuf_dinb]
  connect_bd_net -net trarec_0_cbuf_ena [get_bd_pins blk_mem_gen_0/ena] [get_bd_pins trarec_0/cbuf_ena]
  connect_bd_net -net trarec_0_cbuf_enb [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins trarec_0/cbuf_enb]
  connect_bd_net -net trarec_0_cbuf_wea [get_bd_pins blk_mem_gen_0/wea] [get_bd_pins trarec_0/cbuf_wea]
  connect_bd_net -net trarec_0_cbuf_web [get_bd_pins blk_mem_gen_0/web] [get_bd_pins trarec_0/cbuf_web]
  connect_bd_net -net trarec_0_led1_o [get_bd_ports led_o] [get_bd_pins trarec_0/led1_o]
  connect_bd_net -net trarec_0_out_synch_trig [get_bd_ports Led]
  connect_bd_net -net trig_event_code_cfg_data [get_bd_pins highway_0/in_event_code] [get_bd_pins trig_event_code/cfg_data]
  connect_bd_net -net trigger_in_0_1 [get_bd_ports trigger_in_0] [get_bd_pins highway_0/in_trig]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins axis_clock_converter_0/s_axis_aclk] [get_bd_pins axis_red_pitaya_adc_0/aclk] [get_bd_pins clock_in/IBUF_OUT]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x50000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs packetizer/s_axi/reg0] SEG_axi_cfg_register_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x58000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs trig_event_code/s_axi/reg0] SEG_axi_cfg_register_0_reg01
  create_bd_addr_seg -range 0x08000000 -offset 0x68000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs lev_trig_count/s_axi/reg0] SEG_axi_cfg_register_0_reg02
  create_bd_addr_seg -range 0x00010000 -offset 0x40420000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs time_fifo/S_AXI/Mem0] SEG_axi_fifo_mm_s_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x40430000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs time_fifo/S_AXI_FULL/Mem1] SEG_axi_fifo_mm_s_0_Mem1
  create_bd_addr_seg -range 0x00010000 -offset 0x70000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs event_code/s_axi/reg0] SEG_axi_sts_register_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x42000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs command_register/s_axi/reg0] SEG_command_register_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x40440000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs data_fifo/S_AXI/Mem0] SEG_data_fifo_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x40450000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs data_fifo/S_AXI_FULL/Mem1] SEG_data_fifo_Mem1
  create_bd_addr_seg -range 0x00010000 -offset 0x60000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs decimator_register/s_axi/reg0] SEG_decimator_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs mode_register/s_axi/reg0] SEG_mode_register_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs post_register/s_axi/reg0] SEG_pre_post_register1_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x48000000 [get_bd_addr_spaces red_pitaya_ps/Data] [get_bd_addr_segs pre_register/s_axi/reg0] SEG_pre_post_register_reg0


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


