### 系統時鐘 (100MHz)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
###create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}];

### 系統重置 (CPU_RESETN - 紅色按鈕)
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }];

### UART 16550 介面
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { UART_rxd }];
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { UART_txd }];

### LED 狀態指示燈
## LD0: DRAM Ready (你原本就有的)
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { mb_reset }];

## LD1: 診斷用 - 時鐘閃爍 (新增)
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { diag_led_blink }];

## LD2: 診斷用 - 重置按鈕按下指示 (新增)
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { diag_led_rst }];

## 強制保留 AXI 位址和數據匯流排，不准優化
#set_property DONT_TOUCH TRUE [get_cells -hierarchical *axi_uartlite_0*]


##################################################
set_false_path -through [get_cells -hierarchical -filter {NAME =~ *FPU*}]
# set_false_path -from [get_pins MMIO_i/PipelineCPU_0/inst__0/m_WB/m_WB_Reg/reg_alu/data_o_reg[*]/C] \
#               -to [get_pins MMIO_i/PipelineCPU_0/inst__0/m_ID/m_ID_Reg/reg_inst/data_o_reg[*]/D]
#set_false_path -through [get_cells -hierarchical -filter {NAME =~ *SRTDivider*}]