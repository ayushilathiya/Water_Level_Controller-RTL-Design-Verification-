# Smart Water Level Controller — RTL Design & Verification

## Files
- `water_level_controller.v` — Synthesizable RTL (Verilog). 4-state FSM (EMPTY, FILLING,
  FULL, DRAINING) with sensor-based hysteresis and asynchronous active-low reset.
- `water_level_controller_tb.v` — Self-checking testbench, 8 automated checks covering
  fill cycle, hysteresis, and async reset (mid-operation and at startup).

## How to run (Icarus Verilog — free, ~2 min install)
```bash
# Install (Ubuntu/Debian)
sudo apt-get install iverilog

# Compile and simulate
iverilog -o sim.out water_level_controller.v water_level_controller_tb.v
vvp sim.out

# View waveform (optional, needs GTKWave)
gtkwave water_level_controller_tb.vcd
```

**Verified result:** all 8 self-checks pass (confirmed in this session — see console
output showing `[PASS]` on each check and `==== ALL TESTS PASSED ====`).

## Design notes
- **Hysteresis** is real, not cosmetic: once FULL, the motor stays off until the level
  drops all the way back below the LOW sensor (not just below HIGH), preventing motor
  chatter near the threshold — this is the kind of design decision worth explaining if
  asked about it in an interview.
- **Async reset** is tested at two points: at simulation start, and mid-operation while
  the tank is filling — both confirm the FSM returns cleanly to `S_EMPTY`.
- Outputs are registered (Moore-style) to avoid combinational glitches feeding the motor
  driver.


