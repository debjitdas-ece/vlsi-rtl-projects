/* ROM @0x0000_0000 (4 KB), SRAM @0x0001_0000 (RAM_LEN bytes, default 1 KB) */
RAM_LEN = DEFINED(RAM_LEN) ? RAM_LEN : 1024;
MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  RAM (rwx) : ORIGIN = 0x00010000, LENGTH = RAM_LEN
}
ENTRY(_start)
SECTIONS {
  .text : { *(.text.start) *(.text*) *(.rodata*) *(.srodata*) . = ALIGN(4); } > ROM
  .data : { *(.data*) *(.sdata*) . = ALIGN(4); } > RAM AT > ROM
  .bss  : { _bss_start = .; *(.bss*) *(.sbss*) *(COMMON) . = ALIGN(4); _bss_end = .; } > RAM
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
