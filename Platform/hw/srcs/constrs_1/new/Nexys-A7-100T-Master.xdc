set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
###create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}];

set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }];

set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { UART_rxd }];
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { UART_txd }];


## LD0: DRAM Ready 
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { mb_reset }];

set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { diag_led_blink }];

set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { diag_led_rst }];


##################################################
set_false_path -through [get_cells -hierarchical -filter {NAME =~ *FPU*}]
# set_false_path -from [get_pins MMIO_i/PipelineCPU_0/inst__0/m_WB/m_WB_Reg/reg_alu/data_o_reg[*]/C] \
#               -to [get_pins MMIO_i/PipelineCPU_0/inst__0/m_ID/m_ID_Reg/reg_inst/data_o_reg[*]/D]
#set_false_path -through [get_cells -hierarchical -filter {NAME =~ *SRTDivider*}]
