# Interview sheet: FIFO, CDC & RDC

Project folder: `05_FIFO_CDC_RDC/`

## What I built

- A synchronous FIFO and an asynchronous FIFO (Gray-coded pointers, two-flop synchronizers), both first-word-fall-through.
- The other standard crossing structures: pulse synchronizer, 4-phase handshake for multi-bit words, and a reset synchronizer (async assert, sync deassert).
- Self-checking testbenches: the async FIFO runs 20,000 random words at 6 clock ratios, with and without a bus-skew model.
- SVA bind files for both FIFOs, a CDC bug gallery, Verilator lint-clean RTL, and a regression of 18 checks that runs in CI.

## Three design decisions

1. **Gray-coded pointers and registered flags.** Only the Gray pointer crosses the clock boundary. It changes by one bit per step, so a sample taken mid-change is either the old or the new pointer, never one that did not exist. `wfull` and `rempty` are registered, so a stale pointer only makes the FIFO look fuller or emptier than it is. That is the safe direction: no overflow, no underflow. The cost is a couple of cycles of flag latency, so the usable depth under heavy traffic is slightly smaller than the nominal depth.
2. **Pointers one bit wider than the address, instead of a shared counter.** A shared fill counter would itself have to cross domains. Comparing pointers needs no shared state. Equal pointers mean empty. In Gray code, "full" is the next write pointer equal to the synchronized read pointer with its top two bits inverted.
3. **Toggle for pulses, handshake for words.** A plain 2FF can drop a one-cycle pulse going from a fast clock to a slow one (35 of 83 received in my test). A toggle that flips on each pulse and is edge-detected in the destination never loses one, provided pulses are at least about 3 destination clocks apart. For arbitrary multi-bit data I use a req/ack handshake that holds the data stable until the ack returns. It is slower, but it is correct for any value. Gray only works for values that count by one.

## A bug I hit and how I found it

My first version of the bus-skew model made the **correct** Gray crossing fail: 23 bad jumps in the bug gallery, where I expected 0. I only noticed because the gallery runs a known-good case next to the known-bad one.

The cause was in the model, not the FIFO. I had marked every bit that changed since the last destination sample as "may resolve old or new". But Gray's one-bit guarantee holds per source clock. The destination clock was slower, so several source steps happened between two destination samples, and my model treated all of those changes as simultaneous.

The fix was to model what really causes the problem: routing skew. Bit *i* of the bus is delayed by *i* × `SKEW` ps. After that, the plain binary counter showed 28 bad jumps and the Gray version showed 0.

Lesson: a checker has to be validated against a case that must pass as well as a case that must fail.

## What I would improve

- **Constrain the crossings.** In Phase 5 I want OpenSTA constraints for the pointer crossings (max-delay and skew limits on the Gray buses). Simulation cannot prove CDC safety.
- **Reproduce the binary-pointer failure.** I could not make a binary-pointer async FIFO fail in RTL simulation. It is still wrong in silicon, and I know that from the structure, not from a failing test.
- **Cover more FIFO configurations:** non-power-of-two depth, a synchronous-read (block RAM) variant, almost-full and almost-empty flags on the async FIFO.
- **Balance the coverage.** In some runs the async FIFO reaches empty only a few times, or never reaches full. I'd add directed phases so every run hits both.
- **Put `reset_sync` inside the async FIFO wrapper,** and run the testbenches under a second simulator.
- **Build a UVM environment and bind-based coverage** on top of this (Phase 1).

## Questions to be ready for

**What is metastability, and why do two flops help?** A flop sampling a signal that changes near its clock edge can sit between 0 and 1 for a while. The second flop gives that value a full clock period to settle before anything uses it. The chance of a failure falls roughly exponentially with the settling time, so more time means a much longer mean time between failures. Faster clocks or stricter reliability targets need a third stage.

**Why can't I send a multi-bit bus through plain 2FFs?** The bits can arrive in different destination cycles, so the destination can capture a value that never existed (0x0F to 0x10 sampled as 0x1F). Use Gray for counters, a handshake for arbitrary data, or an async FIFO.

**Why Gray code and not binary for FIFO pointers?** Gray changes one bit per increment, so any sampled value is either the old or new pointer.

**Why register full and empty?** It removes combinational paths from the synchronized pointer to the outputs, and a stale pointer only ever errs toward full or empty, which is safe.

**Why async assert and sync deassert for reset?** Asserting immediately is safe at any time. A deassertion that lands near a clock edge can violate recovery/removal timing and put different flops in different states, so it is synchronized.

**How would you size the FIFO?** From the burst length and the difference in write and read rates, plus a few entries for the synchronizer and flag latency.

**How do you verify a CDC design?** Simulation cannot show metastability. I use structural review of every crossing (signal, source clock, destination clock, structure, why it is safe), assertions such as "Gray pointers change by at most one bit per clock", lint, and a CDC tool where available.
