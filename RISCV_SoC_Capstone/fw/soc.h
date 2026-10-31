#ifndef SOC_H
#define SOC_H
typedef unsigned int u32;
#define REG(a) (*(volatile u32 *)(a))
/* UART @0x1000_0000 */
#define UART_TX      (*(volatile unsigned char *)0x10000000)
#define UART_RX      (*(volatile unsigned char *)0x10000004)
#define UART_STATUS  REG(0x10000008)   /* b0 tx_busy b1 rx_valid b2 overrun b3 frame_err */
#define UART_DIV     REG(0x1000000C)
/* PWM @0x2000_0000 (SoC-plus) */
#define PWM_CTRL     REG(0x20000000)   /* b0 en b1 sw_trip b2 flt_en b3 trip_clr(W1) */
#define PWM_PSC      REG(0x20000004)
#define PWM_PER      REG(0x20000008)
#define PWM_DT       REG(0x2000000C)
#define PWM_ATRG     REG(0x20000010)
#define PWM_STATUS   REG(0x20000014)   /* b0 trp b1 trp_lat b2 flt_in b3 en */
#define PWM_DUTY(i)  REG(0x20000020 + 4*(i))
/* GPIO @0x3000_0000 (SoC-plus) */
#define GPIO_OUT     REG(0x30000000)
#define GPIO_IN      REG(0x30000004)
#define GPIO_STATUS  REG(0x30000008)   /* b0 bus_err (sticky, write clears) */

static inline void uart_putc(char c) { UART_TX = c; }          /* AXI back-pressure stalls CPU */
static inline void uart_puts(const char *s) { while (*s) uart_putc(*s++); }
static inline char uart_getc(void) { while (!(UART_STATUS & 2)); return UART_RX; }
static inline u32 cycles(void) { u32 x; __asm__ volatile("rdcycle %0" : "=r"(x)); return x; }
#endif
