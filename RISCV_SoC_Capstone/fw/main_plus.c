/* SoC-plus firmware: EV motor-drive demo (soft-start, hardware trip, auto-recovery,
 * CSV telemetry over UART) followed by an interactive command shell.
 * RV32I only: no multiply/divide, so decimal conversion uses shifts and subtraction. */
#include "soc.h"

#define PER 500u                      /* PWM period counts: 2*500 clk = 20 us = 50 kHz */
static u32 pct[3];

static void putu(u32 v) {
  static const u32 p10[] = {1000000000u, 100000000u, 10000000u, 1000000u, 100000u, 10000u, 1000u, 100u, 10u, 1u};
  int started = 0;
  for (int i = 0; i < 10; i++) {
    u32 d = 0;
    while (v >= p10[i]) { v -= p10[i]; d++; }
    if (d || started || i == 9) { uart_putc('0' + d); started = 1; }
  }
}
static void puts_(const char *s) { uart_puts(s); }
static u32 x5(u32 v) { return (v << 2) + v; }            /* v * 5 */
static void set_duty(u32 ch, u32 p) { pct[ch] = p; PWM_DUTY(ch) = x5(p); }

static void telemetry(u32 n) {
  u32 st = PWM_STATUS;
  puts_("TEL,"); putu(n); uart_putc(','); putu(cycles()); uart_putc(',');
  putu(pct[0]); uart_putc(','); putu(pct[1]); uart_putc(','); putu(pct[2]); uart_putc(',');
  putu(st & 1); uart_putc(','); putu((st >> 1) & 1); puts_("\r\n");
}

static int streq(const char *a, const char *b) { while (*a && *a == *b) { a++; b++; } return *a == *b; }
static const char *skip(const char *s) { while (*s == ' ') s++; return s; }
static u32 parse_dec(const char **s) { u32 v = 0; while (**s >= '0' && **s <= '9') { v = (v << 3) + (v << 1) + (**s - '0'); (*s)++; } return v; }
static u32 parse_hex(const char **s) {
  u32 v = 0;
  for (;;) {
    char c = **s; u32 d;
    if (c >= '0' && c <= '9') d = c - '0'; else if (c >= 'a' && c <= 'f') d = c - 'a' + 10; else break;
    v = (v << 4) | d; (*s)++;
  }
  return v;
}

static void cmd(const char *l) {
  if (streq(l, "st")) {
    u32 st = PWM_STATUS;
    puts_("ST en="); putu((st >> 3) & 1); puts_(" trp="); putu(st & 1); puts_(" lat="); putu((st >> 1) & 1);
    puts_(" d="); putu(pct[0]); uart_putc(','); putu(pct[1]); uart_putc(','); putu(pct[2]);
    puts_(" busErr="); putu(GPIO_STATUS & 1); puts_(" cyc="); putu(cycles()); puts_("\r\n");
  } else if (l[0] == 'd' && l[1] == ' ') {
    const char *p = skip(l + 1); u32 ch = parse_dec(&p); p = skip(p); u32 v = parse_dec(&p);
    if (ch > 2 || v > 100) puts_("ERR range\r\n"); else { set_duty(ch, v); puts_("OK\r\n"); }
  } else if (l[0] == 'g' && l[1] == ' ') {
    const char *p = skip(l + 1); GPIO_OUT = parse_hex(&p); puts_("OK\r\n");
  } else if (streq(l, "en"))  { PWM_CTRL = 0x5; puts_("OK\r\n"); }
  else if (streq(l, "dis"))   { PWM_CTRL = 0x4; puts_("OK\r\n"); }
  else if (streq(l, "clr"))   { PWM_CTRL = 0xD; puts_("OK\r\n"); }
  else if (streq(l, "bus"))   { u32 x = REG(0x50000000); puts_("bus read -> "); putu(x & 0xFFFF); puts_(" busErr="); putu(GPIO_STATUS & 1); puts_("\r\n"); }
  else if (streq(l, "help"))  puts_("st | d <ch> <pct> | g <hex> | en | dis | clr | bus\r\n");
  else if (l[0])              puts_("ERR\r\n");
}

int main(void) {
  PWM_PSC = 0; PWM_PER = PER; PWM_DT = 25; PWM_ATRG = PER >> 1;
  for (u32 i = 0; i < 3; i++) set_duty(i, 0);
  PWM_CTRL = 0x5;                                    /* enable + hardware fault enable */
  GPIO_OUT = 0x01;
  puts_("EV-SoC PicoRV32/AXI-Lite v1.0\r\nREADY\r\n");

  /* soft-start ramp with fault supervision */
  for (u32 n = 1; n <= 12; n++) {
    u32 st = PWM_STATUS;
    if ((st & 2) && !(st & 4)) { puts_("CLR\r\n"); PWM_CTRL = 0xD; GPIO_OUT = 0x01; }   /* latched trip, fault gone */
    else if (st & 1)           { GPIO_OUT = 0x80; }                                      /* alarm LED */
    u32 p = n << 3;                                  /* 8% per step */
    set_duty(0, p); set_duty(1, p - (p >> 2)); set_duty(2, p >> 1);
    telemetry(n);
  }

  char line[24]; u32 len = 0;
  puts_("> ");
  for (;;) {
    char c = uart_getc();
    if (c == '\r' || c == '\n') {
      line[len] = 0; puts_("\r\n"); cmd(line); len = 0; puts_("> ");
    } else if (len < sizeof(line) - 1) { line[len++] = c; uart_putc(c); }
  }
}
