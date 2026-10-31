/* Base capstone firmware: 10 greetings, then UART echo (Module 6 testbench flow). */
#include "soc.h"
int main(void) {
  for (int i = 0; i < 10; i++) uart_puts("Hello from PicoRV32 SoC!\r\n");
  for (;;) uart_putc(uart_getc());
}
