#!/usr/bin/env python3
"""Plot the SoC's UART telemetry (TEL,n,cycles,d0,d1,d2,trip,latched) from the simulation log.
usage: dashboard.py build/uart_log.txt docs/telemetry.png"""
import sys, re
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

src, out = (sys.argv + [None, None])[1:3]
src = src or "build/uart_log.txt"; out = out or "docs/telemetry.png"
rows = [list(map(int, m.groups())) for m in re.finditer(r"TEL,(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)", open(src, errors="ignore").read())]
if not rows: sys.exit("no TEL lines found in " + src)
n, cyc, d0, d1, d2, trp, lat = zip(*rows)
t_ms = [c / 50e3 for c in cyc]                     # 50 MHz -> ms
fig, (a, b) = plt.subplots(2, 1, figsize=(8, 5), sharex=True, gridspec_kw={"height_ratios": [3, 1]})
a.plot(t_ms, d0, "o-", label="phase A duty %"); a.plot(t_ms, d1, "s-", label="phase B duty %"); a.plot(t_ms, d2, "^-", label="phase C duty %")
a.set_ylabel("commanded duty (%)"); a.set_title("PicoRV32 SoC - soft-start with hardware fault trip (simulation)"); a.legend(loc="upper left"); a.grid(alpha=.3)
b.step(t_ms, trp, where="post", label="PWM outputs tripped"); b.step(t_ms, lat, where="post", ls="--", label="fault latched")
b.set_yticks([0, 1]); b.set_xlabel("time (ms)"); b.legend(loc="upper right"); b.grid(alpha=.3)
fig.tight_layout(); fig.savefig(out, dpi=130); print("wrote", out)
