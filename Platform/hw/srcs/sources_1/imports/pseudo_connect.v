`timescale 1ns / 1ps

module pseudo_connect(
    // ----------------------------------------------------
    // 1. 外部接口 (FPGA Pin Connections)
    // ----------------------------------------------------
    // A. DDR2 物理接口 
    output [12:0] DDR2_0_addr, output [2:0] DDR2_0_ba, output DDR2_0_cas_n,
    output [0:0] DDR2_0_ck_n, output [0:0] DDR2_0_ck_p, output [0:0] DDR2_0_cke,
    output [0:0] DDR2_0_cs_n, output [1:0] DDR2_0_dm, inout  [15:0] DDR2_0_dq,
    inout  [1:0] DDR2_0_dqs_n, inout  [1:0] DDR2_0_dqs_p, output [0:0] DDR2_0_odt,
    output DDR2_0_ras_n, output DDR2_0_we_n,
    
    // B. 外部時脈與重置輸入
    input CLK100MHZ,             
    input CPU_RESETN,            
    
    // C. 系統狀態與中斷輸出
    output ui_addn_clk_o,        
    output sram_busy_o,            
    output intr_inform_interrupt_o,    

    // D. GPIO 接口 
    input  [31:0] GPIO_0_tri_i,
    output [31:0] GPIO_0_tri_o,
    output [31:0] GPIO_0_tri_t,

    // E. SD Card 物理接口 (新增)
    inout  SD_CMD,           
    inout  [3:0] SD_DAT,     
    output SD_SCK,           
    output SD_RESET,         
    input  SD_CD,            

    // F. STARTUP_IO 接口 
    output STARTUP_IO_0_cfgclk,
    output STARTUP_IO_0_cfgmclk,
    output STARTUP_IO_0_eos,
    output STARTUP_IO_0_preq,

    // G. UART 物理接口 (使用 uart_itf 的名稱)
    output  UART_RXD_OUT,          
    input UART_TXD_IN,           
    input  UART_CTS,          
    output UART_RTS,          
    
    // H. CPU 核心接口 
    input  [31:0] cpu_cdma_addr_i, input  [31:0] cpu_cdma_data_i,
    output [31:0] cpu_cdma_data_o, input  except_complete_i,
    output cdma_rdy_o, output [1:0]cdma_exception_o,
    
    input  cpu_req_wr_i, input  cpu_req_rd_i, input  cacheable_i,
    input  [31:0]cpu_daddr_i,
    input  [31:0] cpu_ddata_i, input  [3:0] dmask_i,
    output [31:0] cpu_ddata_o, output dcache_rdy_o, output [1:0]dcache_exception_o, 
    input  dcache_invalidate_i,
    input  dcache_flush_i, input  dcache_writeback_i,
    
    input  [31:0] pc_i,
    input  icache_invalidate_i, output icache_rdy_o, output icache_exception_o,
    
    output if_ready_o,
    output [31:0] inst_o
);

    // ----------------------------------------------------
    // 2. 內部連線 
    // ----------------------------------------------------
    
    wire sys_clk_buf_w;            
    wire sys_clk_w;                
    wire mig_ref_clk_w;            
    wire [0:0] interconnect_aresetn_w;
    wire [0:0] peripheral_aresetn_w;
    wire aux_reset_w;            
    wire mb_reset_0_w;    
    wire riscv_rst_n_w;    

    wire SPI_0_0_io0_i_w;
    wire SPI_0_0_io0_o_w;
    wire SPI_0_0_io0_t_w;
    wire SPI_0_0_io1_i_w;
    wire SPI_0_0_io1_o_w;
    wire SPI_0_0_io1_t_w;
    wire [0:0] SPI_0_0_ss_i_w;
    wire [0:0] SPI_0_0_ss_o_w;
    wire SPI_0_0_ss_t_w;


    IBUFG u_clk_ibuf (
        .O (sys_clk_buf_w),    
        .I (CLK100MHZ)        
    );
    
    // ----------------------------------------------------
    // 3. 實例化 clk_managment & riscv_rstn_gen 
    // ----------------------------------------------------
    clk_managment u_clk_managment (
        .CLK100MHZ(sys_clk_buf_w),       
        .CPU_RESETN(CPU_RESETN),         
        .aux_reset(aux_reset_w),         
        .interconnect_aresetn(interconnect_aresetn_w),    
        .mb_reset_0(mb_reset_0_w),             
        .mig_ref_clk(mig_ref_clk_w),         
        .peripheral_aresetn(peripheral_aresetn_w),      
        .sys_clk(sys_clk_w)                      
    );
    
    riscv_rstn_gen u_riscv_rstn_gen (
        .clk(sys_clk_w),        
        .mb_rst(mb_reset_0_w),    
        .riscv_rst_n(riscv_rst_n_w)    
    );
    
    // ----------------------------------------------------
    // 5. 實例化 mem_sys_top
    // ----------------------------------------------------
    mem_sys_top u_mem_sys_top (
        // A. DDR2 物理接口 
        .DDR2_0_addr(DDR2_0_addr), .DDR2_0_ba(DDR2_0_ba), .DDR2_0_cas_n(DDR2_0_cas_n),
        .DDR2_0_ck_n(DDR2_0_ck_n), .DDR2_0_ck_p(DDR2_0_ck_p), .DDR2_0_cke(DDR2_0_cke),
        .DDR2_0_cs_n(DDR2_0_cs_n), .DDR2_0_dm(DDR2_0_dm), .DDR2_0_dq(DDR2_0_dq),
        .DDR2_0_dqs_n(DDR2_0_dqs_n), .DDR2_0_dqs_p(DDR2_0_dqs_p), .DDR2_0_odt(DDR2_0_odt),
        .DDR2_0_ras_n(DDR2_0_ras_n), .DDR2_0_we_n(DDR2_0_we_n),
        
        // B. 系統時脈與重置 
        .sys_clk(sys_clk_w),             
        .mig_ref_clk(mig_ref_clk_w),         
        .CLK100MHZ(sys_clk_buf_w),        
        .riscv_rst_n(riscv_rst_n_w),         
        
        // C. 系統狀態與中斷輸出 
        .aux_reset(aux_reset_w),  
        .ui_addn_clk_o(ui_addn_clk_o),
        .sram_busy_o(sram_busy_o),
        .intr_inform_interrupt_o(intr_inform_interrupt_o),    

        // D. AXI Bus 要求的重置輸入 
        .interconnect_aresetn_i(interconnect_aresetn_w),
        .peripheral_aresetn_i(peripheral_aresetn_w),
        .CPU_RESETN(CPU_RESETN),

        // E. 周邊埠 - SPI 接口 (連接到 SD 卡邏輯)
        .SPI_0_0_io0_i(SPI_0_0_io0_i_w), .SPI_0_0_io0_o(SPI_0_0_io0_o_w), .SPI_0_0_io0_t(SPI_0_0_io0_t_w),
        .SPI_0_0_io1_i(SPI_0_0_io1_i_w), .SPI_0_0_io1_o(SPI_0_0_io1_o_w), .SPI_0_0_io1_t(SPI_0_0_io1_t_w),
        .SPI_0_0_ss_i(SPI_0_0_ss_i_w), .SPI_0_0_ss_o(SPI_0_0_ss_o_w), .SPI_0_0_ss_t(SPI_0_0_ss_t_w),

        // E. 周邊埠 - STARTUP_IO (用於 SCK)
        .STARTUP_IO_0_cfgclk(STARTUP_IO_0_cfgclk), .STARTUP_IO_0_cfgmclk(STARTUP_IO_0_cfgmclk),
        .STARTUP_IO_0_eos(STARTUP_IO_0_eos), .STARTUP_IO_0_preq(STARTUP_IO_0_preq),
        
        // E. 周邊埠 - UART 接口 (連接到 uart_itf)
        .usb_uart_ctsn(UART_CTS),  
        .usb_uart_rtsn(UART_RTS),  
        .usb_uart_rxd(UART_TXD_IN),     
        .usb_uart_txd(UART_RXD_OUT),     

        // E. 周邊埠 - GPIO
        .GPIO_0_tri_i(GPIO_0_tri_i), .GPIO_0_tri_o(GPIO_0_tri_o), .GPIO_0_tri_t(GPIO_0_tri_t),
        
        // F. CPU 核心接口 
        .cpu_cdma_addr_i(cpu_cdma_addr_i), .cpu_cdma_data_i(cpu_cdma_data_i),
        .cpu_cdma_data_o(cpu_cdma_data_o), 
        .cdma_rdy_o(cdma_rdy_o), .cdma_exception_o(cdma_exception_o),
        
        .cpu_req_wr_i(cpu_req_wr_i), .cpu_req_rd_i(cpu_req_rd_i), .cacheable_i(cacheable_i),
        .cpu_daddr_i(cpu_daddr_i),
        .cpu_ddata_i(cpu_ddata_i), .dmask_i(dmask_i),
        .cpu_ddata_o(cpu_ddata_o), .dcache_rdy_o(dcache_rdy_o), .dcache_exception_o(dcache_exception_o),
        .dcache_invalidate_i(dcache_invalidate_i),
        .dcache_flush_i(dcache_flush_i), .dcache_writeback_i(dcache_writeback_i),
        
        .pc_i(pc_i),
        .icache_invalidate_i(icache_invalidate_i), .icache_rdy_o(icache_rdy_o), .icache_exception_o(icache_exception_o),
        .icache_except_complete_i(icache_except_complete_i),
        
        .if_ready_o(if_ready_o),
        .inst_o(inst_o)
    );

    // ----------------------------------------------------
    // SD Card Interface Connection (Direct Assign - WARNING: May fail synthesis)
    // ----------------------------------------------------

    // SD_CMD (IO0)
    assign SD_CMD = (SPI_0_0_io0_t_w == 1'b0) ? SPI_0_0_io0_o_w : 1'bz;
    assign SPI_0_0_io0_i_w = SD_CMD;

    // SD_DAT[0] (IO1)
    assign SD_DAT[0] = (SPI_0_0_io1_t_w == 1'b0) ? SPI_0_0_io1_o_w : 1'bz;
    assign SPI_0_0_io1_i_w = SD_DAT[0];

    // SD_DAT[3] (SS - Chip Select)
    assign SD_DAT[3] = (SPI_0_0_ss_t_w == 1'b0) ? SPI_0_0_ss_o_w : 1'bz;
    assign SPI_0_0_ss_i_w = SD_DAT[3];

    // SD_SCK
    assign SD_SCK = STARTUP_IO_0_cfgmclk;

    // Other SD pins
    assign SD_DAT[1] = 1'bZ;
    assign SD_DAT[2] = 1'bZ;
    assign SD_RESET = 1'b1;

endmodule