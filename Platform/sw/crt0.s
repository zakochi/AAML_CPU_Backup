# sw/crt0.s
.section .text.startup
.global _start

_start:
    # 1. 設定 Stack (128MB DDR2 的頂端)
    li sp, 0x67FFFFF0
    li s0, 0x40005000

    # 💣 印出 '!' (ASCII 33) 代表進入 DDR 成功
    li t0, 33
    sw t0, 4(s0)

    # 2. 清除 BSS
    la a0, __bss_start
    la a1, __bss_end
    bgeu a0, a1, end_clear_bss
clear_bss_loop:
    sw zero, 0(a0)
    addi a0, a0, 4
    bltu a0, a1, clear_bss_loop
end_clear_bss:

    # 💣 印出 '@' (ASCII 64) 代表 BSS 清除完畢
    li t0, 64
    sw t0, 4(s0)

    # 3. 初始化 C++ 環境 (printf 需要這個)
    call __libc_init_array

    # 💣 印出 '#' (ASCII 35) 代表 C++ 初始化完畢
    li s0, 0x40005000
    li t0, 35
    sw t0, 4(s0)

    # 4. 進入 main
    call main

1:  j 1b