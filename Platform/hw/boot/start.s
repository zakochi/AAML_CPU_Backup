# hw/boot/start.s
.section .vectors, "ax"  
.global _start

.equ UART_BASE,    0x40005000
.equ UART_RX,      0x00
.equ UART_TX,      0x04
.equ UART_STATUS,  0x08
.equ UART_RX_VLD,  0x01
.equ UART_TX_FULL, 0x08
.equ DDR_BASE,     0x60000000


.macro PUTC char
    li a0, \char
    jal ra, uart_putc
.endm

_start:
    # ------------------------------------------
    # 1. Init 
    # ------------------------------------------
    li t0, 0x00006000
    csrs mstatus, t0
    la t0, trap_handler
    csrw mtvec, t0
    li s11, UART_BASE

    # ------------------------------------------
    # 2. Upload code
    # ------------------------------------------
    PUTC 87; PUTC 97; PUTC 105; PUTC 116; PUTC 105; PUTC 110; PUTC 103; PUTC 32
    PUTC 102; PUTC 111; PUTC 114; PUTC 32
    PUTC 65; PUTC 112; PUTC 112; PUTC 32
    PUTC 83; PUTC 105; PUTC 122; PUTC 101; PUTC 10

    # ------------------------------------------
    # 3. Upload
    # ------------------------------------------
    jal ra, recv_uint32
    mv s1, a0            

    li s2, DDR_BASE
    li s3, 0

download_loop:
    bge s3, s1, boot_app
    jal ra, uart_getc
    sb a0, 0(s2)
    addi s2, s2, 1
    addi s3, s3, 1
    j download_loop

boot_app:
    # ------------------------------------------
    # Update DRAM
    # ------------------------------------------
    li t0, 0x60100000
    li t1, 0x60200000
1:  lw t2, 0(t0)
    addi t0, t0, 32
    blt t0, t1, 1b

    # ------------------------------------------
    # 5. Jump to DDR_BASE
    # ------------------------------------------
    fence.i
    li t0, DDR_BASE
    jalr zero, t0, 0

uart_putc:
1:  lw t1, UART_STATUS(s11)
    andi t1, t1, UART_TX_FULL
    bnez t1, 1b
    sw a0, UART_TX(s11)
    ret

uart_getc:
1:  lw t1, UART_STATUS(s11)
    andi t1, t1, UART_RX_VLD
    beqz t1, 1b
    lw a0, UART_RX(s11)
    andi a0, a0, 0xFF
    ret

recv_uint32:
    mv s0, ra
    li t3, 0
    jal ra, uart_getc; or t3, t3, a0
    jal ra, uart_getc; slli a0, a0, 8; or t3, t3, a0
    jal ra, uart_getc; slli a0, a0, 16; or t3, t3, a0
    jal ra, uart_getc; slli a0, a0, 24; or t3, t3, a0
    mv a0, t3
    mv ra, s0
    ret

# ==========================================
# Exception Handler
# ==========================================
.align 4
trap_handler:
    li s11, UART_BASE
    PUTC 69           
    PUTC 58           
    csrr t0, mcause
    addi a0, t0, 48   
    jal ra, uart_putc
    PUTC 10           
1:  j 1b