# PWM IP — Module Hierarchy

## Compile order (also see filelist.f)
1. pwm_prescaler.v
2. pwm_updown_counter.v
3. pwm_dbuf.v
4. pwm_compare.v
5. pwm_deadtime.v
6. pwm_trip.v
7. pwm_adc.v
8. pwm_top.v            (instantiates 1-7)
9. pwm_apb_wrapper.v    (instantiates pwm_top)

## Instance tree

```
pwm_apb_wrapper                          (top-level, APB3 slave, params: P_S, N, SAFE_STATE)
└─ dut : pwm_top                         (params: P_S=P_S, N=N, SAFE_STATE=SAFE_STATE)
   ├─ p_s_inst          : pwm_prescaler       (#PRESCALER=P_S)          x1
   ├─ updown_cnt_inst   : pwm_updown_counter                            x1
   ├─ top_dbuf_inst     : pwm_dbuf                                      x1   (top_val double-buffer only)
   ├─ adctrig_a_inst    : pwm_adc             (#dir_sel=0)              x1
   ├─ adctrig_b_inst    : pwm_adc             (#dir_sel=0)              x1
   ├─ ch[i].dbuf_inst   : pwm_dbuf                                      xN   (one per channel, duty only)
   ├─ ch[i].cmp_inst    : pwm_compare                                   xN
   ├─ ch[i].deadtime_inst : pwm_deadtime                                xN
   └─ trip_inst         : pwm_trip           (#N=2*N, #SAFE_STATE)      x1   (shared, sits after all N deadtime pairs)
```

`ch[i]` is the generate-block instance name (`genvar i`, `0 <= i < N`); e.g. channel 0's comparator is
`dut.ch[0].cmp_inst`, channel 0's dead-time block is `dut.ch[0].deadtime_inst`.

## Signal flow per channel (i = 0..N-1)

```
duty_in[i], duty_id[i] ─► ch[i].dbuf_inst ─► duty_active_i ─┐
                                                             ▼
                          cnt (from updown_cnt_inst) ──► ch[i].cmp_inst ──► cmp_out_i
                                                             │
                                              polarity[i] XOR (pol_out_i)
                                                             ▼
                                              ch[i].deadtime_inst ──► dt_hs_i, dt_ls_i
                                                             ▼
                                    pre_trip[2i] = dt_hs_i, pre_trip[2i+1] = dt_ls_i
                                                             ▼
                                            trip_inst (shared, all channels) ──► pwm_out[2i], pwm_out[2i+1]
```

`pwm_out` is `2*N` bits wide: `pwm_out[2*i]` = channel i high-side, `pwm_out[2*i+1]` = channel i low-side.

## Shared timebase signals (fan out to every channel)
- `cnt`, `dir` — from `updown_cnt_inst`, driven by `tick` from `p_s_inst`
- `z_f` — trough marker (`cnt==0`), commits all `pwm_dbuf` shadow registers and is the CBC trip auto-clear condition
- `z_f_pulse = z_f & tick` — single-cycle version, drives `sync_out` only

## APB register map (pwm_apb_wrapper.v)
| Offset | Register | Bits |
|---|---|---|
| 0x00 | CTRL | [0] mode_sel, [1] sync_en |
| 0x04 | PHASE_OFFSET | [10:0] |
| 0x08 | TOP_VAL | [10:0], write pulses top_id next cycle |
| 0x0C/10/14 | DUTY0/1/2 | [10:0], write pulses duty_id[i] next cycle |
| 0x18 | POLARITY | [2:0] |
| 0x1C | DEADTIME | [7:0] rising, [15:8] falling |
| 0x20 | TRIP_CTRL | [0] trip_mode, [1] trip_clear (W1 pulse), [2] soft_trip |
| 0x24 | TRIG_CTRL | [0]/[2] trig_en_a/b, [1]/[3] dir_qual_a/b |
| 0x28/2C | TRIG_POINT_A/B | [10:0] |
| 0x30 | STATUS (RO) | [0] trip_active, [1] adc_trig_a, [2] adc_trig_b |
| 0x34 | LOCK | [0] — blocks writes to TRIP_CTRL and DEADTIME while set |

## Known fixed-at-synthesis parameters (not APB registers)
- `P_S` (prescaler divide ratio)
- `N` (channel count, default 3)

## Testbenches (not part of the RTL delivery, kept for regression)
- tb_smoke.v — end-to-end pwm_top check: no hs/ls overlap, trip forces safe output
- tb_apb.v — APB register readback, commit-pulse timing, trip status, LOCK enforcement
- tb_counter_mode.v — directed check of edge-aligned vs center-aligned counter sequences
