/* sw/runtime/linker.ld */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    DDR2_RAM (rwx) : ORIGIN = 0x60000000, LENGTH = 128M
}

_STACK_SIZE = 512K;
_HEAP_SIZE  = 512K;

SECTIONS
{
    .text : {
        . = ALIGN(4);
        _stext = .;
        KEEP(*crt0.o(.text.startup))
        *(.text.startup)
        *(.text .text.*)
        *(.gnu.linkonce.t.*)
        _etext = .;
    } > DDR2_RAM

    .rodata : {
        . = ALIGN(4);
        _srodata = .;
        *(.rodata .rodata.*)
        _erodata = .;
    } > DDR2_RAM

    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        _edata = .;
    } > DDR2_RAM

    .bss : {
        . = ALIGN(4);
        _bss_start = .;
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
        __bss_end = .;
    } > DDR2_RAM

    .stack : {
        . = ALIGN(16);
        _stack_end = .;
        . += _STACK_SIZE;
        _stack_start = .;
		__stack_top = .;
    } > DDR2_RAM

    .heap : {
        . = ALIGN(8);
        _heap_start = .;
        . += _HEAP_SIZE;
        _heap_end = .;
    } > DDR2_RAM

    _end = .;
}
